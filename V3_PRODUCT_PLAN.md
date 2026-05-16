# GigaRizz V3 Product Plan — Market Domination

> Last updated 2026-05-14.
> Predecessor: `V2_PRODUCT_PLAN.md` (audit-first profile upgrade studio, shipped in code).
> Companion: `V4_COMPETITOR_KILL_PLAN.md` (surgical, competitor-by-competitor counters), `PHOTO_EDITOR_RESEARCH.md` (FaceApp/Facetune teardown), `BACKLOG.md` (deferred items).

---

## V3 RESEQUENCE — PHOTO-FIRST (2026-05-14)

**Decision:** every V3 sprint now leads with one photo feature. Non-photo bets (Live Wingman keyboard, video, voice, Concierge cron) move to `BACKLOG.md` until the photo wedge is locked. See `PHOTO_EDITOR_RESEARCH.md` for the rationale: Tinder Face Check + Hinge Selfie Verification structurally disadvantage FaceApp/Facetune in the dating-photo context — that is the gap we exploit.

### Photo-First Hero Claim

> **The only AI photo editor that passes Hinge Selfie Verification and Tinder Face Check.** Better than FaceApp on naturalness. Better than Facetune on identity preservation. Built for dating profiles, not viral filters.

### Photo-First Sprint Order

| Sprint | Hero shipped | Status |
|--------|--------------|--------|
| 0 | IdentityMatchService (on-device face similarity), Naturalness intensity slider (Conservative/Standard/Bold), Glow Up Studio scaffold, backend `_wrap_natural` intensity-aware | ✅ Shipped 2026-05-14 |
| 1 | FaceCheck Pre-Flight, Identity Match Certificate, FaceDriftDetector (oversmoothing / eye widening / jaw narrowing / brightness / face size / mouth open), Face Refine Studio (smile enhance + add smile + jaw refine + nose refine + lip enhance + eye color + AI portrait), Glow Up Chain coordinator with rollback | ✅ Shipped 2026-05-14 |
| 2 | Photo Brief Studio — plain English brief + 13-scene curated catalog (helicopter, movie theatre, rooftop bar, art gallery, coffee shop, concert, yacht deck, ski lift, Tokyo street, Italian café, recording studio, motorcycle, private jet); per-variant Identity Match chips + drift count + signed certificate; backend `scene_*` GenerationStyle prompts with identity lock | ✅ Shipped 2026-05-15 |
| 3 | Reference Selfie Vault (set baseline once; auto-injected into Photo Brief Studio + Glow Up Studio + Settings) + Photo Sequence Optimizer per platform (Hinge/Tinder/Bumble per-slot ranking with rationale) | ✅ Shipped 2026-05-15 |
| 4 | Reference Selfie Quality Coach + 8 more dating scenes (gym, sailing race, sushi bar, vineyard, observation deck, dog park, golf course, dance studio) bringing the catalog to 21 environments + Generation Receipt JPEG embedding via EXIF UserComment | ✅ Shipped 2026-05-15 |
| 5 | Age-Faithful drift signal (composite of skin texture amplification + face darkening — Sway AI counter), Before/After compare slider in Photo Brief Studio variant detail, Glow Up Chain V2 with backend `face_restore` step | ✅ Shipped 2026-05-15 |
| 6 | Live in-flight Glow Up Chain preview (per-step thumbnails + final before/after slider in GlowUpStudioView), Save-with-receipt to Photos (JPEG bytes preserved so EXIF UserComment cert survives), Inline Naturalness slider directly in Photo Brief Studio | ✅ Shipped 2026-05-15 |
| 7 | Multi-photo Reference Selfie Vault — auto-pick best baseline from a stored album | Next |

Sprints 7+ resume the original V3 bets (Match Outcome Capture, Concierge cron, Live Wingman) once photo features have a 30-day usage signal.

### What shipped on 2026-05-14 (code)

