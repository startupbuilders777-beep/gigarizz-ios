# GigaRizz V4 — Competitor Kill Plan

> Last updated 2026-05-14.
> Companion docs: `COMPETITOR_RESEARCH.md`, `PHOTO_EDITOR_RESEARCH.md` (FaceApp/Facetune), `V3_PRODUCT_PLAN.md`, `V2_PRODUCT_PLAN.md`, `BACKLOG.md`.

---

## V4 RESEQUENCE — PHOTO-FIRST (2026-05-14)

V4 also re-prioritizes around the photo wedge. Every counter that is not a photo feature is paused until V3 photo sprints 1–3 ship. The non-photo counters stay on the roadmap but appear in `BACKLOG.md`.

### What shipped on 2026-05-14 (V4 counters active in code)

- **Naturalness intensity slider** (counters Aragon, Sway, YourMove, PhotoAI) — three bands plus on-device drift threshold. Backend wrapper varies prompt strength per band.
- **IdentityMatchService** (counters every "doesn't look like me" complaint across the segment) — on-device face similarity, no data leaves the phone. Foundation for FaceCheck Pre-Flight + Identity Match Certificate.
- **Glow Up Studio** (counters Facetune's freeform palette + FaceApp's preset filters) — audit-driven, only shows fixes that help *this* specific photo.

### Sprint 1 photo counters (next 2 weeks)

- **FaceCheck Pre-Flight** — predict Hinge/Tinder verification pass before upload. **Structural counter to FaceApp + Facetune in the dating context** (see `PHOTO_EDITOR_RESEARCH.md`).
- **"Why this photo" rationale on every audit + generation result** — counters RIZZ's templated outputs and Aragon's silent grid.
- **Comparison landing page** (`facetune-vs-gigarizz`, `faceapp-vs-gigarizz`, `rizz-vs-gigarizz`) — copy ready.

### Sprint 2 photo counters

- **Identity Match Certificate** — signed JSON edit receipt per export. Counters FaceApp/Facetune opacity.
- **Age-Faithful Lock** — fails any generation that drifts the apparent age >5 years from the user's reference. Direct Sway AI counter.

---

## Frame

V2 made GigaRizz the only full-stack audit-first AI dating profile studio. V3 was about getting paid monthly through outcome instrumentation and concierge. **V4 is reactive: take every competitor's single best card and beat it on their turf, then take their air.**

The competitive map (from `COMPETITOR_RESEARCH.md`) splits into three threats:

1. **RIZZ + WingAI + Plug AI + Smoothspeak + CupidAI** — text/reply coach kings.
2. **ReGen + Aragon + PhotoAI + Sway AI + DatingImagePro** — photo generators.
3. **Tinder Photo Selector + Bumble AI + Hinge AI** — native, free, distribution-rich.

Nobody combines all three. GigaRizz already does. V4 makes the combination *uncatchable*.

## The 8 Competitors That Matter

For each: their best card, our counter, infrastructure cost, target ship sprint.

### 1) RIZZ (TREND IT LLC) — `id1663430725`

**Their best card:** 37,000 ratings at 4.8★. Owns the search word "rizz." Templated GPT replies to screenshots, low friction.

**Their weakness:** No photos. No audit. Reviews complain about generic templated replies. No reasoning behind suggestions. Brand maturity = brand staleness.

**Our counter — three moves, simultaneous:**

- **Move A: "Why this works" reply rationale.** Every screenshot reply we generate ships with a one-line rationale: *"References her dog (specific) + invites a yes/no answer (low effort to reply)."* This makes GigaRizz feel like coaching, not autocomplete. RIZZ users routinely complain that suggestions feel canned; rationale is the cure.
- **Move B: Reply + photo in one funnel.** When a user pastes a Hinge screenshot, GigaRizz returns a reply *and* notices "your fifth photo is hurting you on Hinge — want to regenerate?" Cross-sell their *only* product into ours.
- **Move C: ASO knife fight.** Bid hard on "rizz" + "rizz app" + "rizz ai" keywords. Run a comparison landing page (`rizz vs gigarizz`) that wins on screenshot-coach + audit + kit.

**Infra cost:** Move A is a prompt template change. Move B is wiring screenshot OCR results into the audit pipeline. Move C is marketing.

**Target sprint:** V4 Sprint 1 (week 1–2).

---

### 2) CupidAI (UMagnet) — `id6502325545`

