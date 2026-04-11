# GigaRizz Backend — EC2 Deployment Guide

## Prerequisites

1. **EC2 Instance** running Ubuntu 24.04 (t3.small minimum, t3.medium recommended)
2. **Security Group** with ports open:
   - 22 (SSH)
   - 80 (HTTP)
   - 443 (HTTPS)
   - 8000 (API — optional, close in production)
3. **SSH Key** (.pem file or default `~/.ssh/id_rsa`)
4. **Domain** pointed to EC2 IP (A record: `api.gigarizz.app` → `<EC2_IP>`)

## Quick Deploy

```bash
# 1. Configure your .env with real API keys
cp backend/.env.example backend/.env.production
# Edit .env.production with real values (OpenAI, Replicate, etc.)

# 2. Set EC2 connection info
export EC2_HOST="3.150.118.161"     # Your EC2 IP
export EC2_KEY="~/.ssh/id_rsa"      # Your SSH key path

# 3. Deploy everything
cd backend
chmod +x deploy.sh
./deploy.sh deploy

# 4. Add SSL (after DNS is configured)
./deploy.sh ssl
```

## Manual Deploy (Step by Step)

### 1. SSH into EC2
```bash
ssh -i ~/.ssh/your-key.pem ubuntu@<EC2_IP>
```

### 2. Install Docker
```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker ubuntu
# Log out and back in for group change
```

### 3. Clone Repository
```bash
git clone https://github.com/startupbuilders777-beep/gigarizz-ios.git ~/gigarizz
cd ~/gigarizz/backend
```

### 4. Configure Environment
```bash
cp .env.example .env
nano .env
# Fill in ALL required values:
#   OPENAI_API_KEY=sk-...
#   REPLICATE_API_TOKEN=r8_...
#   FAL_KEY=...
#   FIREBASE_PROJECT_ID=gigarizz-...
#   S3_BUCKET_NAME=gigarizz-photos
#   AWS_REGION=us-east-2
#   AWS_ACCESS_KEY_ID=...
#   AWS_SECRET_ACCESS_KEY=...
```

### 5. Build and Start
```bash
docker compose build
docker compose up -d

# Verify
docker compose ps
curl http://localhost:8000/health
```

### 6. Configure Nginx
```bash
sudo apt install -y nginx certbot python3-certbot-nginx

sudo tee /etc/nginx/sites-available/gigarizz << 'EOF'
server {
    listen 80;
    server_name api.gigarizz.app;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
        client_max_body_size 50M;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/gigarizz /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx
```

### 7. Add SSL
```bash
sudo certbot --nginx -d api.gigarizz.app
```

## Management Commands

```bash
# From your local machine:
./deploy.sh status    # Check health
./deploy.sh logs      # Tail logs
./deploy.sh update    # Pull latest + rebuild + restart
./deploy.sh rollback  # Revert to previous image
./deploy.sh stop      # Stop all services
./deploy.sh start     # Start services

# On EC2 directly:
cd ~/gigarizz/backend
docker compose ps           # Service status
docker compose logs -f api  # API logs only
docker compose restart api  # Restart API
docker compose exec api python -c "from app.config import get_settings; print(get_settings())"  # Check config
```

## Architecture

```
Internet → Nginx (80/443) → Docker API (8000) → SQLite + Redis
                                ↕
                         External APIs:
                         - OpenAI (moderation + coach + DALL-E)
                         - Replicate (Flux, SDXL, etc.)
                         - fal.ai (Flux, Recraft, etc.)
                         - AWS S3 (photo storage)
```

## iOS App Configuration

Update `Sources/Core/AppConstants.swift` to point to EC2:

```swift
struct APIConfig {
    #if DEBUG
    static let baseURL = "http://localhost:8000"
    #else
    static let baseURL = "https://api.gigarizz.app"
    #endif
}
```

## Monitoring

- **Health Check**: `GET /health` → `{"status": "healthy"}`
- **Docker Restart Policy**: `restart: unless-stopped` (in docker-compose.yml)
- **Logs**: `docker compose logs -f --tail=200`
- **Disk Usage**: `docker system df`
- **Cleanup**: `docker system prune -af` (careful in production)

## Troubleshooting

| Issue | Fix |
|-------|-----|
| SSH timeout | Check: instance running, security group port 22, correct IP |
| 502 Bad Gateway | API crashed: `docker compose logs api`, then restart |
| OpenAI 401 | Invalid API key in .env |
| Replicate timeout | Model cold start. Retry after 30s |
| Disk full | `docker system prune -af && docker volume prune -f` |
| Port 8000 in use | `docker compose down && docker compose up -d` |

## Cost Estimate (AWS)

| Resource | Monthly Cost |
|----------|-------------|
| t3.small EC2 | ~$15 |
| 20GB EBS | ~$2 |
| Data transfer (50GB) | ~$5 |
| **Total** | **~$22/month** |

Plus external API costs:
- OpenAI: ~$0.01/moderation, ~$0.03/coach response
- Replicate: ~$0.01-0.05/generation
- fal.ai: ~$0.01-0.03/generation
