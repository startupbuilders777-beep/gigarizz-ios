# GigaRizz Backend

FastAPI backend for the GigaRizz dating photo AI app.

## Quick Start

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env  # Edit with your API keys
uvicorn app.main:app --reload --port 8000
```

## Architecture

```
backend/
├── app/
│   ├── main.py              # FastAPI app + CORS + lifespan
│   ├── config.py            # Settings from environment
│   ├── deps.py              # Dependency injection
│   ├── routers/
│   │   ├── generation.py    # Photo generation endpoints
│   │   ├── coach.py         # AI dating coach (bios, openers, prompts)
│   │   ├── feature_flags.py # Remote feature flags
│   │   ├── users.py         # User management + analytics
│   │   └── health.py        # Health check + readiness
│   ├── services/
│   │   ├── generation_service.py  # Replicate / fal.ai integration
│   │   ├── coach_service.py       # OpenAI GPT integration
│   │   ├── storage_service.py     # S3/R2 file storage
│   │   └── moderation_service.py  # Content moderation
│   ├── models/
│   │   ├── schemas.py       # Pydantic request/response models
│   │   └── database.py      # SQLAlchemy models + async engine
│   └── middleware/
│       └── auth.py          # Firebase Auth token verification
├── requirements.txt
├── .env.example
├── Dockerfile
└── docker-compose.yml
```

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/v1/generate` | Queue photo generation job |
| GET | `/api/v1/generate/{job_id}` | Check generation job status |
| POST | `/api/v1/coach/bio` | Generate dating bio |
| POST | `/api/v1/coach/openers` | Generate opening lines |
| POST | `/api/v1/coach/prompts` | Generate Hinge prompts |
| POST | `/api/v1/coach/reply` | Suggest conversation reply |
| GET | `/api/v1/flags` | Get feature flags |
| GET | `/api/v1/users/me` | Get current user profile |
| GET | `/api/v1/users/me/analytics` | Get user analytics |
| DELETE | `/api/v1/users/me` | GDPR delete |
| GET | `/api/v1/health` | Health check |

## Environment Variables

See `.env.example` for all required configuration.