**Sprint 0 (foundations):**
- `Core/Services/IdentityMatchService.swift` — on-device Vision-framework face similarity. Largest-face detection, padded face crop, `VNFeaturePrintObservation` distance, mapping to four bands.
- `Core/Services/NaturalnessSettings.swift` — 0–100 intensity slider with three named levels (Conservative default / Standard / Bold). Each maps to a backend prompt wrapper and an identity-match threshold.
- `Features/Upgrade/GlowUpStudioView.swift` — audit-driven photo improver routing each detected issue to the right tool. Only surfaces fixes that help *this* photo.
- `Features/Settings/SettingsView.swift` — naturalness slider UI with live band labels.
- `backend/app/services/generation_service.py` `_wrap_natural(prompt, intensity)` — three prompt wrappers per band (Conservative locks features harder; Bold allows more styling).
- Schema + router + iOS API client wire `naturalness_intensity` through `/api/v1/generate`.

**Sprint 1 (photo improvement engine):**
- `Core/Services/FaceDriftDetector.swift` — six on-device drift signals using Vision face landmarks: oversmoothing (skin Laplacian variance), eye widening (eye/face ratio), jaw narrowing (jaw/face ratio), brightness shift, face size shift, mouth open change. Returns a structured `Report` consumed by FaceCheck Pre-Flight.
- `Core/Models/IdentityMatchCertificate.swift` — Codable signed JSON edit receipt + `IdentityMatchCertificateService.issue/verify` using HMAC-SHA256 with a per-device key. Counters FaceApp/Facetune opacity.
- `Features/Upgrade/FaceCheckPreflightView.swift` — predicts Hinge + Tinder Face Check pass/fail. Combines Identity Match similarity + drift signals into a Pass / Borderline / Fail verdict with named reasons. One-tap "Regenerate at lower intensity" CTA.
- `Features/Upgrade/FaceRefineStudioView.swift` — the generative companion to FaceEnhancementView. Smile enhance / Add smile / Jaw refine / Nose refine / Lip enhance / Eye color (Blue/Green/Hazel/Brown/Gray) / Editorial AI portrait. Each routes to backend GPT Image 2 / Nano Banana 2 with the identity-preserving wrapper at the user's chosen intensity. Result auto-runs IdentityMatchService + FaceDriftDetector and issues an Identity Match Certificate.
- `Features/Upgrade/GlowUpChainCoordinator.swift` — sequential apply with per-step Identity Match scoring + rollback. V1 chain: local face enhance (CIFilter skin smooth/saturation) → color grade (exposure lift). Stops at the first regression beyond the tolerance.
- `Features/Upgrade/GlowUpStudioView.swift` — now wires the chain into the primary CTA with a step-by-step results panel.
- `backend/app/models/schemas.py` — new `GenerationStyle` enums: `smile_enhance`, `add_smile`, `jaw_refine`, `nose_refine`, `lip_enhance`, `eye_color_swap`, `ai_portrait`. Each has a dedicated identity-preserving prompt template in `STYLE_PROMPTS`.

**Sprint 6 (Live Chain Preview + Save-with-Receipt + Inline Naturalness):**
- `Features/Upgrade/GlowUpChainCoordinator.swift` — adds `@Published currentStep` so the studio UI can render the in-flight step. State is reset between runs.
- `Features/Upgrade/GlowUpStudioView.swift` — chain results panel now shows per-step thumbnails (44pt), an in-flight row with spinner for the current step, and a `BeforeAfterCompare` slider on the final image vs the user's reference selfie when one is available.
- `Core/Services/PhotoLibraryService.swift` — adds `saveJPEGData(_:)` that calls `addResource(with: .photo, data:, options:)` so the JPEG bytes (with embedded EXIF UserComment certificate) survive into the user's library. The legacy `creationRequestForAsset(from: UIImage)` path strips custom EXIF.
- `Features/Upgrade/PhotoBriefStudioView.swift` (BriefResultDetailSheet) — new "Save with receipt to Photos" button with idle / saving / saved / failed states. Inline Naturalness slider in the studio footer (was previously Settings-only) so users can tune intensity without leaving the generation flow.

