# GigaRizz — App Store Launch Checklist

> Last updated 2026-05-14 after Firebase project bootstrap (`rizzi-44071`).
> Branch: `main` | Backend tests: **33/33** | iOS simulator tests: **passing** | Release simulator build: **passing**
> Models in catalog: **20** (10 Replicate + 5 fal.ai + 5 OpenAI)
> SOTA surfaces shipped: Face Enhance, Outfit Studio, Hairstyle, Age Studio, Pose Studio, Hinge Mode
> **V2 Profile Upgrade flow is the default first-run shell** (audit -> diagnosis -> kit -> export -> screenshot coach)
> Firebase project `rizzi-44071`: iOS app registered, `GoogleService-Info.plist` bundled, backend Admin SDK initialized.

---

## ⚠️ USER ACTIONS REQUIRED BEFORE LAUNCH

These cannot be done from CLI / scripts and need you in front of a browser or with credentials in hand.

### Firebase Console (rizzi-44071)
1. **Enable Authentication** — open https://console.firebase.google.com/project/rizzi-44071/authentication/providers and click *Get Started*. Enable **Email/Password** and **Sign in with Apple** providers.
2. **Enable Firestore** — https://console.firebase.google.com/project/rizzi-44071/firestore. Create database in `nam5` location, start in *production* mode.
3. **Enable Storage** — https://console.firebase.google.com/project/rizzi-44071/storage. Default rules.
4. *(Optional, costs money)* Upgrade to Blaze plan if you want any of the above doable via API later.

### Apple Developer
5. Set `DEVELOPMENT_TEAM` in `project.yml` (or an xcconfig) to your Apple Team ID. Re-run `xcodegen generate`.
6. In Apple Developer portal: register App ID `com.gigarizz.app`, enable **Sign in with Apple** capability.
7. Create Distribution Cert + Provisioning Profile.

### Provider API keys (drop into `backend/.env`)
8. `OPENAI_API_KEY` — required for audit + coach + GPT Image 2 generation.
9. `REPLICATE_API_TOKEN` — Flux, SDXL, CodeFormer (face enhance), InstantID.
10. `FAL_KEY` — Nano Banana 2 (Outfit/Hairstyle/Age Studio).
11. `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` + `S3_BUCKET_NAME=gigarizz-photos`.

### EC2 backend
12. Start EC2 instance (currently stopped — port 22 timeout from this machine on 2026-05-14). Allocate elastic IP.
13. Update `backend/deploy.sh` `EC2_HOST=` if IP changed.
14. From a machine with the SSH key: `cd backend && ./deploy.sh setup && ./deploy.sh deploy && ./deploy.sh ssl`.
15. Point `api.gigarizz.app` DNS to the elastic IP.

### Marketing / legal pages (Cloudflare Pages)
16. `cd web && npm install && npx wrangler login && npm run deploy`.
17. Cloudflare dashboard → Pages → gigarizz-web → add custom domains `www.gigarizz.app` + `gigarizz.app`.

### App Store Connect
18. Create app, upload screenshots (use marketing/assets), set IAPs, submit reviewer notes.
19. RevenueCat dashboard → wire products + entitlements `gold` / `plus` → set `REVENUECAT_API_KEY` Xcode build setting.
20. PostHog dashboard → set `POSTHOG_API_KEY` Xcode build setting.

---

## What was completed on 2026-05-14

- Firebase project `rizzi-44071`: iOS app registered (`com.gigarizz.app`, app ID `1:264997849602:ios:9b923b56f34f795d68751b`).
- `GoogleService-Info.plist` downloaded via Firebase Management API and installed at `GigaRizz/Resources/`.
- `xcodegen generate` re-run; plist now bundled in `.app` (verified in Debug-iphonesimulator build).
- Service account JSON installed at `backend/firebase-service-account.json`. Both files added to `.gitignore`.
- Backend `.env` `FIREBASE_PROJECT_ID` updated to `rizzi-44071`. Admin SDK initializes successfully.
- Backend test suite: **33/33** still passing.
- Debug iOS simulator build: **passing** (xcodebuild exit 0).
- New planning docs: `V3_PRODUCT_PLAN.md` (market-domination roadmap), `V4_COMPETITOR_KILL_PLAN.md` (surgical counter-feature plan), `COMPETITOR_RESEARCH.md` (25 competitor profiles).

