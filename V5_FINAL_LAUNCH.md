# GigaRizz V5 — Final Launch Plan, Positioning & Roadmap

> Last updated 2026-06-13. This is the **final pre–App Store** plan. It supersedes the *sequencing* of V4 (V4 counters stay valid as competitive intel) and folds the photo-editor wedge (`PHOTO_EDITOR_RESEARCH.md`) into one shipping scope.
> Companion docs: `V4_COMPETITOR_KILL_PLAN.md`, `PHOTO_EDITOR_RESEARCH.md`, `COMPETITOR_RESEARCH.md`, `LAUNCH_CHECKLIST.md`.
> Operating principle for V5: **tighten, don't sprawl.** V2–V4 already shipped a deep feature surface (148 Swift files, 27-scene Brief Studio, audit, kit, identity-lock, FaceCheck). V5 is about *finishing, polishing, and merchandising* — not inventing ten more features.

---

## 1. The repositioning (what changed)

V2–V4 positioned GigaRizz as the *audit-first AI dating-profile studio*. That stays the **wedge**. V5 widens the **claim** to the category the user actually shops in:

> **GigaRizz is the AI photo studio that replaces FaceApp and Facetune for the people who actually need it — anyone who wants to look like their best *real* self in any photo, anywhere.** Dating is where we prove it (the only editor whose results pass Hinge Selfie Verification & Tinder Face Check), but the engine makes *any* photo of you better, in *any* environment, with *any* edit — without making you look like a different person.

Three audiences, one engine:
1. **Men on dating apps** (core wedge) — "look optimal, get matches, stay verifiable."
2. **Women on dating apps** — same engine, with makeup/glow/skin tuned female-first; the "natural, not catfish" promise is *more* valued here per `PHOTO_EDITOR_RESEARCH.md` §3.2.
3. **General photo users** (TAM expansion) — "the FaceApp/Facetune you don't have to feel weird about." Headshots, travel photos, putting yourself in places, fixing bad lighting.

### Why this is defensible
FaceApp/Facetune optimize for **virality and extreme transformation** (their defaults push past the identity line — `PHOTO_EDITOR_RESEARCH.md` §2.2, §3.2). The 2025–26 dating world made *that exact behavior* a liability: Tinder Face Check + Hinge Selfie Verification reject heavily-edited photos. GigaRizz's **identity-lock contract** (on-device IdentityMatch, FaceCheck Pre-Flight, drift detector, signed edit receipts) is the one thing FaceApp/Facetune *structurally will not build* because it caps the transformations they sell. We own "better **and** still you."

### One-liner (App Store subtitle candidates)
- "AI photos of the real you — anywhere."
- "Look your best. Still look like you."
- "The AI photo studio that passes Face Check."

---

## 2. What already exists (do NOT rebuild — merchandise it)

Inventory from the shipped V2–V4 code, mapped to the new claim:

| Capability (shipped) | FaceApp/Facetune analog | V5 action |
|---|---|---|
| Photo Brief Studio + 27-scene catalog + plain-English brief | "put yourself anywhere" | **Re-merchandise** as "Studio / Anywhere" — lift out of the dating-only framing |
| Face Refine Studio (smile, jaw, nose, lips, eyes, AI portrait) | Facetune reshape tools | Keep; gate behind naturalness slider (our differentiator) |
| Glow Up Chain V2 (CodeFormer restore, identity-gated steps + rollback) | Facetune Enhance / one-tap glow | Keep; this is our "Enhance" — better because it *can't* drift |
| Outfit Studio / Hairstyle / Age Studio / Pose Studio | FaceApp hair/beard, Facetune try-ons | Keep; "Pose Studio — any scene, locked face" is closest to env-swap |
| IdentityMatch + FaceDriftDetector + Age-Faithful Lock (on-device) | *nobody* | **The billboard.** Lead every screenshot with it |
| FaceCheck Pre-Flight (predict Hinge/Tinder pass) | *nobody* | **The billboard.** Trust beat |
| Signed Identity Match Certificate + EXIF receipt round-trip | *nobody* | Trust/PR proof point |
| Reference Selfie Vault + Quality Coach | re-ask every time | Onboarding moat |
| Audit → Diagnosis → Profile Kit → Export (Hinge/Tinder/Bumble) | *nobody* combines all three | Dating wedge hero artifact |
| Screenshot Coach, Rizz Coach, Bio/Openers | RIZZ et al. | Keep; dating retention |
| Emberling companion (XP ranks, moods) | — | **Decision needed** (see §5) |