**Sprint 5 (Age-Faithful Lock + Compare Slider + Chain V2):**
- `Core/Services/FaceDriftDetector.swift` — adds `apparentAgeShift` Signal triggered by (a) skin variance ratio >1.5 OR (b) skin variance ratio >1.2 paired with a >0.15 face brightness drop. Direct counter to Sway AI's "looks older than actual age" complaint cluster. Surfaces in FaceCheck Pre-Flight + Photo Brief Studio variant detail.
- `Core/Design/Components/BeforeAfterCompare.swift` — draggable curtain that reveals reference vs candidate side-by-side. Wired into BriefResultDetailSheet so users can visually verify the variant against their stored reference selfie. Hero proof of "looks like you."
- `Features/Upgrade/PhotoBriefStudioView.swift` — variant detail sheet uses BeforeAfterCompare when a vault selfie is available, otherwise falls back to single-image view.
- `Features/Upgrade/GlowUpChainCoordinator.swift` — V2 chain inserts a backend `face_restore` step (CodeFormer via the existing `face_restore` model) between `localEnhance` and `colorGrade`. Identity-match-gated rollback unchanged. Adds anti-plastic + blur recovery to the local-only V1 chain.

**Sprint 4 (quality coach + scene expansion + receipt embedding):**
- `Core/Services/ReferenceSelfieQuality.swift` — wraps `PhotoQualityAnalyzer` to score the stored reference selfie (excellent / acceptable / poor) with critical-vs-cosmetic issue flagging. Surfaced as a banner in `PhotoBriefStudioView` whenever the verdict is below excellent so users fix the baseline before burning generations.
- `Core/Services/CertificateEmbedding.swift` — stamps the `IdentityMatchCertificate` JSON into the JPEG's EXIF `UserComment` tag so the receipt travels with the photo whenever the user shares it. Uses `CGImageDestination` to keep ImageIO's full property set intact. Round-tripping verified by `extract(from:)`.
- `Features/Upgrade/PhotoBriefStudioView.swift` (BriefResultDetailSheet) — the share button now writes a temp JPEG with the receipt embedded and shares the URL instead of the bare `Image` so downstream apps preserve the metadata.
- `backend/app/models/schemas.py` — 8 new GenerationStyle enums: `scene_gym`, `scene_sailing_race`, `scene_sushi_bar`, `scene_vineyard`, `scene_observation_deck`, `scene_dog_park`, `scene_golf_course`, `scene_dance_studio`. Catalog is now **21 dating environments**.
- `backend/app/services/generation_service.py` — matching identity-locked prompt templates for each new scene.
- `backend/tests/test_api.py` — extends scene-style validation + bumps the identity-preserving assertion count from 13 to 21.
- `Core/Models/PhotoScene.swift` — adds the matching iOS catalog entries plus a new `active` Category bucket (Gym, Sailing race, Golf, Dance studio).

**Sprint 3 (Reference Vault + Photo Sequence Optimizer):**
- `Core/Services/ReferenceSelfieVault.swift` — `@MainActor ObservableObject` singleton. Persists the user's baseline selfie to Application Support (excluded from backups). Now auto-injected into PhotoBriefStudioView + GlowUpStudioView so users set their reference once and every photo-aware feature trusts it. Old "pick a selfie every time" friction is gone.
- `Features/Settings/SettingsView.swift` — new "Reference Selfie Vault" section with thumbnail preview, replace, and forget. Replaces the previous "go set a selfie elsewhere" coaching cards across the photo features.
- `Features/Upgrade/PhotoSequenceOptimizerView.swift` — per-platform lineup ranker (Hinge / Tinder / Bumble / Raya). Reuses `ProfileKitOrderer` for the algorithm and adds per-slot **rationale** text ("Hinge swipers spend 92% of their attention on slot 1…", "Tinder reward stacking: a strong second-slot face shot lifts swipe-through ~18%…"). Surfaces unfilled slot types per platform.
- `Features/Upgrade/ProfileDiagnosisView.swift` — new "Photo Sequence Optimizer" entry card with Hinge/Tinder/Bumble icon. Maps the audit's wire-format platform strings to typed `DatingPlatform` values.