**Their best card:** Most ambitious feature surface. Real-time AirPods coaching during dates. GQ Studio combines photos with the rest of the funnel. Tier ladder up to $279.99/yr.

**Their weakness:** Confusing tier wall. Tiny review base. AirPods-during-a-real-date is genuinely creepy and a liability landmine. Photo feature inherits the segment-wide "doesn't look like me" complaint.

**Our counter:**

- **Practice Date instead of Live Date.** Voice-mode rehearsal with an AI persona built from the *matched person's* profile. Plays out a hypothetical first-date conversation so the user is sharp before they show up — without an AirPod whispering in their ear during the actual date. Equally useful, no consent ambiguity, App Store-safer.
- **One-page tier ladder.** Free → Plus ($14.99) → Pro ($29.99) → Concierge ($59.99). No weekly framing. No hidden upsells. Beats CupidAI's confusion-as-pricing.
- **Naturalness as a hard contract.** Every GigaRizz-generated photo includes an Identity Match score (V3 Bet 5). CupidAI's GQ Studio has no such gating. Make "Identity Match: PASSED" a visible badge on each export.

**Infra cost:** Practice Date needs voice (Whisper STT + a TTS that can do brisk back-and-forth). Tier copy is a writing task. Identity Match is on the V3 roadmap.

**Target sprint:** Sprint 4–5 (overlap with V3 voice infra).

---

### 3) Sway AI — `id6502842382`

**Their best card:** 5,300 ratings, full stack (profile feedback + photo + chat), strong dating positioning. Closest direct functional match to GigaRizz.

**Their weakness:** Reviews flag photos as "cartoonish, deep wrinkles, older than actual age." Profile scan is a paid add-on creating friction. No platform-specific kit packaging.

**Our counter:**

- **Anti-Aging Lock.** Their #1 complaint is "older than actual age." Add an "age-faithful" check to the identity drift detector that flags any generated photo where estimated age differs from the user's stated age by ≥5 years. Show a "Failed age check" badge and silently re-roll.
- **Audit included free, every time.** Sway gates the profile scan. GigaRizz V2 already includes it in the free tier — make that a billboard. *"Free profile diagnosis, no card needed."*
- **Platform-Specific Kit as the export.** Sway gives users a pile of photos. GigaRizz gives a Hinge Pack / Tinder Pack / Bumble Pack — six photos in correct aspect ratio, ordered, plus a platform-appropriate bio, plus three prompt answers (Hinge), plus a sticky opener arsenal.

**Infra cost:** Age estimator (Vision framework `VNDetectFaceCaptureQualityRequest` plus a simple age inference) — small. Audit-free is already shipped. Kits are partly shipped in V2.

**Target sprint:** Sprint 2.

---

### 4) ReGen AI Profile Photos — `id6757136097`

**Their best card:** Aggressive annual at $24.99. Hybrid sub + consumable pricing. Hyper-realistic "looks like you" framing.

**Their weakness:** Tiny review base. Photo-only. No audit, no bio, no openers, no platform export. Pre-canned poses and environments.

**Our counter:**

- **Conversational Photo Brief.** Skip preset packs entirely. Let users type a brief in plain English: *"Coffee shop, Brooklyn, golden hour, gray hoodie, looking off camera."* Engine returns four variations, drift-checked. Beats ReGen's preset library on creative range and beats Aragon on naturalness.
- **Annual price match at $29.99.** Plus annual undercuts CupidAI ($69.99 Pro yearly), matches ReGen's annual within $5, and includes audit + kit + coach. Make the comparison loud.
- **"Generation Receipt."** Every export shows what was generated, when, and at what naturalness threshold. Builds trust ReGen's smaller brand can't match on launch.

**Infra cost:** Conversational brief is prompt engineering plus a small UI. Pricing is positioning. Receipts are JSON serialization + a UI panel.

**Target sprint:** Sprint 3.

---

### 5) Aragon AI — `id6673918806`

**Their best card:** Volume (100+ images per pack). Polished editing toolkit (background changer, blemish remover, magic eraser, upscaler). Cross-platform reach including Vision Pro.

**Their weakness:** Corporate DNA. Independent tests rate dating fit only 6.5/10. Only 3–5 usable photos per 100 in dating tests. Face drift. Premium-priced for outputs many users find unusable.

**Our counter:**

