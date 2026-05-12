# GigaRizz — Core User Flow

> Last updated 2026-05-01 after iter 9 (server-driven feature flag system).
>
> Every gate below is **server-driven**: flag values come from `GET /api/v1/flags` (cached for 1h on iOS). Edit `backend/.env` and the live app re-shapes itself on next refresh.

---

## 1. Cold launch path

```
[ User taps app icon ]
        │
        ▼
┌──────────────────────────────────────────────────┐
│ GigaRizzApp.init                                 │
│   • Firebase guard:                              │
│       Bundle.main.url("GoogleService-Info") != nil │
│       → FirebaseApp.configure() else skip        │
│   • RevenueCat guard:                            │
│       AppConstants.revenueCatAPIKey != "appl_REPLACE..." │
│       → Purchases.configure() else skip          │
│   • PostHog guard: same pattern                  │
│   • FeatureFlagManager loads cached flags        │
└──────────────────────────────────────────────────┘
        │
        ▼
[ FeatureFlagManager.refreshIfNeeded() — fires from .task on root view ]
        │
        ▼
┌──────────────────────────────────────────────────┐
│ flags.onboarding_enabled?                        │
│   YES → OnboardingFlow                           │
│   NO  → skip to Auth                             │
└──────────────────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────────────────┐
│ OnboardingFlow                                   │
│   • Capped at flags.onboarding_max_steps (≤30)   │
│   • Quiz step shown if flags.onboarding_quiz_enabled │
│   • "Skip" CTA shown if flags.onboarding_skip_enabled │
│   • Social proof / testimonials / video demo     │
│     each gated by their own flag                 │
└──────────────────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────────────────┐
│ Auth                                             │
│   • Apple Sign-In primary                        │
│   • DEBUG: dev_auth_bypass UserDefault           │
│     → skip Apple ID (for simulator testing)      │
└──────────────────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────────────────┐
│ flags.paywall_mode                               │
│   "hard" → PaywallView blocks until purchase     │
│   "soft" → home renders; paywall on Nth use     │
│            (N = flags.soft_paywall_after_uses)   │
│   "none" → no paywall (App Review demo)          │
└──────────────────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────────────────┐
│ MainTabView                                      │
│   ┌─ Home    ─ 4 Quick Actions (flag-filtered)   │
│   ├─ Tools   ─ 13 tiles (each flag-gated)        │
│   ├─ Coach   ─ Bio writer / openers / reply      │
│   ├─ Matches ─ Local match tracker               │
│   └─ Settings─ Subscription, account, [DEBUG: Use Real AI] │
└──────────────────────────────────────────────────┘
```

---

## 2. Generate flow (golden path)

This is the most-trafficked flow. All 6 SOTA tools below funnel into the same backend pipeline.

```
[ User picks photo via PhotosPicker ]
        │
        ▼
┌──────────────────────────────────────────────────┐
│ AIGenerationService.generate()                   │
│   • ServiceMode.current decides:                 │
│     - DEBUG && UserDefault.dev_use_real_ai       │
│       → real backend                             │
│     - else → mock photos (fast iteration)        │
└──────────────────────────────────────────────────┘
        │ real-mode branch
        ▼
┌──────────────────────────────────────────────────┐
│ PhotoUploadService.upload(image)                 │
│   1. Resize to 1600px max-side                   │
│   2. Encode JPEG q=0.85                          │
│   3. POST /api/v1/uploads/presign                │
│      → { upload_url, asset_url }                 │
│   4. PUT to upload_url                           │
│   5. Return asset_url                            │
└──────────────────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────────────────┐
│ POST /api/v1/generate                            │
│   {                                              │
│     model: "nano-banana-2",                      │
│     style: "outfit_swap",                        │
│     source_image_urls: [...],                    │
│     pose_image_url: nullable,                    │
│     prompt_overlay: nullable                     │
│   }                                              │
│ → backend creates prediction                     │
│ → returns { prediction_id, status: "pending" }   │
└──────────────────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────────────────┐
│ Polling loop                                     │
│   GET /api/v1/generate/status/{id} every 2s     │
│   until status ∈ {succeeded, failed, canceled}   │
└──────────────────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────────────────┐
│ Result screen                                    │
│   • compactMap result_urls into GeneratedPhoto   │
│     (BUG-1 fix: don't drop URLs)                 │
│   • Save to GalleryStore                         │
│   • Share sheet (Hinge / Tinder / iMessage)      │
└──────────────────────────────────────────────────┘
```