**Sprint 2 (scene catalog + conversational brief):**
- `Core/Models/PhotoScene.swift` — 13-scene curated dating catalog organized by category (Adventure, Cinematic, Lifestyle, Travel, Professional). Each scene maps to a backend `scene_*` GenerationStyle and seeds the brief field.
- `Features/Upgrade/PhotoBriefStudioView.swift` — hero view: reference selfie picker, scene picker (or skip), plain-English brief field (250 char), variant count picker. Each generation runs through identity lock + drift detection + signed certificate per variant. Result tiles show IdentityMatch chip + drift count.
- `Features/Upgrade/ScenePickerSheet.swift` — visual catalog sheet with 5 categories, blurb per scene, "Built to beat ReGen" framing.
- `Features/Upgrade/BriefResultDetailSheet.swift` (in PhotoBriefStudioView.swift) — full-screen variant detail with metrics, drift report, share, certificate sheet.
- `Features/Upgrade/ProfileDiagnosisView.swift` — new "Photo Brief Studio" entry card directly under the Build Kit CTA so users land in the new flow after audit.
- `backend/app/models/schemas.py` — 13 new `GenerationStyle` enums (`scene_helicopter`, `scene_movie_theatre`, `scene_rooftop_bar`, `scene_art_gallery`, `scene_coffee_shop`, `scene_concert`, `scene_yacht_deck`, `scene_ski_lift`, `scene_tokyo_street`, `scene_italian_cafe`, `scene_recording_studio`, `scene_motorcycle`, `scene_private_jet`).
- `backend/app/services/generation_service.py` — matching `STYLE_PROMPTS` templates. Every prompt opens with the "Same person as the reference photo, same face" lock and ends with "Do not alter the face" — identity-preservation contract is enforced at the prompt layer.
- `backend/tests/test_api.py` — `test_generation_accepts_v3_sprint2_scene_styles` (schema validation across all 13 styles) + `test_scene_prompts_are_identity_preserving` (every prompt enforces the identity lock + 3:4 aspect).
- `Core/Services/IdentityMatchService.swift` — refactored to a single nonisolated detached worker so non-Sendable Vision observations never cross actor boundaries (iOS 26 Sendable strictness fix uncovered while wiring Sprint 2).

**Backend tests:** `35/35` passing through Sprint 4 (test count covers Sprint 2 + 4 scene additions; idempotent and identity-preserving asserts updated to 21 scenes).
**iOS Debug simulator build:** clean (`** BUILD SUCCEEDED **`) after every regenerate-and-build cycle through Sprint 4.

### FaceCheck Pre-Flight (Sprint 1 hero)

The single most defensible feature in the category. FaceApp and Facetune *cannot* ship this without cannibalizing their power-user behavior — their products incentivize the kind of editing that fails verification.

**Mechanism:**
1. User selects a generated or edited photo to upload.
2. GigaRizz runs IdentityMatchService against the user's reference selfie.
3. If similarity ≥ band threshold AND no detected drift signals (oversmoothing, eye widening, jaw narrowing) — surface a green "Predicted to pass Face Check" badge.
4. If borderline or failing — surface specific reasons and offer a one-tap regenerate at a lower intensity.
5. Backend logs the prediction so we can calibrate against real verification outcomes.

**Why now:** Tinder Face Check went US-wide in 2025. Hinge made Selfie Verification mandatory in UK + Australia and the rest of the world is following. Match Group reports >50% drop in bad-actor interactions where Face Check is live. The dating photo market that *can pass verification* is the only photo market that matters now.

### Identity Match Certificate (Sprint 2 hero)

Every exported photo gets a signed JSON edit receipt:

```json
{
  "kit_id": "...",
  "photo_id": "...",
  "original_hash": "sha256:...",
  "naturalness_intensity": 25,
  "identity_match_score": 0.84,
  "identity_match_band": "acceptable",
  "tools_applied": ["face_restore", "color_grade"],
  "drift_signals": [],
  "verified_at": "2026-05-14T10:42:00Z",
  "signature": "..."
}
```

Shipped alongside every Save / Share / Copy export. Counters the FaceApp/Facetune "what did this app actually do to my photo" opacity. Builds the brand claim *"every photo we ship has a receipt."*

### Audit-Driven Glow Up (Sprint 3 hero)

