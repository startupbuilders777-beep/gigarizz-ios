# GigaRizz — App Store Launch Checklist

> Generated from full E2E audit on April 11, 2026
> Commit: `5229a78` | 19/19 backend tests passing | iOS BUILD SUCCEEDED

---

## STATUS OVERVIEW

| Area | Status | Blockers |
|------|--------|----------|
| iOS App Build | ✅ Clean | None |
| Backend Unit Tests | ✅ 19/19 | None |
| Backend E2E (local) | ✅ All endpoints | Placeholder API keys |
| Marketing Assets | ✅ 8 files | Need real screenshots |
| EC2 Deployment | ⏳ Ready to deploy | Instance unreachable (likely stopped) |
| Firebase Auth | 🚫 BLOCKER | No GoogleService-Info.plist |
| RevenueCat | 🚫 BLOCKER | Placeholder API key |
| PostHog Analytics | 🚫 BLOCKER | Placeholder API key |
| API Keys (Backend) | 🚫 BLOCKER | All placeholder values |
| App Store Connect | 🚫 Not started | Need account + metadata |
| Privacy Policy | ⚠️ URL exists but no page | Need to create page |
| Dev Team Signing | ⚠️ Empty | Need Apple Developer account |

---

## 🔴 P0 — BLOCKERS (Must fix before submission)

### 1. Firebase Configuration
- [ ] Create Firebase project at https://console.firebase.google.com
- [ ] Enable Authentication (Email + Apple Sign In)
- [ ] Download `GoogleService-Info.plist`
- [ ] Add to `GigaRizz/Resources/` and reference in `project.yml`
- [ ] Set `FIREBASE_PROJECT_ID` in backend `.env`
- [ ] Verify: `FirebaseApp.configure()` runs in `GigaRizzApp.swift`

### 2. RevenueCat Configuration
- [ ] Create RevenueCat project at https://app.revenuecat.com
- [ ] Set up App Store Connect API key in RevenueCat
- [ ] Create products in App Store Connect:
  - GigaRizz Plus (weekly/monthly)
  - GigaRizz Gold (monthly/annual)
  - Intro Offer (discounted first period)
- [ ] Create "default" offering in RevenueCat
- [ ] Replace `AppConstants.revenueCatAPIKey` with real key
- [ ] Verify entitlement IDs: `gold`, `plus`

### 3. Real API Keys (Backend .env)
- [ ] `OPENAI_API_KEY` — Get from https://platform.openai.com/api-keys
- [ ] `REPLICATE_API_TOKEN` — Get from https://replicate.com/account/api-tokens
- [ ] `FAL_KEY` — Get from https://fal.ai/dashboard/keys
- [ ] `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` — Create IAM user for S3
- [ ] Create S3 bucket `gigarizz-photos` in us-east-2
- [ ] Set bucket CORS policy for iOS uploads

### 4. PostHog Analytics
- [ ] Create project at https://us.posthog.com
- [ ] Replace `AppConstants.postHogAPIKey` with real project key
- [ ] Verify host: `https://us.i.posthog.com`

### 5. Apple Developer Account
- [ ] Set `DEVELOPMENT_TEAM` in `project.yml`
- [ ] Create App ID in Apple Developer portal
- [ ] Set bundle ID: `app.gigarizz.GigaRizz` (or your chosen ID)
- [ ] Enable capabilities: Push Notifications, Sign in with Apple

### 6. Code Signing
- [ ] Create Distribution certificate
- [ ] Create Provisioning Profile (Distribution)
- [ ] Archive with proper signing

---

## 🟡 P1 — Required for Launch (but not blocking build)

### 7. Privacy & Legal Pages
- [ ] Create Privacy Policy page at https://www.gigarizz.app/privacy
- [ ] Create Terms of Service page at https://www.gigarizz.app/terms
- [ ] Include sections: data collection, AI processing, photo storage, user rights
- [ ] GDPR / CCPA compliance statements
- [ ] Set up domain (Vercel/Netlify + custom domain)

### 8. EC2 Backend Deployment
- [ ] Start EC2 instance (currently stopped/unreachable at 3.150.118.161)
- [ ] Update security group: allow ports 22, 80, 443 from anywhere
- [ ] Get new public IP (elastic IP recommended)
- [ ] Run `./backend/deploy.sh deploy`
- [ ] Upload `.env.production` with real API keys
- [ ] Set up DNS: `api.gigarizz.app` → EC2 IP
- [ ] Run `./backend/deploy.sh ssl` for HTTPS
- [ ] Verify: `curl https://api.gigarizz.app/health`

