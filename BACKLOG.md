# GigaRizz Backlog

> Last updated 2026-05-14.
> Items deferred out of V3 / V4 active scope so the team can focus on **the best dating photo generator on iOS**. Everything here is paused until the photo wedge is locked.
> Companion docs: `V3_PRODUCT_PLAN.md`, `V4_COMPETITOR_KILL_PLAN.md`, `PHOTO_EDITOR_RESEARCH.md`.

## Focus Reminder

V3 + V4 are now **photo-first**. The single test for any incoming feature: *Does this make GigaRizz the best dating photo generator on iOS, or does it pull attention away from that goal?* If the latter, it goes in this file.

The hero claim we are building toward: *Better than FaceApp. Better than Facetune. The only AI photo editor that passes Hinge Selfie Verification and Tinder Face Check.*

## Deferred — Non-photo V3 features

### Match Outcome Capture + Lift Dashboard
*Originally V3 Bet 1.* Capture screenshots of swipes/matches 7/14/30 days post-export, OCR the counts, compute lift. Returns to scope **after** photo features prove a Identity Match pass-rate ≥85% on real user uploads. Until then we can't claim outcomes truthfully.

### Concierge Weekly Re-Audit (subscription tier)
*Originally V3 Bet 2.* Sunday cron re-audits + push notification with one suggestion. The $59.99 Concierge tier remains in the pricing plan — we just don't build the weekly cron yet. Ships in V3.5 once Match Outcome Capture has 30 days of data. **Keep the tier on the paywall as a soft pre-sale (waitlist) so we learn willingness-to-pay.**

### Video Hinge Prompt Generation
*Originally V3 Bet 3.* Provider integration (fal.ai Runway / Pika), 10s record, AI rescript, voice clone. Big infra lift; the photo wedge ships first. Re-evaluate in 8 weeks.

### Voice Prompt Generation
*Originally V3 Bet 3.* ElevenLabs / OpenAI voice + script generator for Hinge voice prompts. Same reasoning as video.

### Live Wingman (iOS keyboard extension)
*Originally V3 Bet 4 / V4 Sprint 6.* Replies inline in Hinge/Tinder/Bumble keyboard. App Review risk + 2–3 cycle slippage. Photo wedge ships first.

### Practice Date voice rehearsal
*Originally V4 Sprint 4.* AI-persona voice rehearsal before first date. Needs voice infra (also blocked behind voice prompt).

### Date Logistics Helper
*Originally V4 Sprint 5.* Venue suggestions, "let's grab a drink" drafting. Needs Maps API + chat history per match.

### Conversation Memory per Match (encrypted local store)
*Originally V4 Smoothspeak / Wingman counter.* Core Data store + privacy receipts UI. Re-scope after the photo features have shipped + the Coach screen has been instrumented.

### Friend Audit referral mechanic
*Originally V3 Loop C.* Lower priority than App Store-search-driven acquisition for the photo wedge launch.

### Glow-Up Wall public showcase
*Originally V3 Loop A.* User-submitted before/after gallery. Needs CMS + opt-in + moderation. Ship the first cohort hand-curated in marketing assets; defer the in-app surface.

### Match Story submission
*Originally V3 Loop B.* User-generated success stories with $20 credit. Wait until outcome instrumentation exists.

### Public Anonymized Scoreboard
*Originally V4 Sprint 8.* "Top 10% in your city" benchmark. Needs aggregated dataset. Build after V3 Lift Dashboard.

### Real Photographer Marketplace fallback
*Originally V4 item #20.* Vetted local photographers as upsell. Marketplace ops + onboarding non-trivial. Defer until 10k+ paying users.

## Deferred — Non-photo V4 features

### A/B Bio Tester
Bio variant runner with match-volume tracking. Depends on Match Outcome instrumentation.

### Roast Mode audit voice
Prompt template swap. Trivial to ship but distracts from the trust position. Park it.

### Conversational AI editor (Facetune Skin 2.0 parity)
Already covered by existing photo tools + Glow Up Studio + Identity Match in V3. Revisit only if user reviews ask for "AI edit by chat."

### Multi-identity / Group Photo Generator (Nano Banana 2 5-identity)
The infrastructure exists in the catalog (`nano_banana_2`) but the UX/use-case design needs work. Defer to V4.x.

### Native Hinge/Tinder Shortcut export
Apple Shortcuts file builder + clipboard helpers. Small infra but big polish lift. Defer.

### Dating-app policy linter (deeper version of FaceCheck Pre-Flight)
Cite each platform's terms in-app. Light add once FaceCheck Pre-Flight has shipped + caught a few real failures.

## On hold / blocked on external action

### Apple Developer team enablement
Set `DEVELOPMENT_TEAM` and enable Sign in with Apple capability. Required for TestFlight + App Store submission.

### Firebase Auth provider enable (Console click)
Email/Password + Apple. One click per provider. Without this, sign-in fails on real devices.

### Real provider API keys
OpenAI, Replicate, fal.ai, AWS. Once installed, end-to-end generation can be validated.

### EC2 backend deploy
Instance currently stopped. Restart, allocate elastic IP, run `backend/deploy.sh`.

### Cloudflare Pages deploy
`web/` is ready. `npx wrangler login && npm run deploy` from a machine that can complete the OAuth browser handoff.

## Killed / not pursuing

### Gender swap
FaceApp ships it; we will not. Brand liability for a dating product.

### Aggressive face reshape (jawline / nose / lip plumping)
Facetune ships these; we will not. Documented as a Hinge Face Check failure cause.

### Smile-from-no-smile generation
FaceApp's "add smile" creates Cheshire-cat artifacts and fails FaceCheck likeness checks. We only do **smile enhance** (restore an existing partial smile), never **smile add**.

### Eye color change
Facetune ships it; FaceCheck flags it. Killed.

### AI Portraits / celebrity styles
FaceApp's viral surface. Too transformative for dating use. Killed.

## Notes

If an item moves out of backlog into a sprint, delete it from this file and add it to the live plan. Don't let this list rot; review every 4 weeks.