**Conclusion:** the engine for "create photos of yourself in different environments / replace yourself in an environment you choose" is ~80% built. V5's net-new build is small and surgical (§4).

---

## 3. Final launch scope — the cut line

Ship v1.0 with a **tight, fully-polished** surface. Everything flag-gated already; V5 decides the default-ON set.

### TIER A — must be flawless at launch (the demo path)
1. **Onboarding → Reference Vault set → first result in < 2 min.**
2. **Studio (Anywhere)** — preset scenes + plain-English brief, identity-locked, 4 variants, drift chip per variant.
3. **Glow Up (Enhance)** — one-tap, identity-gated, before/after slider.
4. **FaceCheck Pre-Flight** — the trust moment before export.
5. **Profile Kit export** (Hinge/Tinder/Bumble) — the dating payoff.
6. **Paywall + restore + account delete** — store-compliant, no weekly sub, cancel-in-app.

### TIER B — on by default, polished but not headline
Face Refine Studio, Outfit/Hairstyle/Age/Pose Studio, Screenshot Coach, Photo Sequence Optimizer, Roast Mode, Variant Compare + bulk save.

### TIER C — flag OFF for launch (revisit post-launch; in `BACKLOG.md`)
Keyboard extension, Practice Date / voice, Date Logistics, Match-outcome lift dashboard (needs real data), Photographer Marketplace, public scoreboard.

### Anti-goals (do not ship, brand liability)
Gender swap, extreme age shift, celebrity-style transforms, anything that defaults past the identity line.

---

## 4. The net-new "FaceApp/Facetune killer" features (V5 build)

These are the *only* substantial new builds. Each is chosen because it's differentiated AND not already covered.

### 4.1 Magic Studio — compound natural-language edits ("complex operations") ⭐ flagship
**Gap:** FaceApp/Facetune are single-op, manual, one-slider-at-a-time. The user asked for "complex operations." Let the user type one request — *"put me on a rooftop at golden hour, change my hoodie to a white linen shirt, fix the harsh lighting, remove the person behind me"* — and the engine plans + executes the steps as one identity-locked chain, showing each step with a drift score (reusing the Glow Up Chain coordinator + per-step rollback).
**Why we win:** compound editing + identity lock + per-step transparency. Facetune can't chain without exposing drift; FaceApp has no plan/step model at all.
**Reuse:** GlowUpChainCoordinator (chaining + rollback), Brief Studio (scene), backend `_wrap_natural`, IdentityMatch. Net-new = an intent → step-plan parser + the compound-request UI.

