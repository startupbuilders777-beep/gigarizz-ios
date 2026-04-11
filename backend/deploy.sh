#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# GigaRizz Backend — EC2 Deployment Script
# ═══════════════════════════════════════════════════════════════════
# Usage:
#   ./deploy.sh                 # Full deploy (setup + build + start)
#   ./deploy.sh setup           # First-time server setup only
#   ./deploy.sh build           # Build Docker images
#   ./deploy.sh start           # Start services
#   ./deploy.sh stop            # Stop services
#   ./deploy.sh logs            # Tail logs
#   ./deploy.sh status          # Check service status
#   ./deploy.sh update          # Pull latest + rebuild + restart
#   ./deploy.sh rollback        # Rollback to previous image
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

# ── Config ──────────────────────────────────────────────────────────
EC2_USER="${EC2_USER:-ubuntu}"
EC2_HOST="${EC2_HOST:-3.150.118.161}"  # Update with current IP
EC2_KEY="${EC2_KEY:-~/.ssh/id_rsa}"
APP_DIR="/home/ubuntu/gigarizz"
REPO_URL="https://github.com/startupbuilders777-beep/gigarizz-ios.git"
DOMAIN="${DOMAIN:-api.gigarizz.app}"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log() { echo -e "${GREEN}[DEPLOY]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

SSH_CMD="ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -i $EC2_KEY $EC2_USER@$EC2_HOST"
SCP_CMD="scp -o ConnectTimeout=10 -o StrictHostKeyChecking=no -i $EC2_KEY"

check_connection() {
    log "Testing SSH connection to $EC2_HOST..."
    $SSH_CMD "echo 'Connected'" 2>/dev/null || err "Cannot connect to EC2. Check:\n  1. Instance is running\n  2. Security group allows SSH (port 22)\n  3. Key file exists at $EC2_KEY\n  4. IP is correct: $EC2_HOST"
}

setup_server() {
    log "Setting up EC2 instance..."
    $SSH_CMD << 'SETUP_SCRIPT'
set -euo pipefail

echo "── Installing Docker ──"
if ! command -v docker &>/dev/null; then
    sudo apt-get update -qq
    sudo apt-get install -y -qq apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://get.docker.com | sudo sh
    sudo usermod -aG docker ubuntu
    echo "Docker installed. You may need to re-login for group changes."
fi

echo "── Installing Docker Compose ──"
if ! command -v docker compose &>/dev/null; then
    sudo apt-get install -y -qq docker-compose-plugin
fi

echo "── Installing Nginx ──"
sudo apt-get install -y -qq nginx certbot python3-certbot-nginx

echo "── Installing git ──"
sudo apt-get install -y -qq git

echo "── Creating app directory ──"
mkdir -p ~/gigarizz

echo "── Server setup complete ──"
docker --version
docker compose version
nginx -v 2>&1
SETUP_SCRIPT
    log "Server setup complete!"
}

clone_or_pull() {
    log "Syncing code to EC2..."
    $SSH_CMD << SYNC
cd ~
if [ -d "$APP_DIR" ] && [ -d "$APP_DIR/.git" ]; then
    echo "Pulling latest..."
    cd $APP_DIR && git pull origin main
else
    echo "Cloning fresh..."
    rm -rf $APP_DIR
    git clone $REPO_URL $APP_DIR
fi
SYNC
}

upload_env() {
    if [ -f ".env.production" ]; then
        log "Uploading .env.production..."
        $SCP_CMD .env.production $EC2_USER@$EC2_HOST:$APP_DIR/backend/.env
    else
        warn "No .env.production found locally. Create one with real API keys!"
        warn "Copy .env.example to .env.production and fill in real values."
    fi
}

build_images() {
    log "Building Docker images on EC2..."
    $SSH_CMD << BUILD
cd $APP_DIR/backend
docker compose build --no-cache
BUILD
    log "Build complete!"
}

start_services() {
    log "Starting services..."
    $SSH_CMD << START
cd $APP_DIR/backend
docker compose up -d
echo "── Services running ──"
docker compose ps
START
    log "Services started!"
}

stop_services() {
    log "Stopping services..."
    $SSH_CMD "cd $APP_DIR/backend && docker compose down"
    log "Services stopped."
}

show_logs() {
    $SSH_CMD "cd $APP_DIR/backend && docker compose logs -f --tail=100"
}

show_status() {
    $SSH_CMD << STATUS
echo "── Docker Services ──"
cd $APP_DIR/backend && docker compose ps
echo ""
echo "── System Resources ──"
free -h | head -2
df -h / | tail -1
echo ""
echo "── API Health ──"
curl -s http://localhost:8000/health 2>/dev/null || echo "API not responding"
STATUS
}

setup_nginx() {
    log "Configuring Nginx reverse proxy..."
    $SSH_CMD << 'NGINX'
sudo tee /etc/nginx/sites-available/gigarizz > /dev/null << 'CONF'
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
        proxy_connect_timeout 75s;

        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    client_max_body_size 50M;
}
CONF

sudo ln -sf /etc/nginx/sites-available/gigarizz /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx
echo "Nginx configured!"
NGINX
    log "Nginx reverse proxy configured!"
}

setup_ssl() {
    log "Setting up SSL with Let's Encrypt..."
    $SSH_CMD "sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@gigarizz.app"
    log "SSL configured!"
}

update() {
    log "Updating deployment..."
    clone_or_pull
    upload_env
    build_images
    $SSH_CMD "cd $APP_DIR/backend && docker compose down && docker compose up -d"
    log "Update complete!"
    show_status
}

rollback() {
    log "Rolling back to previous image..."
    $SSH_CMD << 'ROLLBACK'
cd ~/gigarizz/backend
PREV=$(docker images --format '{{.Repository}}:{{.Tag}} {{.CreatedAt}}' | grep gigarizz | sort -k2 -r | head -2 | tail -1 | awk '{print $1}')
if [ -n "$PREV" ]; then
    echo "Rolling back to: $PREV"
    docker compose down
    docker tag $PREV gigarizz-api:latest
    docker compose up -d
else
    echo "No previous image found for rollback"
fi
ROLLBACK
}

full_deploy() {
    check_connection
    setup_server
    clone_or_pull
    upload_env
    build_images
    start_services
    setup_nginx
    log "═══════════════════════════════════════════════"
    log "  Deployment complete!"
    log "  API: http://$EC2_HOST:8000/health"
    log "  Nginx: http://$DOMAIN"
    log ""
    log "  Next: Run './deploy.sh ssl' for HTTPS"
    log "═══════════════════════════════════════════════"
}

# ── Main ──────────────────────────────────────────────────────────
case "${1:-deploy}" in
    setup)    check_connection && setup_server ;;
    build)    check_connection && build_images ;;
    start)    check_connection && start_services ;;
    stop)     check_connection && stop_services ;;
    logs)     check_connection && show_logs ;;
    status)   check_connection && show_status ;;
    update)   check_connection && update ;;
    rollback) check_connection && rollback ;;
    nginx)    check_connection && setup_nginx ;;
    ssl)      check_connection && setup_ssl ;;
    deploy)   full_deploy ;;
    *)        echo "Usage: $0 {deploy|setup|build|start|stop|logs|status|update|rollback|nginx|ssl}" ;;
esac