- **Quality over quantity claim.** *"We generate 12 photos. 11 of them are usable."* Lead with the failure rate (a fact Aragon won't put in marketing). Track usable-rate per user as a KPI in V3 Match Outcome instrumentation and surface it.
- **Drift Detector visible in the result grid.** Tag each photo with its identity match score. Hide or strike through any photo below the threshold. Users instantly see "this AI doesn't lie to me about whether the photo is acceptable" — Aragon's tests show users sifting through 95 bad photos to find 5.
- **Built-in editor for the user's *existing* photos.** Counter Aragon's editing toolkit with the *same toolkit applied to the photos the user already loves* — face enhance, background swap, hairstyle try-on, outfit swap. We already ship these in V2. Re-merchandise them as "Polish what you have" inside the Upgrade tab.

**Infra cost:** Tagging the grid is a UI change. Quality-over-quantity is positioning. The editor surfaces already exist (V2 Photo Actions).

**Target sprint:** Sprint 2 (merch + UI), Sprint 3 (drift visibility).

---

### 6) Tinder Photo Selector / Bumble AI Photo Feedback / Hinge Convo Starters

**Their best card:** Free, native, on-device, trained on the platform's own outcome data. Distribution = every user of that app.

**Their structural weakness:** Each is locked to its own platform. None *generates*. Hinge explicitly refuses to give copy/paste replies. Bumble nudges, doesn't replace. Tinder picks from your camera roll but won't tell you why.

**Our counter:**

- **Triple-Platform Kit.** We ship a single Profile Kit that works on all three apps. Match Group will never optimize you for their competitors. GigaRizz can. Make this the cover-of-the-App-Store-listing screenshot: *"Built for Hinge, Tinder, and Bumble — in one tap."*
- **"Why this photo" overlay.** Counter Tinder Photo Selector's silent picking. For every photo we recommend (or de-recommend), surface a one-line reason in the user's plain language. *"Hinge favors clear eye contact in the first slot — this one wins."*
- **One-tap export → live profile.** Apple Shortcuts + clipboard + photo album drops every kit one tap away from being live on each app. Native AI can't beat this because they can't optimize for the other app.
- **FaceCheck Compliance Pre-Check.** Tinder rolled out FaceCheck in 2025; Hinge added Selfie Verification. Any AI photo too edited fails verification. GigaRizz runs the user's reference selfie against each generated photo to predict pass/fail *before* the user uploads. **Native AI won't ship this because it would expose how often their own selection picks unverifiable photos.** This is a unique trust beat.

**Infra cost:** Kit packaging is V2. Reasons are a prompt addition. FaceCheck pre-check uses the same identity match infra as V3 Bet 5. Shortcuts file is small Swift work.

**Target sprint:** Sprint 1 (kit narrative + reasons), Sprint 3 (FaceCheck), Sprint 6 (Shortcuts export).

---

### 7) Smoothspeak — `id6739810324`

**Their best card:** System keyboard usable in any app. Coach with reasoning ("Cue"). Conversation memory per match. Stanford/Google AI pedigree in marketing.

**Their weakness:** No photo generation. Keyboard permissions friction. Coach can feel verbose.

**Our counter:**

- **GigaRizz Live Wingman keyboard (V3 Bet 4).** Same UX win as Smoothspeak's keyboard, but with photo regeneration shortcuts and audit nudges baked in. *Inside Hinge, you can re-rank your photo set without leaving the keyboard.*
- **Conversation Memory tied to Match Outcomes.** Smoothspeak remembers what you talked about. GigaRizz remembers what you talked about *and* whether your kit produced a date. The data flywheel they can't match.
- **Concise mode by default.** Smoothspeak's verbose coach is a known complaint. GigaRizz defaults to one-line suggestions with an optional "explain" expansion.

**Infra cost:** Keyboard extension is V3 Sprint 6 (high effort). Memory + outcome linkage uses V3 outcome data + per-match notes.

**Target sprint:** Sprint 6.

---

### 8) Wingman: AI Dating Coach — `id6581480971`

**Their best card:** Persistent per-match memory (attachment style, red flags, history). "Rate My Photo" + "Compare Photos" + "Fix My Bio" + "Check My Vibe" — a coherent toolbox.

**Their weakness:** No photo generation. Lower review base. Memory feature can feel surveillance-heavy without strong privacy framing.

**Our counter:**

- **Memory with a Privacy Receipt.** Match memory exists, but the user sees exactly what is stored, can delete per-match notes anytime, and the data never leaves their device (CoreML embedding). Smoothspeak's keyboard + Wingman's memory, with privacy receipts shown by default in the Coach tab.
- **Rate + Generate in one flow.** Wingman rates the photo; GigaRizz rates and *fixes*. Same gesture, more output.
- **Vibe Check ↔ Naturalness.** Wingman has "Check My Vibe." We have an Identity Match score *plus* an Outfit Authenticity score *plus* a "this background isn't a place you've been" warning. The same metaphor, more rigorous content.

**Infra cost:** On-device memory needs Core Data + an encrypted store. Privacy receipts are UI. Other items leverage V3 identity match.

**Target sprint:** Sprint 5–7.

---

## Surgical Feature Counter-List

Drawn from the V4 Spike List in `COMPETITOR_RESEARCH.md`. Each line cites the competitor and the GigaRizz-only differentiator.

| # | Feature | Counters | New infra? | Sprint |
|---|---------|----------|-----------|--------|
| 1 | Profile Audit with named reasoning | Photofeeler, Wingman, Bumble | No | 1 |
| 2 | Naturalness slider + Identity drift detector | Aragon, Sway, YourMove, PhotoAI | Face embedding compare | 2 |
| 3 | Per-platform Profile Kit (Hinge/Tinder/Bumble) | Every competitor | No | 1 |
| 4 | Screenshot reply coach with "why this works" rationale | RIZZ, WingAI, Plug AI, Smoothspeak | No | 1 |
| 5 | Photo Sequence Optimizer (lineup ranking) | Tinder Photo Selector, Picker AI | No | 2 |
| 6 | Live Profile Replicator (paste current Hinge URL → rebuild plan) | Hinge AI, Roast.dating | OCR + vision (have) | 3 |
| 7 | "Roast Mode" audit toggle | Roast.dating | Prompt only | 1 |
| 8 | Voice Prompt Recorder + coach for Hinge | Hinge native (unmonetized) | Whisper + eval | 4 |
| 9 | Date Logistics Helper (opener → date locked) | CupidAI Wingman, Wingman: AI Coach | Maps API | 5 |
| 10 | One-Tap Native Export (Shortcuts + clipboard + album) | Every competitor | iOS Shortcuts | 6 |
| 11 | Conversational Photo Brief (plain-English prompts) | PhotoAI, Aragon | No | 3 |
| 12 | Match Insurance Re-Audit (V3 outcome loop) | Sway AI Profile Scan | V3 Sprint 1 | V3 done |
| 13 | Privacy-First Local Mode | Picker AI, Tinder Selector, all server competitors | CoreML face embedding | 7 |
| 14 | FaceCheck/Selfie Verification Compliance pre-check | Nobody | Identity match (V3) | 3 |
| 15 | Practice Date voice rehearsal | Flines AI Girlfriend, CupidAI Wingman | Voice infra | 4 |
| 16 | Public anonymized scoreboard ("top 10% in your city") | Photofeeler | Aggregated dataset | 8 |
| 17 | Bio A/B test with match-volume tracking | Nobody | Scheduling + outcome | V3 done |
| 18 | Group Photo Surgery (extract solo from group shot) | Picker AI, Tinder Selector | Detection + segmentation | 5 |
| 19 | "Stop the auto-renew" trust pricing | Plug AI, Flines AI, YourMove | None — brand | 1 |
| 20 | Real Photographer Marketplace fallback | ROAST $97 expert tier | Marketplace ops | 7+ |

## Pricing Counter-Move

Competitor weekly subs ($3.99–$9.99) drive the majority of billing complaints in the segment. Multiple competitors (Plug AI, YourMove) have a Google Play 2.6★ rating despite a 4.5★ iOS rating — the gap is overwhelmingly cancellation friction.

**V4 pricing posture:**
- **No weekly subs.** Monthly + Annual + one-time consumable credit packs.
- **Default to consumable credits.** Subscription is opt-in inside the app, not the default paywall path.
- **One-tap unsubscribe surfaced in Settings tab.** Not buried in Apple's subscription manager.
- **Refund-on-request for unused generations.** Reviewed within 24 hours.
- **Trust badge:** "No weekly autorenew. Cancel inside the app."

This is a marketing-only feature with zero infra cost. It is the single most defensible competitive moat in the category because every weekly-sub competitor has structural reasons not to copy it.

## Acquisition Counter-Moves

### A. "RIZZ vs GigaRizz" comparison page

ASO + paid search. Direct comparison landing page (own domain). Shipped pre-launch.

### B. Reverse-review feed

Pull worst-rated 1-star reviews from Aragon, Sway, YourMove (public on App Store) and write a one-liner per common complaint: *"Looks fake? Identity drift detector. Cancellation hell? Cancel inside the app. Photos too old? Age faithful check."* Surface in onboarding as "Why GigaRizz."

### C. Native-AI distancing

Position GigaRizz as the **multi-platform** alternative to Hinge/Tinder/Bumble's native AI. Headline: *"Hinge's AI works on Hinge. Tinder's AI works on Tinder. GigaRizz works on every app you swipe on."*

### D. ASO keyword raid

Target keywords no competitor owns:
- "ai dating profile audit"
- "looks like me ai photos"
- "ai dating coach reply why"
- "hinge tinder bumble photos"
- "facecheck pass ai"
- "voice prompt hinge"

## Execution Sequence

V4 is **8 sprints over ~14 weeks** post-V3 Sprint 1. Each sprint targets one or two of the eight competitors above. Multiple sprints run in parallel once infra is in place.

| Sprint | Counters shipped | Competitors covered |
|--------|------------------|---------------------|
| 1 | Rationale on replies, per-platform kit narrative, "Roast Mode," trust pricing posture, comparison landing page | RIZZ, Tinder/Bumble/Hinge native, segment-wide |
| 2 | Identity drift detector, age-faithful check, photo sequence optimizer, anti-aging lock | Sway AI, Aragon, ReGen |
| 3 | Conversational photo brief, generation receipts, FaceCheck pre-check, Live Profile Replicator | ReGen, PhotoAI, native AI |
| 4 | Voice prompt recorder + coach, Practice Date rehearsal | Hinge voice prompts, CupidAI Wingman, Flines AI |
| 5 | Date Logistics Helper, Group Photo Surgery | CupidAI, Wingman, Picker AI |
| 6 | Live Wingman keyboard extension, One-tap native export | Smoothspeak, Keys AI, every export-weak competitor |
| 7 | Privacy-First Local Mode, Photographer Marketplace fallback | Picker AI, Tinder Selector, ROAST |
| 8 | Public Anonymized Scoreboard, full ASO + comparison-page push | Photofeeler, RIZZ search-intent |

## Risk & Reality Check

| Risk | Reality |
|------|---------|
| Many of these features overlap V3. | Intentional. V4 is a *narrative* layer on top of V3. The features that already exist in V3 get re-merchandised in V4 for competitor-specific marketing copy. |
| 20 features ≠ feasible in one cycle. | Prioritize sprints 1–3 (the easy wins). Sprints 6–8 are stretches; if they slip the brand wins are still locked. |
| Native platform AI keeps eating features. | The triple-platform kit + cross-app coaching is structurally unreachable for native AI — they have business reasons not to optimize the user for competitors. We are safe there indefinitely. |
| Identity Match / FaceCheck pre-check might be wrong. | Show the user the threshold. Let them override. Don't claim 100% accuracy; claim "predicted to pass at 92%+." |
| Voice-rehearsal feature could feel awkward. | Frame as "practice with a coach," not "practice with your match." Use a generic AI persona by default; offer match-profile-derived persona only as an explicit user opt-in. |

## What "Winning V4" Looks Like

By end of V4:

- GigaRizz outranks RIZZ on at least one of: "ai dating profile," "dating photos ai," "ai dating coach reply."
- App Store rating ≥ 4.7★ on ≥ 2,000 ratings.
- Concierge attach rate ≥ 8% of paying users (carryover from V3).
- "Doesn't look like me" appears in <2% of 1-star reviews (vs Aragon/Sway baselines of ~25%).
- Verified average match lift surfaced in App Store screenshots (from V3 outcome data).
- One Match Group product manager retweets a GigaRizz feature with grudging respect.

The last bullet is unserious but useful as a vibe check. If their PMs notice, we're winning.

## V4 One-Liner

> GigaRizz V4 is the only AI dating product that beats RIZZ on coaching, beats Aragon on naturalness, beats Hinge on voice prompts, beats Tinder Photo Selector on transparency, and beats every billing-complaint competitor on trust — at once, in one app.