---

## 3. Per-feature flow matrix

| Surface          | Entry point          | Flag                         | Model used                   | Style enum         | Identity-preserving |
|------------------|----------------------|-------------------------------|------------------------------|-------------------|---------------------|
| Generate (free)  | Home Quick Action / Tab | `enable_generation`          | User picks (16 free models)  | preset/custom     | depends on model    |
| Face Enhance     | Home QA / ToolsHub   | `enable_face_enhance`         | CodeFormer (Replicate)       | `face_restore`    | ✅ (anti-plastic)   |
| Outfit Studio    | Home QA / ToolsHub   | `enable_outfit_studio`        | Nano Banana 2 (fal.ai)       | `outfit_swap`     | ✅                  |
| Hairstyle        | Home QA / ToolsHub   | `enable_hairstyle`            | Nano Banana 2 (fal.ai)       | `hairstyle_swap`  | ✅                  |
| Age Studio       | ToolsHub             | `enable_age_studio`           | Nano Banana 2 (fal.ai)       | `age_modify`      | ✅                  |
| Pose Studio      | ToolsHub             | `enable_pose_studio`          | InstantID (Replicate)        | `custom`          | ✅ (locks face)     |
| Hinge Mode       | ToolsHub → Generate  | `enable_hinge_overlay`        | GPT Image 2 (OpenAI)         | `hinge_prompt`    | text overlay        |
| Background       | ToolsHub             | `enable_background_replacer`  | Flux/SDXL (Replicate)        | preset            | depends             |
| Photo Ranking    | ToolsHub             | `enable_photo_ranking`        | n/a (Vision framework)       | n/a               | n/a                 |
| Color Grade      | ToolsHub             | `enable_color_grade`          | n/a (CoreImage)              | n/a               | n/a                 |
| Expression Coach | ToolsHub             | `enable_expression_coach`     | n/a (Vision framework)       | n/a               | n/a                 |
| Pose Library     | ToolsHub             | `enable_pose_library`         | n/a (static images)          | n/a               | n/a                 |
| Coach            | Tab                  | `enable_coach`                | OpenAI gpt-4o-mini           | n/a               | n/a                 |

---

## 4. Paywall trigger points

| Mode    | Trigger                                                       | Dismissible? | Use case            |
|---------|---------------------------------------------------------------|--------------|---------------------|
| `none`  | Never shown                                                   | n/a          | App Review demo     |
| `soft`  | Nth generation (where N = `soft_paywall_after_uses`, default 3) | Yes        | Standard production |
| `hard`  | Right after onboarding, blocks Home                          | No           | A/B test            |

The mode is read once on cold launch from `flags.paywall_mode`. Switching mode requires user to refresh flags (force-quit app or wait 1h).

### Free tier quotas (server-enforced via `flags.max_free_generations`)
- Free: 3 generations
- Plus: 30 generations
- Gold: 999 generations (effectively unlimited)
- Batch ceiling across all tiers: `flags.max_batch_models` (default 4)

---

## 5. Onboarding flow detail

```
Step 1   — Welcome / hero video         (gated by onboarding_show_video_demo)
Step 2-5 — Pain-point qualification    (always)
Step 6   — Social proof carousel        (gated by onboarding_show_social_proof)
Step 7-9 — Goal selection              (always)
Step 10-12 — Photo readiness quiz       (gated by onboarding_quiz_enabled)
Step 13-18 — Style preferences         (always)
Step 19   — Testimonial card            (gated by onboarding_show_testimonials)
Step 20-25 — Personalization Q&A       (always)
Step 26-29 — App tour                   (always)
Step 30   — Sign in / Skip CTA          (skip gated by onboarding_skip_enabled)
```