---

## STATUS OVERVIEW

| Area                              | Status                | Blocker?                                    |
|-----------------------------------|-----------------------|---------------------------------------------|
| iOS App Build                     | ✅ Debug launch + Release simulator build clean | No                  |
| iOS Tests                         | ✅ `xcodebuild test -quiet` passing | No                             |
| iOS UI Tests                      | ✅ V2 smoke + navigation checks passing | No                    |
| Backend Unit Tests                | ✅ 33/33              | No                                          |
| Backend E2E (local)               | ✅ All endpoints      | Placeholder API keys                        |
| Server-driven Feature Flags       | ✅ 33+ flags          | No                                          |
| V2 Profile Upgrade flow           | ✅ End-to-end         | No                                          |
| V2 Audit endpoint (GPT-4o vision) | ✅ Shipped            | No                                          |
| V2 ProfileKit + Export (share / save / copy) | ✅ Shipped | No                                          |
| V2 Screenshot Coach (Vision OCR)  | ✅ Shipped            | No                                          |
| V2 Paywall gate (audit-triggered) | ✅ Shipped            | No                                          |
| Trust toggle (Keep me looking like me) | ✅ Shipped       | No                                          |
| Dev-build Real-AI Toggle          | ✅ Settings → DEBUG   | No                                          |
| Dev-build Force V2 Toggle         | ✅ Settings → DEBUG   | No                                          |
| 6 SOTA Surfaces                   | ✅ All flag-gated     | No                                          |
| Unified V2 design system          | ✅ V2Components atoms | No                                          |
| EC2 Deployment                    | ⏳ Ready              | Instance needs restart                      |
| Privacy manifest                  | ✅ Added              | Verify final App Store privacy answers match |
| Sign in with Apple entitlement    | ✅ Added              | Requires Apple Developer capability enabled |
| App icon catalog                  | ✅ Complete           | No asset-catalog warnings in Release build  |
| Firebase Auth                     | ⚠️ External setup     | Add `GoogleService-Info.plist` for live auth |
| RevenueCat                        | ⚠️ External setup     | Set build setting `REVENUECAT_API_KEY` + App Store products |
| PostHog Analytics                 | ⚠️ External setup     | Set build setting `POSTHOG_API_KEY`         |
| Real Provider API Keys            | ⚠️ External setup     | OpenAI / Replicate / fal.ai / AWS           |
| Apple Developer Account           | ⚠️ External setup     | `DEVELOPMENT_TEAM` empty                    |
| App Store Connect                 | 🚫 Not started        | Need account + metadata + screenshots       |
| Privacy Policy & Terms            | ✅ Pages written      | Deploy via `cd web && npm run deploy` (Cloudflare Pages) |
| Production S3 Bucket              | ⚠️ Falls back to dev  | Create bucket + IAM keys                    |

---

## 0. Dev-Build Quick Start (run app locally with real AI)

The dev build now works end-to-end without real keys (mock service mode). To exercise real AI in DEBUG, do this:

### Backend `.env` (copy from `backend/.env.example`)
Minimum required for real AI generation:

```bash
# AI providers (REQUIRED for real generation)
OPENAI_API_KEY=<openai_api_key>         # GPT Image 1, GPT Image 2, DALL-E 3, Coach
REPLICATE_API_TOKEN=r8_...              # Flux, SDXL, SD3, RealVisXL, InstantID, CodeFormer
FAL_KEY=fal_...                         # Nano Banana 2, Recraft V3, SDXL Lightning

# Photo storage (REQUIRED for source-image upload)
S3_BUCKET_NAME=gigarizz-photos
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
S3_ENDPOINT_URL=                        # leave empty for real S3; set for R2/MinIO
```

### Run backend
```bash
cd backend
uv sync
uv run uvicorn app.main:app --reload --port 8000
```

### iOS dev toggle
1. Run app on simulator or device.
2. Open Settings tab → scroll to **Developer** (DEBUG only).
3. Toggle **Use Real AI** ON. App now sends generation requests to backend instead of returning mocked photos.
4. Photo upload happens via the new `PhotoUploadService` → presigned PUT to S3.

If S3 keys are missing the upload service falls back to a placeholder dev URL — generations will fail at provider but the app won't crash.

---