### 4.2 "Drop me into this photo" — user-supplied target scene
**Gap:** Brief Studio uses *our* 27 presets. The user explicitly wants to "replace themselves in an environment they choose." Let the user pick **any** photo as the target environment (a bar they like, a beach, a friend's travel pic) and composite the identity-locked subject into it.
**Why we win:** unbounded environments vs a fixed preset library (beats ReGen too). Plus a "plausibility" check — flag environments the user has demonstrably never been (honesty layer FaceApp won't ship).
**Reuse:** PhotoUploadService (second image), generation pipeline (img+ref), IdentityMatch.

### 4.3 Studio home — first-class general photo entry point
**Gap:** today the Photos tab reads as a *dating-kit appendage* ("No photos in your kit yet"). For the FaceApp/Facetune audience, the photo studio must stand alone.
**Build:** a clean Studio landing — "Improve any photo" / "Put yourself anywhere" / "Magic edit" — that does NOT require starting the dating audit. Dating kit becomes one destination *from* the studio, not the gate *to* it.

### 4.4 Women-first tuning pass
**Gap:** copy/defaults skew male. Add a gender-aware naturalness profile (makeup/glow/skin defaults) and female-first scene/scenario presets, surfaced from onboarding. Engine unchanged; presets + copy + default sliders only.

> Everything else competitors do is already matched by shipped V2–V4 surfaces (§2). Resist adding more.

---

## 5. Open product decisions (resolve early in the loop)

1. **Emberling companion** — does the Tamagotchi-style XP/mascot strengthen retention or dilute the premium "pro photo studio" positioning? *Recommendation:* keep but make it opt-in / secondary, never on the primary studio path. Re-evaluate with TestFlight.
2. **Naturalness default band** — confirm default is the middle band (passes FaceCheck) for all new users.
3. **Pricing** — lock the no-weekly-sub ladder (Plus monthly/annual, Gold annual, consumable credits) per `V4_COMPETITOR_KILL_PLAN.md` pricing posture before App Store IAP setup.

---

## 6. Launch readiness — the blocking checklist (owned, not aspirational)

From `LAUNCH_CHECKLIST.md`, the true blockers (most are external setup the *user* must do — see that doc §0–4). V5 engineering keeps the build green and the demo path flawless; these gate submission:

- [ ] Firebase Auth providers enabled (Apple + Email) — **user action**
- [ ] Real provider keys in prod `.env` (OpenAI/Replicate/fal/AWS) — **user action**
- [ ] EC2 backend live at `api.gigarizz.app` + SSL + DNS — **user action**
- [ ] Privacy/Terms pages deployed (Cloudflare) — **user action**
- [ ] RevenueCat products + entitlements wired — **user action**
- [ ] App Store Connect: metadata, screenshots, IAP, review notes (`PAYWALL_MODE=none` for review) — **user action**
- [ ] Account deletion + source-image 30-day deletion job verified — **engineering**
- [ ] AI-content disclosure on every result + C2PA/EXIF marker — **engineering**
- [ ] Real screenshots captured from the polished demo path — **engineering (simulator loop)**

---

## 7. Execution loop (how V5 actually ships)

Run as a tight loop, each iteration verified in the simulator (design must be *aesthetic as fuck* before it counts as done):

**Loop step = { pick highest-leverage item → implement → build → run in simulator → screenshot → judge aesthetics → fix or accept → commit }.**

Ordered backlog for the loop:
1. ✅ Simulator design-verification harness (DEBUG auth bypass + tap/scroll/screenshot tooling).
2. ✅ Fix faded CTA gradient (systemic flame→beige → saturated flame CTA).
3. ✅ Studio home first-class entry (Magic Studio hero on Photos tab).
4. ✅ Magic Studio compound-edit flow (§4.1) — flagship. Planner + view + 6 passing unit tests, verified in sim.
5. ✅ "Drop me into this photo" (§4.2) — `SceneSwapView`, two-photo flow, verified in sim.
6. Women-first tuning pass (§4.4).  ← next
7. Full design-polish sweep of Tier-A path (spacing, type scale, empty states, loading/skeletons, haptics, dark-mode contrast).
8. AI-content disclosure on result surfaces + account/data deletion verification.
9. Capture App Store screenshots from the polished path.

Each loop iteration updates this file's checkboxes and the task list. Competitive claims trace back to `V4_COMPETITOR_KILL_PLAN.md`; trust claims to `PHOTO_EDITOR_RESEARCH.md`.

## 8. What "winning V5 / launch" looks like
- Demo path (onboard → Studio → Glow Up → FaceCheck → export) is flawless and beautiful on a real device.
- A general user with zero dating intent can open the app, fix/transform a photo, and feel it beat FaceApp/Facetune — without a catfish result.
- Identity-lock / FaceCheck is the first thing a reviewer and a user notice.
- App Store rating ≥ 4.7★; "doesn't look like me" < 2% of 1-stars; no weekly-sub billing complaints.
</content>