A&B testing knobs:
- `onboarding_max_steps=5` collapses to lean acquisition flow (skip 6-29)
- `onboarding_max_steps=30` (default) is the luxury flow
- `onboarding_quiz_enabled=false` removes the qualification quiz entirely

---

## 6. Error & fallback paths

| Failure                              | UX                                                              |
|--------------------------------------|-----------------------------------------------------------------|
| Backend unreachable                  | Mock service mode used silently (DEBUG); error toast (Release)  |
| `/api/v1/flags` fails                | Cached flags from last successful fetch                         |
| First-ever launch + flags fail       | `FeatureFlags.defaults` (everything enabled, paywall=`soft`)    |
| Source upload fails                  | Generation aborts with retry CTA; photo never reaches provider  |
| Provider returns 0 URLs              | Fixed in BUG-1 — `compactMap` filters; user sees empty result   |
| Firebase missing plist               | SDK init skipped; no auth UI (DEBUG bypass available)           |
| RevenueCat not configured            | Subscription tab shows "Manage subscription" disabled            |
| `MODERATION_ENABLED=true` + bad text | Backend returns 400 with content-policy reason                  |

---

## 7. What gates each surface (flag → file map)

```
HomeView.visibleQuickActions filter
  → GigaRizz/Sources/Features/Home/HomeView.swift
  → Reads: enable_generation / enable_face_enhance / enable_outfit_studio / enable_hairstyle

ToolsHubView per-tile gates
  → GigaRizz/Sources/Features/Tools/ToolsHubView.swift
  → Reads: enable_face_enhance / enable_outfit_studio / enable_hairstyle / enable_age_studio
            / enable_pose_studio / enable_hinge_overlay / enable_background_replacer
            / enable_photo_ranking / enable_color_grade / enable_expression_coach / enable_pose_library

PaywallView mode dispatch
  → GigaRizz/Sources/Features/Paywall/PaywallView.swift (if exists)
  → Reads: paywall_mode / soft_paywall_after_uses

OnboardingFlow step gating
  → GigaRizz/Sources/Features/Onboarding/...
  → Reads: onboarding_enabled / onboarding_quiz_enabled / onboarding_skip_enabled
            / onboarding_max_steps / onboarding_show_social_proof
            / onboarding_show_testimonials / onboarding_show_video_demo

FeatureFlagManager.shared
  → GigaRizz/Sources/Core/Services/FeatureFlagManager.swift
  → Single source of truth; cached in UserDefaults("gigarizz_feature_flags")
```

---

## 8. Operating playbook (post-launch)

### "User reports SOTA feature broken"
1. Check `curl https://api.gigarizz.app/api/v1/flags | jq .enable_<feature>`
2. If `false`, flip `FLAG_ENABLE_<FEATURE>=true` in `/srv/gigarizz/.env` and restart
3. If `true`, check provider status (Replicate / fal.ai / OpenAI dashboards)
4. Last resort: `FLAG_ENABLE_<FEATURE>=false` to hide the broken surface

### "App Review submission"
1. `FLAG_PAYWALL_MODE=none`
2. `FLAG_ONBOARDING_SKIP_ENABLED=true`
3. Restart backend
4. Submit; reviewer sees free unlimited app
5. After approval: flip `FLAG_PAYWALL_MODE=soft`

### "Onboarding A/B test"
1. Even iOS device IDs → `FLAG_ONBOARDING_MAX_STEPS=5`
2. Odd iOS device IDs  → `FLAG_ONBOARDING_MAX_STEPS=30`
3. (Requires PATCH /api/v1/flags admin endpoint — currently in backlog)

### "Surge protection"
1. `FLAG_MAX_FREE_GENERATIONS=1` to throttle anonymous traffic
2. `FLAG_ENABLE_BATCH_GENERATION=false` to disable highest-cost surface
3. Investigate provider quota