Today's Glow Up Studio routes each issue to the right tool one-tap. Sprint 3 upgrades this to chain the fixes: tap *Apply Glow Up* and the engine sequentially runs the lighting fix, then face restore, then background swap, with the identity match score re-computed after each step and the user shown a before/during/after comparison. Stop the chain at the first regression. Beats Facetune's "tool drawer" UX with a single "make this photo good" gesture.

---

## V3 Mission

V2 made GigaRizz the **AI dating profile studio**. V3 makes it the **only thing that actually keeps working after the user gets matches** — turning a one-shot generator into a continuous dating system the user pays for monthly because it keeps producing outcomes.

> V2 promise: *Upload your photos. Get a better dating profile today.*
> V3 promise: *Keep your dating profile winning, week after week, until you stop dating.*

The shift is from **transaction** to **subscription with proven outcomes**. Every V3 feature exists to either:
1. Prove the kit worked (close the match-outcome loop), or
2. Re-engage the user with a reason to re-generate, or
3. Stay in the loop after matches arrive (date conversion, not just match count).

## V3 Strategic Bets

### Bet 1 — Close the outcome loop

Photofeeler measured photos but never proved match lift. Aragon and Regen generate photos but disappear after export. **GigaRizz V3 follows the user into the dating app and measures lift.**

Implementation:
- **Match outcome capture.** After 7 days post-export, push notification: "Send us screenshots of your last 20 swipes / likes / matches." OCR pulls the counts.
- **A/B kit experiments.** Generate two kit variants (e.g., Kit A leads with archetype X, Kit B leads with archetype Y). Track which one wins on real match data.
- **Lift dashboard.** "Kit v3 got you 2.4× more matches than Kit v1." This is *evidence*, not "AI dating photos."

This is the wedge no competitor has the data pipeline for. It also lets the App Store description finally make a real claim (3× more matches, *verified by your screenshots*).

### Bet 2 — Concierge subscription tier

Most users won't open the app weekly. **Concierge does it for them.**

Implementation:
- Every Sunday, Concierge runs a silent re-audit using the user's most recent uploaded screenshots (matches, opens, swipe rates).
- It produces *one* recommendation: "Swap photo #3 — your Wednesday match rate dropped 35% on rainy days. Try this version." or "Your bio's third line is killing reply rate; here's a tighter version."
- One-tap apply → regenerate → push to gallery.
- User feels they have a dating coach on staff.

Concierge becomes the headline feature of the $29.99/mo Pro tier and the reason users don't churn after 60 days.

### Bet 3 — Video

Hinge's video prompts and Tinder's "Loops" are growing. Competitors are still stuck at static images.

Implementation:
- **Video selfie → video Hinge prompt.** User records 10s. AI generates 3 punchier scripted versions, regenerates voice, recomposes b-roll, color-grades. Export as Hinge-ready MP4.
- **AI b-roll from photos.** Take the user's static photos and produce a 6s reel-style profile video (Ken Burns + motion + ambient sound).
- **Voice prompts.** Generate professionally-mixed voice notes for Hinge's voice prompts using the user's actual voice (consented sample) + AI-written script.

Voice is where the next 12 months of dating-app product investment will land. If GigaRizz owns "AI voice prompt for Hinge" before competitors notice, that's the next category.

### Bet 4 — Live AI Wingman

V2 ships screenshot-based coach. V3 ships **live-replying coach** — AI in the loop while the user is actively chatting.

Implementation:
- **iOS keyboard extension.** When user is typing in Hinge/Tinder/Bumble, a discreet GigaRizz row shows three reply suggestions in real time. One tap inserts.
- **Live screenshot watcher (no keyboard required).** User shares to GigaRizz from any dating-app screenshot via Share Sheet → AI replies in <2 seconds, copyable.
- **First-date AI planner.** Once a match commits to "let's grab a drink," GigaRizz suggests three venues based on the matched person's profile cues (their photos, prompts, bio) and the user's stated city.

This bet is operationally hard (keyboard extensions are notoriously rejected, OCR latency is real) but functionally devastating. **Nobody else owns the conversation loop.**

### Bet 5 — Verified outcomes + social proof