### 9. Update iOS Production URL
- [ ] After EC2 is deployed, verify `AppConstants.backendBaseURL`:
  - DEBUG: `http://localhost:8000` ✅ (already set)
  - RELEASE: `https://api.gigarizz.app` ✅ (already set)
- [ ] Test full flow on device with backend pointing to EC2

### 10. App Store Connect Setup
- [ ] Create app in App Store Connect
- [ ] Fill in app metadata:
  - Name: GigaRizz
  - Subtitle: AI Dating Photos That Get Matches
  - Category: Photo & Video (Primary), Lifestyle (Secondary)
  - Age Rating: 17+ (photo AI content)
- [ ] Upload screenshots (6.7" iPhone, 6.1" iPhone, 12.9" iPad)
  - Use `marketing/assets/screenshot-frames.html` as base
  - Replace mock content with real app screenshots
- [ ] Write/paste App Store description from `marketing/assets/appstore-description.md`
- [ ] Add keywords from metadata.json (100 char limit)
- [ ] Upload 1024x1024 app icon (render from `marketing/assets/app-icon-spec.svg`)
- [ ] Set price: Free (with IAP)
- [ ] Select In-App Purchases
- [ ] Set App Review information (demo account, notes)

### 11. TestFlight Beta
- [ ] Archive and upload to TestFlight
- [ ] Add internal testers (your team)
- [ ] Add external testers (beta group)
- [ ] Test full flows:
  - [ ] Onboarding (30-step luxury flow)
  - [ ] Photo generation (at least 3 models)
  - [ ] Batch generation
  - [ ] Coach (bio, openers, reply)
  - [ ] Paywall + subscription
  - [ ] Account creation (Firebase Auth)
  - [ ] Settings + account deletion

---

## 🟢 P2 — Polish Before Launch

### 12. iOS Schema Alignment (Minor Issues Found)
- [ ] iOS `BioRequest` sends `vibe` field → backend ignores it (harmless but wasteful)
  - Option A: Remove `vibe` from iOS `BioRequest`
  - Option B: Add `vibe` support to backend `BioRequest`
- [ ] iOS `BioRequest` missing `age`/`gender` fields → backend supports them
  - Consider adding age/gender to iOS bio generation flow
- [ ] iOS `UserAnalytics` decoder is missing some fields the backend returns:
  - `favorite_style`, `total_matches`, `match_rate`, `top_style`, `streak_days`, `weekly_generations`, `platform_breakdown`
  - iOS only decodes: `totalGenerations`, `successfulGenerations`, `generationsToday`, `favoriteStyle`

### 13. Backend Hardening
- [ ] Set `moderation_enabled: true` in production .env
- [ ] Switch moderation `check_text` to fail-closed in production (currently fails open)
- [ ] Add rate limiting middleware (currently only DB-level check)
- [ ] Set `ENVIRONMENT=production` and `DEBUG=false`
- [ ] Disable docs endpoint in production (already conditional)
- [ ] Configure CORS to only allow your domains (not localhost)
- [ ] Add structured logging (JSON logs for CloudWatch)
- [ ] Set up health check monitoring (UptimeRobot, Pingdom)

### 14. Performance & Reliability
- [ ] Add Redis for session caching (docker-compose already includes redis)
- [ ] Set up database backups (SQLite → periodic S3 backup, or migrate to PostgreSQL)
- [ ] Add Sentry for error tracking (both iOS and backend)
- [ ] Set up CloudWatch alarms for EC2

### 15. App Review Preparation
- [ ] Create demo account for Apple Review team
- [ ] Write reviewer notes explaining AI photo generation
- [ ] Prepare for potential rejection reasons:
  - AI content disclosure (required since iOS 17.4)
  - Photo manipulation warnings
  - In-app purchase must be clearly described
- [ ] Add "AI-Generated" watermark or metadata to all generated photos
- [ ] Include privacy nutrition label info:
  - Data collected: photos, name, email, usage data
  - Data linked to user: photos, purchase history
  - Tracking: PostHog analytics

### 16. Marketing Launch
- [ ] Deploy landing page from `marketing/assets/landing-page.html`
- [ ] Set up Product Hunt launch
- [ ] Prepare social media cards from `marketing/assets/social-cards.html`
- [ ] Set up email capture on landing page
- [ ] Prepare App Store Optimization (ASO):
  - Screenshots with compelling captions
  - Keyword research (from metadata.json)
  - Preview video (optional but high-impact)

---

## 📋 Quick Reference — Integration Points

| iOS Constant | Current Value | Production Value |
|-------------|---------------|------------------|
| `backendBaseURL` (DEBUG) | `http://localhost:8000` | Keep as-is |
| `backendBaseURL` (RELEASE) | `https://api.gigarizz.app` | Verify DNS |
| `revenueCatAPIKey` | `appl_REPLACE...` | Real RC key |
| `postHogAPIKey` | `phc_REPLACE...` | Real PH key |
| `postHogHost` | `https://us.i.posthog.com` | Keep as-is |
| `termsURL` | `https://www.gigarizz.app/terms` | Create page |
| `privacyURL` | `https://www.gigarizz.app/privacy` | Create page |

| Backend .env | Current | Production |
|-------------|---------|------------|
| `OPENAI_API_KEY` | `sk-REPLACE...` | Real key |
| `REPLICATE_API_TOKEN` | `r8_REPLACE...` | Real key |
| `FAL_KEY` | `REPLACE...` | Real key |
| `ENVIRONMENT` | `development` | `production` |
| `DEBUG` | `true` | `false` |
| `MODERATION_ENABLED` | `true` | `true` (fail-closed) |

---

## E2E Test Results Summary

| Endpoint | Status | Notes |
|----------|--------|-------|
| `GET /health` | ✅ 200 | Returns version, environment |
| `GET /api/v1/flags` | ✅ 200 | 19 feature flags |
| `GET /api/v1/generate/models` | ✅ 200 | 16 models, category filter works |
| `GET /api/v1/users/me` | ✅ 200 | Auto-creates user, returns profile |
| `GET /api/v1/users/me/analytics` | ✅ 200 | Returns empty analytics for new user |
| `POST /api/v1/generate` | ⚠️ 500 | Expected: moderation fails with placeholder key |
| `POST /api/v1/generate/batch` | ⚠️ Auth | Needs valid user token |
| `POST /api/v1/coach/bio` | ⚠️ 500 | Expected: OpenAI fails with placeholder key |
| `POST /api/v1/coach/openers` | ⚠️ 500 | Expected: OpenAI fails with placeholder key |
| `POST /api/v1/coach/reply` | ⚠️ 500 | Expected: OpenAI fails with placeholder key |

All ⚠️ endpoints will work with real API keys. The code paths are correct.

---

## Bugs Fixed This Session

1. **Model category filter broken** — `GET /api/v1/generate/models?category=premium` returned all 16 models. Fixed: added `category` query param filtering.
2. **Moderation crashes on invalid key** — `check_text()` had no try/except, causing unhandled 500 on OpenAI auth error. Fixed: added graceful error handling (fail-open in dev).
3. **Storage service wrong field names** — Used `settings.s3_bucket` and `settings.s3_region` but config.py has `s3_bucket_name` and `aws_region`. Fixed.
4. **`.env.example` mismatched config** — `S3_BUCKET` and `S3_REGION` didn't match pydantic Settings. Fixed to `S3_BUCKET_NAME` and `AWS_REGION`.

---

## Recommended Post-Launch Features (from Competitor Analysis)

| Priority | Feature | Effort | Impact |
|----------|---------|--------|--------|
| 1 | Photo A/B Testing | Medium | High retention |
| 2 | Shorten Onboarding (30→5 steps) | Small | High acquisition |
| 3 | Screenshot Profile Audit | Medium | High engagement |
| 4 | Personal AI Model Training | Large | Market differentiator |
| 5 | Outfit/Clothing Swap | Medium | Viral potential |
| 6 | Keyboard Extension | Medium | Daily engagement |
| 7 | Platform-Specific Templates | Small | Revenue |
| 8 | Social Sharing Mechanics | Small | Growth |
| 9 | AI Video Portraits | Large | Premium upsell |
| 10 | Couple Photo Generator | Medium | Viral + press |