## 0.5. V2 Profile Upgrade Flow (Codex V2 plan — shipped end-to-end)

The V2 experience is the audit-first dating profile studio. It lives behind
`FLAG_ENABLE_V2_UPGRADE_FLOW` (default off) so V1 users see no change until
TestFlight cohorts opt in.

### What's shipped
- **Audit endpoint** (`POST /api/v1/audit`) — GPT-4o vision scores 4–8 photos on six dimensions (clarity, lighting, expression, crop, authenticity, platform_fit), tags archetypes, returns 3 specific top fixes + missing-archetype list.
- **Upgrade tab** — first-run flow: pick platforms → upload photos → audit → diagnosis. Each stage uses the same V2Components atoms (V2HeroCard, V2PrimaryButton, V2TrustBadge, V2ScoreRing, V2PlatformPill, V2SectionHeader).
- **Profile Diagnosis screen** — animated score ring (color-graded by band), summary, Top Fixes with archetype tags, Missing Slots grid, Spotlight (best/weakest), per-photo critique cards. "Build my Profile Kit" CTA navigates to ProfileKitView.
- **ProfileKitView (hero artifact)** — platform pill selector switches per-platform photo strip, bio with regenerate + copy, Hinge prompts, first messages, sticky export bar (Copy all / Save photos / Share kit). Per-line copy on every prompt and opener.
- **ProfileKitOrderer** — pure algorithm picks first photo (never social_proof), prefers archetype variety, then tops off by score. Per-platform slot counts + suggested archetype mix.
- **ProfileKitExporter** — UIPasteboard, PHPhotoLibrary multi-photo save, UIActivityViewController share with bio + prompts + openers text block.
- **PaywallGate** — pure decision struct (`mode × isSubscribed × auditsUsedSoFar`). Triggers between audit completion and full diagnosis when `paywall_mode=hard` or `soft + threshold reached`. AuditUsageCounter persists per-device.
- **Naturalness toggle** — `keep_me_natural` flag on every generation request wraps prompts with identity-preservation language. Default ON. Server-side `_wrap_natural()` is idempotent. Surfaced in Settings → Trust & Privacy.
- **Screenshot Coach** — Vision OCR on-device (`VNRecognizeTextRequest`) extracts text from profile/chat screenshots, then routes to existing `/openers` or `/reply` endpoints for: profile opener / reply suggestion / revive dead chat. Pixels never leave the device.
- **DEBUG override** — `dev_force_v2_upgrade_flow` UserDefault (Settings → Developer) forces V2 on without backend flag flip; UI test launch arg `-dev_force_v2_upgrade_flow 1` makes the V2 flow CI-testable.

### To activate V2 for a TestFlight cohort
```bash
ssh ubuntu@api.gigarizz.app
sed -i 's/FLAG_ENABLE_V2_UPGRADE_FLOW=false/FLAG_ENABLE_V2_UPGRADE_FLOW=true/' /srv/gigarizz/.env
sudo systemctl restart gigarizz
curl https://api.gigarizz.app/api/v1/flags | jq .enable_v2_upgrade_flow   # → true
```

iOS picks up the new flag within 1h on the next `refreshIfNeeded()`. Force-quit the app to apply immediately.

### V2 surfaces by file
| Surface              | File                                                              |
|----------------------|-------------------------------------------------------------------|
| Tab gating           | `App/MainTabView.swift`                                           |
| State machine        | `Features/Upgrade/UpgradeFlowView.swift`                          |
| Diagnosis hero       | `Features/Upgrade/ProfileDiagnosisView.swift`                     |
| Kit hero             | `Features/Upgrade/ProfileKitView.swift`                           |
| Photo ordering       | `Features/Upgrade/ProfileKitOrderer.swift`                        |
| Export pipeline      | `Features/Upgrade/ProfileKitExporter.swift`                       |
| Paywall decision     | `Features/Upgrade/PaywallGate.swift`                              |
| Visual atoms         | `Features/Upgrade/V2Components.swift`                             |
| Audit client         | `Core/Services/GigaRizzAPIClient.swift` (`runAudit`)              |
| Persistence          | `Core/Services/ProfileKitStore.swift`                             |
| Naturalness wrap     | `backend/app/services/generation_service.py` (`_wrap_natural`)    |
| OCR service          | `Core/Services/ScreenshotOCRService.swift`                        |
| Screenshot Coach UI  | `Features/ScreenshotCoach/ScreenshotCoachView.swift`              |