Trust is the category's biggest wound. Reviewers say "AI photos look fake." V3 turns that wound into the brand position.

Implementation:
- **Identity Match certificate.** Every generated photo is rated against a baseline selfie (face similarity + skin texture + naturalness). Photos passing the threshold get a "Looks like you" badge.
- **Verified before/after.** Users can opt into the public showcase: their before-after pair is anonymized (face-swapped or blurred to a recognizable style) and shown in app onboarding + landing page + ads.
- **Photofeeler-style human ratings.** Optional: pay 100 coins to get 20 anonymous human raters on a kit before export. Returns scores per archetype.
- **Anti-fake mode.** Toggle that goes beyond "keep me natural" — bans backgrounds the user has never been to, bans outfits they don't own (verified from upload history). This is *radical honesty as a feature*.

### Bet 6 — Native platform export

V2 exports a copy-and-paste kit. V3 exports a **one-tap-to-live profile**.

Implementation:
- **Hinge prompt one-tap.** Hinge has no public profile API, but every prompt is keyboard-fillable. GigaRizz generates a Shortcuts file that auto-fills the prompts. (Or use Hinge's profile creation deep links if any are public.)
- **Tinder/Bumble photo bundle.** Export a zip with photos pre-named in upload order, plus a clipboard-ready bio. Pushes to Photos app in a dedicated GigaRizz album.
- **AirDrop kit.** AirDrop to your friend for a sanity check before publishing.

Native export removes the last friction between "AI made me a profile" and "my profile is live."

## Information Architecture (V3 changes from V2)

V2 tabs: Upgrade / Photos / Coach / Profile.

V3 keeps these but adds:

- **Upgrade → Match Loop** sub-section once a kit is exported. Shows lift metrics, prompts to upload screenshots.
- **Coach → Live** tab inside the Coach screen for keyboard extension + first-date planner.
- **Profile → Concierge** entry point (subscriber-only).
- **Profile → Identity Vault** for the user's verified baseline selfie + match certificate history.

No tab rename. We don't want existing V2 testers to relearn the shell.

## Surface-Level Feature List (V3)

### Must-have (Sprint plan below)

1. Match Outcome Capture (screenshot-based OCR pipeline + match-count store).
2. Lift Dashboard (UI in Upgrade tab, persists per-kit).
3. Concierge Weekly Re-Audit (background task + push notification + one-tap re-generate).
4. Video Hinge Prompt Generation (backend video pipeline using GPT-4o + a video provider like Runway/Sora/Pika).
5. Voice Prompt Generation (TTS using ElevenLabs or OpenAI voice + user-cloned voice opt-in).
6. iOS Keyboard Extension (Live Wingman).
7. Identity Match Certificate (face-similarity service).
8. Native Hinge/Tinder Shortcut export.

### Should-have

9. AI Date Planner (post-match venue suggestions).
10. Verified before-after public showcase opt-in.
11. Anti-fake mode toggle (extends naturalness).
12. Photofeeler-style human rating marketplace (start with a curated panel before opening to public).
13. Hinge voice prompt vault (saved scripts the user can re-record monthly).
14. Reel-style auto-generated profile video from existing photos.

### Later (V3.x)

15. Live screenshot watcher daemon.
16. Multi-identity group photo generator (Nano Banana 2 5-identity, was Later in V2).
17. Conversational AI editor (Facetune Skin 2.0 parity from V2 backlog).
18. AR mirror try-on for outfit/hair preview before generation.

## Pricing & Monetization Update

V2 pricing was Free / Plus / Pro. V3 introduces **Concierge** as the new top tier.

| Tier        | Monthly | Annual  | What's in |
|-------------|---------|---------|-----------|
| Free        | $0      | $0      | 1 audit / mo, 2 generations, basic bio writer, no export. |
| Plus        | $14.99  | $99     | Unlimited audits, 50 generations/mo, full kit export, all archetype slots, screenshot coach. |
| Pro         | $29.99  | $199    | Everything in Plus + video prompts + voice prompts + Live Wingman keyboard + first-date planner + verified Identity Match. |
| **Concierge** | **$59.99** | **$399** | Everything in Pro + weekly automated re-audit + one human-curated review per quarter + private Slack to a dating consultant. |

Concierge is positioned for users who have tried Plus/Pro and want hands-off dating optimization. It also dramatically lifts LTV.

Intro offer: **$4.99 for the first 7 days of any paid tier**, after which it converts to the chosen monthly plan.

## Acquisition & Growth Loops (V3)

V2 launches with App Store + organic search. V3 builds three durable loops:

### Loop A — User-Generated Showcase

Every exported kit prompts the user: "Want to be in the GigaRizz showcase? Free month of Plus if your before/after is featured. Photos are anonymized."

The featured pairs power:
- The App Store screenshots.
- Landing page hero.
- TikTok/Instagram ads (one of the highest-CPM-killing creative types).
- An in-app "Hall of Glow-Ups" gallery as social proof during onboarding.

### Loop B — Match Outcome Stories

When a user reports a 2×+ match lift, the app offers: "Share your story (anonymous). $20 credit back." Stories become content for paid ads and SEO landing pages ("How I tripled my Hinge matches with AI" — written from real user data).

### Loop C — Friend Audit (referral mechanic)

Existing users can run a free audit on a friend's profile by uploading screenshots. Friend gets a real diagnosis. CTA: "Want the full kit? Get $20 off your first month." Friend converts at much higher rate than cold install because they already saw the diagnosis quality.

## Technical Plan

### Phase 1 — Match outcome instrumentation (foundation)

Goal: Capture real outcome data from day one of V3.

Tasks:
- Add `MatchOutcome` Codable model: `kitId`, `period (7d, 14d, 30d)`, `matches`, `swipes`, `messages`, `replies`, `platform`, `screenshotURLs`.
- Add `POST /api/v1/match-outcomes` endpoint. OCRs screenshots server-side (Vision OCR + GPT-4o number extraction).
- Add iOS `MatchOutcomeCapture` view: prompts via push notification 7/14/30 days post-export.
- Add `LiftDashboardView` in Upgrade tab: shows match rate before vs after kit, archetype performance, recommended next iteration.

### Phase 2 — Concierge

Tasks:
- Backend cron (Celery beat) runs weekly per-user.
- Pull last 4 weeks of match outcomes + most recent kit + last audit.
- Run a "delta audit": what changed, what regressed.
- Produce one recommendation: photo swap, bio rewrite, or prompt regenerate.
- Push notification: "Your weekly upgrade is ready."
- One-tap apply → regenerate → save to gallery.
- Subscriber-only (Concierge entitlement in RevenueCat).

### Phase 3 — Video pipeline

Tasks:
- Backend service `video_service.py`. Provider: start with fal.ai video model (Runway Gen-3 or Pika 1.5) — same API style as image providers.
- Endpoint `POST /api/v1/video/hinge-prompt` accepts user voice sample + script.
- Voice cloning: ElevenLabs Voice ID per user (optional, consent required).
- iOS `HingeVideoPromptView`: record 10s baseline, choose prompt question, generate 3 variants, preview, export MP4.

### Phase 4 — Live Wingman (keyboard extension)

Tasks:
- New target `GigaRizzKeyboard` in `project.yml` with type `app-extension`.
- Keyboard extension reads pasteboard or last-screenshot, sends to backend coach endpoint, returns 3 reply candidates.
- iOS host app activates the extension via Settings instructions.
- App Review prep: keyboard extensions are reviewed strictly. Document exactly what data leaves the device. Build a `KeyboardPrivacyView` in Settings explaining it.

### Phase 5 — Identity Match certificate

Tasks:
- Backend `identity_service.py` using OpenAI vision + a face-similarity score (Vision framework on-device backup).
- Compute similarity for every generated photo against the user's baseline selfie.
- Annotate each `GeneratedPhoto` with `identityMatchScore` and `identityMatchPassed` bool.
- iOS UI: green checkmark on photos that pass, warning on photos that don't.
- "Anti-fake mode" toggle promotes the threshold from 0.7 → 0.85.

### Phase 6 — Native exports

Tasks:
- Apple Shortcuts file builder: generates a `.shortcut` per user with prefilled bio/prompts. Imported into Hinge via clipboard.
- AirDrop bundle export.
- "GigaRizz" custom Photos album with auto-ordered photos.

### Phase 7 — Acquisition surfaces

Tasks:
- Public showcase backend (admin-curated database of opted-in before/after).
- iOS "Glow-Up Wall" view during onboarding.
- Friend Audit flow (separate from main onboarding, takes friend's uploads → diagnosis → install incentive).
- Match Story submission flow.

## Sprint Plan

**Sprint 1 (1 week, post-V2 launch)** — Match Outcome instrumentation + Lift Dashboard skeleton.

**Sprint 2 (2 weeks)** — Identity Match certificate + Anti-fake mode + showcase scaffolding.

**Sprint 3 (2 weeks)** — Concierge weekly re-audit job + push notifications + one-tap apply.

**Sprint 4 (3 weeks)** — Video pipeline (Hinge prompt video). High risk — provider choice may shift.

**Sprint 5 (2 weeks)** — Voice prompts (ElevenLabs integration + record/preview/export).

**Sprint 6 (3 weeks)** — Live Wingman keyboard extension. App Review will take 1-2 cycles; budget accordingly.

**Sprint 7 (1 week)** — Native exports (Shortcuts + AirDrop + Photos album).

**Sprint 8 (2 weeks)** — Acquisition surfaces (Glow-Up Wall, Friend Audit, Match Story).

Total: ~16 weeks from V2 launch to V3 full release. Several sprints can run in parallel once Sprint 1 is done.

## Risk & Mitigation

| Risk | Mitigation |
|------|-----------|
| Apple rejects keyboard extension for privacy. | Build screenshot-watcher fallback (Share Sheet). Both ship; whichever Apple allows wins. |
| Video provider quality is uneven. | Start with a single best-in-class provider (fal.ai Runway). Budget per-video cost in subscription pricing. |
| Voice cloning ethical/legal concerns. | Require explicit consent + only the user's own voice. Watermark generated audio if Apple requires it. |
| Match Outcome capture relies on user upload — many won't upload. | Push notifications + 1-week reminder + small in-app credit reward for uploading. |
| Concierge churn (user feels nagged). | One push per week, hard cap. Quiet weeks if no data changed. User can pause Concierge any time. |
| Lift claims attract App Store scrutiny. | Only claim lift when ≥30-day data exists. Use "users see avg 2.4× matches *based on their own reported data*" — qualified language. |
| Concierge $59.99 tier prices most users out. | Plus tier remains the volume product. Concierge is a 5% LTV unlock, not the volume play. |

## Metrics

V3 North Star (replaces V2's "time to diagnosis"):

> **Match Outcome Reporting Rate** — % of users who exported a kit who report a match outcome within 14 days.

Targets:
- 14-day report rate ≥ 35%.
- Of reporters, ≥ 60% show ≥ 1.5× match lift vs their pre-kit baseline.
- Concierge attach rate ≥ 8% of paid users by month 3.
- Live Wingman keyboard daily-active rate ≥ 40% of Pro users.
- Voice prompt generation per user per month ≥ 2 (it's the most viral surface).

## Positioning Update

V2 App Store subtitle: *AI Dating Photos That Get Matches*.
V3 App Store subtitle: *AI Profile + Coach. Verified Match Lift.*

Lead screenshot pivots from "before/after photo" to "before/after lift metric": *2.4× matches verified.*

## V3 One-Liner

> GigaRizz V3 is the only AI dating product that proves it worked, keeps your profile sharpened weekly, and stays in your corner from match to first date.

## Dependencies

V3 cannot start until V2 has:
1. Real provider keys installed (so Concierge has something to regenerate with).
2. App Store approval (so we have any users to instrument).
3. RevenueCat tiers expanded to include Concierge (will add ahead of launch so we can enable the SKU without an app update).
4. PostHog wired (so outcome instrumentation has a backbone).

## When V3 Is Done

When a paying GigaRizz Pro user can say: *"GigaRizz didn't just take my photos — it made my dating profile keep winning, week after week, and it told me exactly how much better it got."*

That is the line no competitor can match.