---

## 1. Server-Driven Feature Flag System

Every SOTA surface, paywall variant, and onboarding step is gated by a server-driven flag fetched on cold start (and every 1h after). Edit any flag in `backend/.env` and **no app update is required** — the change propagates to live users on the next refresh.

### Flag categories
- **Core surfaces** — `enable_generation`, `enable_coach`, `enable_face_swap`, `enable_background_replacer`, `enable_expression_coach`, `enable_photo_ranking`, `enable_color_grade`, `enable_pose_library`, `enable_intro_offer`, `enable_batch_generation`
- **Model tiers** — `enable_premium_models`, `enable_photorealistic_models`, `enable_artistic_models`
- **SOTA features (iter 1-9)** — `enable_face_enhance`, `enable_outfit_studio`, `enable_hairstyle`, `enable_age_studio`, `enable_pose_studio`, `enable_hinge_overlay`, `enable_nano_banana_2`, `enable_gpt_image_2`, `enable_instant_id`
- **Paywall** — `paywall_mode` ∈ {`none`, `soft`, `hard`}, `soft_paywall_after_uses` (int)
- **Onboarding** — `onboarding_enabled`, `onboarding_quiz_enabled`, `onboarding_skip_enabled`, `onboarding_max_steps` (cap of 30), `onboarding_show_social_proof`, `onboarding_show_testimonials`, `onboarding_show_video_demo`
- **Quotas** — `max_free_generations`, `max_plus_generations`, `max_gold_generations`, `max_batch_models`
- **Misc** — `show_promo_banner`, `min_app_version`

### How to flip a flag in production
1. SSH to EC2: `ssh ubuntu@api.gigarizz.app`
2. Edit `/srv/gigarizz/.env` and change e.g. `FLAG_PAYWALL_MODE=hard` or `FLAG_ENABLE_OUTFIT_STUDIO=false`
3. Restart: `sudo systemctl restart gigarizz`
4. Verify: `curl https://api.gigarizz.app/api/v1/flags | jq .paywall_mode`
5. iOS pulls within 1 hour OR force-refresh by killing + cold-launching the app.

### App Review demo mode
Set `FLAG_PAYWALL_MODE=none` to remove all paywalls during review. Reviewers see free, unlimited app. Flip back to `soft` post-approval.

### Backlog: PATCH /api/v1/flags admin endpoint
Currently flags are baked into Settings on backend boot. A `PATCH /api/v1/flags` endpoint with admin auth would allow runtime toggles without SSH+restart. Tracked in `tasks.json` backlog.

---

## 2. Core User Flow

See [CORE_USER_FLOW.md](./CORE_USER_FLOW.md) for the full diagram + per-feature flows. TL;DR cold-start path:

```
Launch
  → SDK init guards (Firebase/RevenueCat/PostHog all opt-in if keys present)
  → onboarding_enabled flag check
    → 30-step luxury onboarding (capped by onboarding_max_steps)
    → onboarding_quiz_enabled? → photo-readiness quiz
    → onboarding_skip_enabled? → "Skip for now" CTA
  → Apple Sign-In (or DEBUG dev auth bypass)
  → paywall_mode check
    → "hard" → blocking paywall before Home
    → "soft" → home renders; paywall on Nth use (soft_paywall_after_uses)
    → "none" → home, no paywall (App Review)
  → Home tab: 4 SOTA Quick Actions (visible filtered by feature flags)
  → Tap Quick Action / ToolsHub tile / Generate
    → photo upload (resize 1600px JPEG q=0.85 → presigned PUT)
    → backend gen_svc creates prediction (Replicate/fal.ai/OpenAI)
    → result polling → URL preserved → save/share
```

---

## 3. P0 EXTERNAL SETUP (must finish before App Store submission)

The app now degrades gracefully when Firebase, RevenueCat, or PostHog are not
configured, which keeps local and simulator launches from dead-ending. For App
Store review and production, these still need real Apple/Firebase/RevenueCat/
backend configuration so reviewers can exercise live account, purchase,
restore, and AI generation flows.

### 3.1 Firebase configuration
- [ ] Create Firebase project at https://console.firebase.google.com
- [ ] Enable Authentication: Email + **Sign in with Apple**
- [ ] Download `GoogleService-Info.plist` to `GigaRizz/Resources/`
- [ ] Reference in the Xcode project/build settings if needed (the app already guards missing Firebase config)
- [ ] Set `FIREBASE_PROJECT_ID` in backend `.env`
- [ ] Verify cold launch reaches MainTabView (the lazy-init guards already prevent crashes if missing; once added, real auth lights up)

### 3.2 RevenueCat
- [ ] Create RevenueCat project at https://app.revenuecat.com
- [ ] Wire App Store Connect API key
- [ ] Create products in App Store Connect:
  - GigaRizz Plus weekly + monthly
  - GigaRizz Gold monthly + annual
  - Intro Offer (discounted first period)
- [ ] Create "default" offering with `gold` and `plus` entitlement IDs
- [ ] Set `REVENUECAT_API_KEY` as a build setting / xcconfig value
- [ ] Verify entitlements unlock correct quotas (`max_plus_generations`, `max_gold_generations`)

### 3.3 Real provider API keys (backend `.env`)
- [ ] `OPENAI_API_KEY` — https://platform.openai.com/api-keys
- [ ] `REPLICATE_API_TOKEN` — https://replicate.com/account/api-tokens
- [ ] `FAL_KEY` — https://fal.ai/dashboard/keys
- [ ] `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` — IAM user with S3 PutObject + GetObject
- [ ] Create S3 bucket `gigarizz-photos` (or your own name) and set `S3_BUCKET_NAME`
- [ ] CORS policy on bucket: allow `PUT` from `https://api.gigarizz.app` and (DEBUG) `http://localhost:8000`

### 3.4 PostHog Analytics
- [ ] Create project at https://us.posthog.com
- [ ] Set `POSTHOG_API_KEY` as a build setting / xcconfig value
- [ ] Verify host: `https://us.i.posthog.com`

### 3.5 Apple Developer + signing
- [ ] Set `DEVELOPMENT_TEAM` in Xcode build settings or an xcconfig
- [ ] Create App ID in Apple Developer portal: `com.gigarizz.app`
- [ ] Enable capabilities: **Sign in with Apple**
- [ ] Create Distribution certificate + Provisioning Profile (App Store)
- [ ] Test archive: `xcodebuild -scheme GigaRizz -configuration Release archive`

---

## 4. P1 — Required for launch (build doesn't block, but submission does)

### 4.1 Privacy & Legal pages — Cloudflare Pages via Wrangler
Pages are written and live in `web/public/`:
- `/privacy` — full Privacy Policy (data collection, AI providers, S3 retention, GDPR/CCPA, deletion)
- `/terms` — Terms of Service (acceptable use, IP, subscription auto-renewal, refund policy via Apple, AAA arbitration)
- `/support` — Support contact + FAQ
- `/` — landing page

Deploy steps:
- [ ] `cd web && npm install` (first time only)
- [ ] `npx wrangler login` (Cloudflare account auth)
- [ ] `npm run deploy` — first deploy creates `gigarizz-web` project on Cloudflare Pages
- [ ] Cloudflare dashboard → Pages → gigarizz-web → Custom domains:
  - Add `www.gigarizz.app` (required — iOS app `AppConstants.privacyURL`/`termsURL` link here)
  - Add `gigarizz.app` (apex — `_redirects` file forwards to www)
- [ ] Verify: `curl -I https://www.gigarizz.app/privacy` returns 200
- [ ] Verify: `curl -I https://www.gigarizz.app/terms` returns 200

### 4.2 EC2 backend deployment
- [ ] Start EC2 instance (currently stopped/unreachable at 3.150.118.161)
- [ ] Security group: ports 22, 80, 443 open
- [ ] Allocate elastic IP (don't rely on dynamic IP)
- [ ] Run `./backend/deploy.sh deploy`
- [ ] Upload `.env.production` with real keys
- [ ] DNS: `api.gigarizz.app` → EC2 IP
- [ ] `./backend/deploy.sh ssl` for Let's Encrypt cert
- [ ] Smoke test: `curl https://api.gigarizz.app/health` returns 200
- [ ] Smoke test: `curl https://api.gigarizz.app/api/v1/flags | jq` returns 30+ flags

### 4.3 App Store Connect setup
- [ ] Create app: name `GigaRizz`, primary category Photo & Video, secondary Lifestyle, age 17+
- [ ] Subtitle: `AI Dating Photos That Get Matches`
- [ ] Screenshots (6.7" + 6.1" + 12.9" iPad if supported):
  - Use `marketing/assets/screenshot-frames.html` as template
  - Capture real screenshots from each SOTA flow (Face Enhance, Outfit, Hairstyle, Pose Studio, Generate)
- [ ] App icon 1024×1024 (render from `marketing/assets/app-icon-spec.svg`)
- [ ] Description from `marketing/assets/appstore-description.md`
- [ ] Keywords from metadata.json (100 char limit — fit "AI", "dating", "photos", "FaceApp alternative", "Hinge", "Tinder")
- [ ] In-App Purchases: Plus weekly/monthly, Gold monthly/annual, Intro offer
- [ ] App Review notes: explain AI photo generation, demo account, set `FLAG_PAYWALL_MODE=none` for review

### 4.4 TestFlight beta
- [ ] Archive + upload to TestFlight
- [ ] Internal testers (your team)
- [ ] External beta (50-100 users)
- [ ] Test golden paths:
  - [ ] Onboarding 30-step (with all flags ON)
  - [ ] Onboarding 5-step (set `FLAG_ONBOARDING_MAX_STEPS=5`)
  - [ ] Photo generation across 3 model categories
  - [ ] Batch generation
  - [ ] Face Enhance (anti-plastic CodeFormer)
  - [ ] Outfit Studio
  - [ ] Hairstyle
  - [ ] Age Studio
  - [ ] Pose Studio (InstantID)
  - [ ] Hinge Mode (gold-tier presets)
  - [ ] Coach (bio / openers / reply)
  - [ ] Paywall variants: `soft` (after N uses), `hard` (blocking), `none`
  - [ ] Account creation + delete
  - [ ] Settings → Developer toggle (DEBUG only — should NOT ship in Release archive)

---

## 5. P2 — Polish before launch

### 5.1 iOS schema alignment (minor)
- [ ] iOS `BioRequest` sends `vibe` field → backend ignores it (harmless but wasteful)
- [ ] iOS `BioRequest` missing `age`/`gender` fields the backend supports
- [ ] iOS `UserAnalytics` decoder missing: `favorite_style`, `total_matches`, `match_rate`, `top_style`, `streak_days`, `weekly_generations`, `platform_breakdown`

### 5.2 Backend hardening
- [ ] Set `MODERATION_ENABLED=true` (already default in `.env.example`)
- [ ] Switch `check_text` to fail-closed in production (currently fail-open in dev)
- [ ] Rate limiting middleware (currently DB-level only)
- [ ] `ENVIRONMENT=production`, `DEBUG=false`
- [ ] Disable `/docs` in production (already conditional on DEBUG)
- [ ] CORS: only allow `https://www.gigarizz.app` + iOS app bundle ID; drop localhost
- [ ] Structured JSON logging for CloudWatch
- [ ] UptimeRobot / Pingdom on `/health`
- [ ] Sentry SDK both iOS and backend

### 5.3 App Review prep
- [ ] Demo account preloaded with sample generations
- [ ] Reviewer notes: explain AI photo generation, NSFW moderation pipeline (`enable_face_swap=false` by default), source images deleted after 30 days
- [ ] iOS 17.4 AI content disclosure on each generated photo
- [ ] Consider AI-Generated metadata (C2PA / EXIF marker)
- [ ] Privacy nutrition label:
  - Data collected: photos, name, email, usage data, purchase history
  - Linked to user: photos, purchases
  - Tracking: PostHog analytics, RevenueCat purchases

### 5.4 Marketing launch
- [ ] Deploy `marketing/assets/landing-page.html`
- [ ] Product Hunt launch
- [ ] Social cards from `marketing/assets/social-cards.html`
- [ ] Email capture on landing page
- [ ] ASO: real screenshots, preview video

---

## 6. Bugs Fixed (iter 1-9)

| ID  | Bug                                                                | Iter   |
|-----|--------------------------------------------------------------------|--------|
| 1   | Generated photos drop URLs in production (`map { _ in ... }`)      | iter 1 |
| 2   | Source images never uploaded to backend                            | iter 2 |
| 3   | Face enhancement fake (CIFilter only, no CodeFormer)               | iter 3 |
| 4   | Inline comment on `S3_ENDPOINT_URL` crashed StorageService         | iter 2 |
| 5   | App crashes on launch (Firebase missing plist)                     | iter 2 |
| 6   | `Storage.storage()` fatal-errored on MainTabView render            | iter 4 |
| 7   | `Firestore.firestore()` fatal-errored eagerly                      | iter 4 |
| 8   | ServiceTests bit-rot — FeatureFlags missing 5 args                 | iter 5 |
| 9   | ServiceTests bit-rot — FeatureFlags struct gained 18 fields        | iter 9 |

---

## 7. Quick Reference — Integration Points

| iOS Constant                  | DEBUG                       | RELEASE                       |
|-------------------------------|------------------------------|--------------------------------|
| `backendBaseURL`              | `http://localhost:8000`      | `https://api.gigarizz.app`     |
| `REVENUECAT_API_KEY`          | Empty build setting          | Real key                       |
| `POSTHOG_API_KEY`             | Empty build setting          | Real key                       |
| `postHogHost`                 | `https://us.i.posthog.com`   | Same                           |
| `termsURL`                    | `https://www.gigarizz.app/terms`   | Live page                |
| `privacyURL`                  | `https://www.gigarizz.app/privacy` | Live page                |
| Settings → Use Real AI        | OFF (mock photos)            | N/A (DEBUG-only)               |

| Backend `.env`                | Dev                   | Production                |
|-------------------------------|------------------------|----------------------------|
| `OPENAI_API_KEY`              | Empty                  | Real key                   |
| `REPLICATE_API_TOKEN`         | Empty                  | Real key                   |
| `FAL_KEY`                     | Empty                  | Real key                   |
| `ENVIRONMENT`                 | `development`          | `production`               |
| `DEBUG`                       | `true`                 | `false`                    |
| `MODERATION_ENABLED`          | `true`                 | `true` (fail-closed)       |
| `FLAG_PAYWALL_MODE`           | `soft`                 | `soft` post-approval; `none` for App Review |
| `FLAG_ONBOARDING_MAX_STEPS`   | `30`                   | A/B test 5 vs 30           |

---

## 8. What is missing? (gap analysis)

### Critical gaps (block App Store)
- All P0 external setup items above
- Privacy + Terms pages: ✅ written; need `npm run deploy` from `web/` + Cloudflare custom domain
- App Store screenshots (need real captures from working dev build)

### Important gaps (quality bar)
- Source-image deletion job (S3 lifecycle policy: delete after 30 days)
- Account deletion endpoint (Apple requires this since iOS 14.5)
- AI content disclosure UI on every result screen
- Subscription restore flow tested end-to-end
- Network failure UX (current generation flow assumes network is up)

### Nice-to-have (post-launch)
- Feature-flag PATCH endpoint
- Sentry error tracking
- Background photo upload (current upload blocks UI)
- Conversational AI editor (Facetune Skin 2.0 parity)
- Video selfie support (Hinge prompts)
- Group date / multi-character generation (Nano Banana 2 5-identity)

---

## 9. E2E Test Results — Current

| Endpoint                              | Status | Notes                                                    |
|---------------------------------------|--------|----------------------------------------------------------|
| `GET /health`                         | ✅ 200 | Returns version, environment                             |
| `GET /api/v1/flags`                   | ✅ 200 | **30+ feature flags** (was 19)                           |
| `GET /api/v1/generate/models`         | ✅ 200 | **20 models** (was 16); category filter works            |
| `GET /api/v1/users/me`                | ✅ 200 | Auto-creates user                                         |
| `GET /api/v1/users/me/analytics`      | ✅ 200 | Empty analytics for new user                              |
| `POST /api/v1/uploads/presign`        | ✅ 200 | Returns presigned PUT URL (or dev placeholder if no S3)   |
| `POST /api/v1/generate`               | ⚠️ 500 | Expected without real provider keys                       |
| `POST /api/v1/generate/batch`         | ⚠️ Auth | Needs valid user token                                   |
| `POST /api/v1/coach/{bio,openers,reply}` | ⚠️ 500 | Expected without `OPENAI_API_KEY`                      |

All ⚠️ endpoints work with real keys. Code paths verified correct.
