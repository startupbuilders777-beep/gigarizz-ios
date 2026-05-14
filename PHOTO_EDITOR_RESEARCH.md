# Photo Editor Competitor Research: FaceApp & Facetune vs GigaRizz

> Last updated 2026-05-14.
> Companion docs: `COMPETITOR_RESEARCH.md`, `V2_PRODUCT_PLAN.md`, `V3_PRODUCT_PLAN.md`, `V4_COMPETITOR_KILL_PLAN.md`.
> Scope: facial improvement / face editing / skin / portrait retouch only. Not body, not video, not general selfie editing.
> Frame: GigaRizz is an audit-first AI dating profile app. The competitive surface is "make this dating profile photo look like the user's best self while staying recognizably them." Our brand contract is **Keep me looking like me.**

---

## 1. Why this research matters now

Dating apps cracked down on photo authenticity in 2025–2026. Tinder's Face Check rolled out nationwide in the US, and Match Group reported that interactions with "bad actors" fell more than 50% where Face Check is live ([Identity Week](https://identityweek.net/tinder-expands-facial-verification-across-the-u-s-raising-the-bar-for-dating-app-safety/), [Scripps News](https://www.scrippsnews.com/business/company-news/safe-swiping-tinder-launches-nationwide-facial-verification-to-fight-catfishing)). Hinge made Face Check mandatory in the UK and Australia, with the rest of the world following ([ID Tech](https://idtechwire.com/hinge-makes-face-check-mandatory-as-uk-and-australia-age-verification-rules-drive-dating-app-biometrics/), [Hinge Help](https://help.hinge.co/hc/en-us/articles/45715796564243-Face-Check-Scan)). Hinge's own help docs explicitly warn that "heavily edited photos" can cause Selfie Verification to fail ([Hinge Help](https://help.hinge.co/hc/en-us/articles/10303221435539-What-is-Selfie-Verification)).

In other words, *the dating photo category is structurally hostile to the kind of editing FaceApp and Facetune sell as a feature.* This is the wedge for GigaRizz.

Meanwhile, FaceApp and Facetune still dominate App Store charts and mindshare. They define the user's mental model of "AI photo editor." We do not need to outgun them as general selfie editors. We need to be the only editor a dating-app user trusts to put a photo into a profile that will pass Face Check.

This document is the playbook for that.

---

## 2. FaceApp — feature-by-feature deep dive

### 2.1 Feature catalog

FaceApp markets more than 60 "photorealistic filters" centered on viral transformations ([FaceApp.com](https://www.faceapp.com/), [AI Chat Daily](https://www.aichatdaily.com/tools/faceapp)). The feature areas that matter for the dating-photo wedge:

| Feature | What it does | Free / Pro | GigaRizz relevance |
|---|---|---|---|
| Smile enhance / add smile | Adds basic, wide, tight, or "upset" smile to a closed-mouth face | Basic free; variants Pro | High — expression quality is a top audit issue |
| Age (younger / older / classic) | Ages the face up or down by 10–30 years | Pro for most variants | Negative — for dating we want age-faithful, not age-shifted |
| Gender swap | Predicts opposite-gender face | Free | Out of scope; can be a brand liability |
| Hair color / style swap | Switches base color, tries different cuts (length, style, volume) | Black free; rest Pro | Medium — useful for "is this haircut working" |
| Beard / facial hair | Adds or removes stubble, full beards, mustaches | Pro | Medium — same as hair |
| Makeup | "Hollywood," "Glamour," "Soft Glam" style packs | Pro | Low for men; medium for women |
| Background swap | Replaces background; recently split into separate face+background editing for "better balance, depth, focus" ([AI Chat Daily](https://www.aichatdaily.com/tools/faceapp)) | Pro | High — dating profiles regularly fail on background |
| Skin retouch | Smoothing, glow, blemish removal, wrinkle reduction | Mixed | Critical — dating photo quality issue #1 |
| AI portraits / styles | Celebrity styles, era styles, viral one-tap looks | Pro | Low — these are too transformative for our trust contract |
| Photo enhancement | One-tap lighting / color / sharpness upgrade | Mixed | Critical — every dating photo benefits |
| Impressions | Pre-defined "looks" combining several edits | Pro | Low — opaque, hard to audit |
| Lens blur / vignettes / overlays | Cosmetic post-processing | Pro | Low |

### 2.2 Default aggression — do they keep identity?

FaceApp's defaults are tuned for *virality*, not realism. Reviews and tests consistently flag:

- "Most effects feel unrealistic and look fake" ([JustUseApp reviews](https://justuseapp.com/en/app/1180884341/faceapp-ai-face-editor/reviews))
- Cheshire-cat smile artifacts on the smile filter ([JustUseApp reviews](https://justuseapp.com/en/app/1180884341/faceapp-ai-face-editor/reviews))
- Gender-swap errors when hair is non-conventional ([Common Sense Media](https://www.commonsensemedia.org/app-reviews/faceapp-ai-face-editor))
- Inconsistent retouch — "what some considered flawless, others saw as overly airbrushed" ([Common Sense Media](https://www.commonsensemedia.org/app-reviews/faceapp-ai-face-editor))

Identity preservation is not a stated product principle. The brand promise is closer to "see yourself different," and the defaults push toward exaggerated, sharable results. This is the opposite of what a dating-profile user needs.

### 2.3 Pricing & conversion mechanics

- **Pro Annual**: $19.99 / year, all filters unlocked, no ads, no watermark, priority processing ([FaceApp FAQ](https://www.faceapp.com/faq/how-much-does-faceapp-cost/), [Alternatives.co pricing](https://alternatives.co/software/faceapp/pricing/))
- **Pro Lifetime**: $79.99 one-time ([Alternatives.co](https://alternatives.co/software/faceapp/pricing/))
- Annual is positioned as the default tier (under $2/month effective) and is the dominant conversion path
- Free trial converts automatically, and 2026 user reviews repeatedly call this out — "free trial converted without approval, $31 charged" ([JustUseApp reviews](https://justuseapp.com/en/app/1180884341/faceapp-ai-face-editor/reviews))

### 2.4 Known user complaints

From [Trustpilot](https://www.trustpilot.com/review/faceapp.com), [PissedConsumer](https://faceapp.pissedconsumer.com/review.html), [JustUseApp](https://justuseapp.com/en/app/1180884341/faceapp-ai-face-editor/reviews), and [SecurityBrief](https://securitybrief.asia/story/faceapp-pro-version-scams-privacy-concerns):

1. **Billing / cancellation friction.** Dominant complaint. Auto-renew after trial, repeat charges, hard cancellation.
2. **Results look fake or airbrushed.** Particularly the smile and age filters.
3. **Privacy concerns.** FaceApp uploads photos to AWS / GCP and the ToS gives the company an in-perpetuity license over the image ([TechCrunch](https://techcrunch.com/2019/07/17/faceapp-responds-to-privacy-concerns/), [PBS](https://www.pbs.org/newshour/science/is-faceapp-a-security-risk-3-privacy-concerns-you-should-take-seriously), [FaceApp Privacy Policy](https://www.faceapp.com/en/privacy/)). Photos cached 24–48h on cloud.
4. **Feature regressions.** Face swap was removed, drawing 1-star reviews ([JustUseApp](https://justuseapp.com/en/app/1180884341/faceapp-ai-face-editor/reviews)).
5. **Bias.** Age filters criticized for racial and gender stereotypes ([Common Sense Media](https://www.commonsensemedia.org/app-reviews/faceapp-ai-face-editor)).

### 2.5 Technical — what we can verify

FaceApp's pipeline is widely understood (from technical write-ups, not leaked source) to use Generative Adversarial Networks, specifically CycleGAN / DiscoGAN-style architectures for attribute transfer (age, gender, smile) ([ScienceABC](https://www.scienceabc.com/innovation/how-does-faceapp-work.html), [Interesting Engineering](https://interestingengineering.com/generative-adversarial-networks-the-tech-behind-deepfake-and-faceapp), [Dimensionless](https://dimensionless.in/trending-story-faceapp-gans/)). **Unverified:** whether the 2026 version still uses GANs exclusively or whether they have migrated to diffusion for newer styles. The architecture has not been publicly confirmed by the company in any source we found, and the company is privately held with no published patents we located.

What is verified: **photos are processed in the cloud, not on-device** ([FaceApp Privacy Policy](https://www.faceapp.com/en/privacy/)). Photos are encrypted with a key stored locally, but the photo itself is sent to AWS / GCP.

---

## 3. Facetune (Lightricks) — feature-by-feature deep dive

### 3.1 Feature catalog

Facetune was the original "skin smoother" and has steadily added generative AI features since 2022 ([Facetune App](https://www.facetuneapp.com/), [Lightricks Wikipedia](https://en.wikipedia.org/wiki/Lightricks), [Facetune Wikipedia](https://en.wikipedia.org/wiki/Facetune)).

| Feature | What it does | Tier | GigaRizz relevance |
|---|---|---|---|
| Smooth (skin) | Bilateral-style softening with skin-map detection ([Sonary review](https://sonary.com/b/lightricks/facetune+creative-tools/)) | Free / Pro | Critical |
| Glow / skin tone | Brightens skin and shifts tone | Pro | Critical |
| Patch | Clone-from-clean-area to cover blemishes ([Facetune blog](https://www.facetuneapp.com/features/photo-retouch)) | Pro | Medium |
| Heal Spot | Single-tap blemish remover, leaves rest untouched ([Facetune blog](https://www.facetuneapp.com/features/photo-retouch)) | Free / Pro | Critical |
| Teeth whitening | Detects teeth, brightens with temperature slider to prevent blue-white look | Free / Pro | Critical |
| Eye brightening | Lifts whites of eyes | Pro | Medium |
| Eye color change | Recolors iris | Pro | Negative — explicit identity drift |
| Eye reshape | Resizes eyes via warp | Pro | Negative for dating — too easy to over-edit |
| Face reshape / refine | Warp-based jaw / chin / cheekbone adjustments | Pro | Negative — Hinge calls out reshape edits |
| Nose reshape | Warps nose width / length | Pro | Negative |
| Lip plump / reshape | Warps lip volume | Pro | Negative |
| Body editor (sibling app: Bodytune) | Height, waist, slim, muscle | Pro | Out of scope; Bodytune is a separate app |
| Hair color / hairstyle | Generative hair try-on | Pro | Medium |
| Makeup AI | Auto-applies eye / lip / cheek makeup | Pro | Medium for women |
| AI Headshots | LoRA training on 10–15 photos, ~30 min to train, returns styled headshots ([Facetune Headshots](https://www.facetuneapp.com/features/ai-headshot-generator), [jobsearchwithai test](https://jobsearchwithai.substack.com/p/i-spent-almost-80-on-ai-headshots)) | Pro | Direct competition |
| Enhance (one-tap glow up) | AI auto-brighten + smooth + balance ([Facetune Enhance](https://www.facetuneapp.com/features/photo-retouch)) | Pro | Critical reference point |
| Vanish / object remove | Remove people, signs, distracting objects | Pro | Medium |
| Backdrop / background remove | Cut subject, swap background ([Facetune Backdrop](https://www.facetuneapp.com/features/background-remover)) | Pro | High |
| Photo filters & presets | Color grading | Free | Medium |
| Beard filters / Virtual Hair Try-Ons / Virtual Outfits | Generative try-on flows | Pro | Medium — competes with our V2 |

### 3.2 Defaults — natural vs. extreme

Facetune's marketing emphasizes natural results: "natural, high-quality results," "respectful editing experience" ([Facetune blog](https://www.facetuneapp.com/blog/best-skin-smoothing-app)). The Smooth tool's claimed advance vs. desktop frequency-separation is that it uses ML to distinguish skin tone and texture, giving "more natural" output ([GetApp](https://www.getapp.com/website-ecommerce-software/a/facetune-video/)).

In practice though, the *default sliders go all the way to extreme.* Power users push them. The catfishing critique is loud:

- "FaceTune: The Online Dating Scourge" ([Girls Chase](https://www.girlschase.com/article/dating-rules/facetune-online-dating-scourge))
- "Facetune Might Be the New Way to Catfish" ([Get Me Giddy](https://getmegiddy.com/facetune-new-way-to-catfish))
- "Almost every girl's picture was FaceTuned" — a quoted user estimate of >90% in NYC ([Girls Chase](https://www.girlschase.com/article/dating-rules/facetune-online-dating-scourge))

So while Facetune *can* do natural, the product surface makes extreme easy and there is no friction on going past the identity-drift line. There is no built-in "this looks like a different person" warning.

For AI Headshots specifically, an independent test described results as "influencer energy, not corporate executive" and called the output "less realistic and more stylized" than competitors ([jobsearchwithai test](https://jobsearchwithai.substack.com/p/i-spent-almost-80-on-ai-headshots)).

### 3.3 Pricing & conversion mechanics

- **Monthly**: $25 / month (high anchor)
- **Quarterly**: $40 / 3 months
- **Yearly**: $77.99 / year (positioned as "save 50%")
- **7-day free trial** on all plans ([Facetune Pricing](https://www.facetuneapp.com/pricing), [Pine AI](https://www.19pine.ai/cancel-subscription/newspaper-magazine-and-online-learning/how-to-cancel-facetune))

Conversion tactics are similar to FaceApp: high monthly anchor → annual looks like a steal. The 7-day trial converts automatically.

### 3.4 Known user complaints

From [Trustpilot](https://www.trustpilot.com/review/facetuneapp.com), [PissedConsumer](https://facetune.pissedconsumer.com/review.html), [JustUseApp](https://justuseapp.com/en/app/1149994032/facetune2-by-lightricks/reviews):

1. **Predatory trial / billing.** Trustpilot 1.5★ average with 69 reviews. Recurring theme: "charged months after cancellation," "trap users" language.
2. **Features moved behind paywall.** Users complain previously-free tools now require subscription.
3. **Cancellation requires both website *and* app to be cancelled separately.**
4. **Catfishing reputation.** Not technically a "complaint about the product working badly" — instead, it is a *reputation cost* the user pays for being seen using it.
5. **Over-editing visible to matches.** Implicit in the Hinge / Tinder verification trend.

### 3.5 Technical — what we can verify

- Facetune is built by Lightricks on top of their "LTEngine" image processing engine designed for mobile platforms ([Lightricks Wikipedia](https://en.wikipedia.org/wiki/Lightricks))
- Lightricks began incorporating generative AI flows in Facetune from summer 2022 ([Lightricks](https://www.lightricks.com/))
- Newer features (AI Headshots, Virtual Hair, Virtual Outfits) are LoRA-based training flows that require ~30 minutes of model training ([Facetune Headshots](https://www.facetuneapp.com/features/ai-headshot-generator)). LoRA training is cloud — not on-device.
- Skin smoothing on still images appears to be partly on-device (legacy Facetune was famous for fast offline edits) but the newer generative flows are cloud. **Unverified:** the exact split between on-device and cloud in 2026; Lightricks does not publicly document this.

---

## 4. The dating-app context — what FaceApp and Facetune don't have to care about

This is the structural opening for GigaRizz. Five demands that the dating context imposes:

### 4.1 Selfie Verification / Face Check survival

Tinder Face Check and Hinge Selfie Verification both fail on heavily edited photos. Hinge documentation calls this out directly: "different hairstyles or heavy makeup may cause verification to fail," "distant photos, blocked by sunglasses or hair, or heavily edited photos can cause the algorithm to fail" ([Hinge Help](https://help.hinge.co/hc/en-us/articles/10303221435539-What-is-Selfie-Verification)). Tinder uses an encrypted, non-reversible facial map to detect fraud and duplicate accounts ([Identity Week](https://identityweek.net/tinder-expands-facial-verification-across-the-u-s-raising-the-bar-for-dating-app-safety/)).

**Implication:** every photo we ship must pass a face-embedding similarity check against the user's verified selfie or it will get the user banned from the dating app.

### 4.2 Subtlety as default, not as a slider preset

Facetune ships sliders that go all the way to 100. The "natural look" relies on user restraint. Dating users do not have that restraint — see the 90% NYC estimate. GigaRizz's defaults must clamp.

### 4.3 Outcome, not aesthetic

FaceApp and Facetune sell aesthetic transformation. GigaRizz V2 already instruments match outcomes (see `V3_PRODUCT_PLAN.md`). Photo edits should be tied to whether they actually move match rate, not just whether they look pretty in isolation.

### 4.4 Identity drift detection

No general selfie editor warns the user "this no longer looks like you." A dating editor must, because the *match conversation* will reveal the catfish.

### 4.5 Privacy posture

FaceApp uploads to AWS / GCP with a 24–48h cache. For dating photos containing the user's face *and* their stated identity, this is uncomfortable. Many users will pay a meaningful premium for "stays on device."

---

## 5. The GigaRizz Way — feature-by-feature recommendations

For each feature category, what we ship, what defaults we set, where we run it, and what the post-edit identity-match threshold is.

> **Notation.** Identity match threshold uses a normalized cosine similarity on Apple Vision face-print embeddings vs. the user's verified selfie. 1.0 = identical, 0.0 = unrelated. We treat ≥ 0.85 as "passes Face Check"; 0.75–0.85 as "ship with warning"; < 0.75 as "block." These thresholds are starting points and must be calibrated against the per-platform threshold once we have a test set of real Hinge/Tinder verifications (see Section 6 build plan).

### 5.1 Skin (smoothing, glow, blemish removal)

**Ship.** Three controls collapsed into one slider: *Skin Polish* (0–100, default **20**).

- Default 20 = bilateral filter with low strength, only inside detected skin map, preserves pores at the eye and lip transition zones.
- 50+ blocked unless user explicitly toggles "Aggressive" with a warning *"may reduce identity match"*.
- Separate Heal-Spot tap tool for single-blemish removal (this is the safest edit — small region, no global change).

**Where.** Fully on-device. Core Image `CIBilateralFilter` + a Vision-derived skin mask. See the well-known [YUCIHighPassSkinSmoothing](https://github.com/YuAo/YUCIHighPassSkinSmoothing) reference implementation. There is no quality reason to send a skin smooth to the cloud, and on-device gives us the privacy-first marketing.

**Threshold after edit.** ≥ 0.92. Skin smoothing should be invisible to a face embedding; if our pipeline drops below 0.92 we have a bug.

### 5.2 Teeth (whitening)

**Ship.** Auto teeth whitening, defaults to **subtle (~+15 brightness, +5 saturation reduction)**. Detect teeth region using Vision mouth landmarks (the `innerLips` polygon).

**Where.** On-device. This is a localized LUT, no neural net needed.

**Threshold after edit.** ≥ 0.95. Teeth whitening is sub-region; should be embedding-invisible.

### 5.3 Eyes

**Ship.** Three subfeatures, with one explicitly excluded:

- **Whites brightening** (default 15%, low-aggression LUT, Vision sclera mask) — ship.
- **Eye bag softening** (default 20%, frequency-separation on under-eye region) — ship.
- **Eye reshape** — **do not ship**. Crosses the identity line. Document this as a deliberate omission in onboarding ("we don't reshape your eyes; matches see your eyes on a first date").
- **Eye color change** — **do not ship**. Hard identity drift, fails Face Check guaranteed.

**Where.** On-device. Vision eye landmarks + Core Image LUT.

**Threshold after edit.** ≥ 0.93.

### 5.4 Jaw / nose / lips / face reshape

**Ship nothing.** This is the line where dating photos stop looking like the user. Hinge explicitly calls out reshape edits as a verification failure cause ([Hinge Help](https://help.hinge.co/hc/en-us/articles/10303221435539-What-is-Selfie-Verification)). The right product move is to *not* ship a reshape tool and to put a Subtlety Lock badge ("we don't reshape your face") on the editor. This is a competitive moat: Facetune cannot remove their reshape tool without losing power users.

**Substitute.** Pose / angle recommendations from our existing PhotoAudit. If the user wants a different jawline, change the pose and lighting; do not warp the face.

### 5.5 Hair (color, hairstyle, hairline)

**Ship.** Generative hairstyle try-on (we already have this in V2 `Features/HairstylePicker`). Default to subtle variations within the user's current style family; require explicit selection for radical changes.

**Where.** Cloud — generative hair try-on quality is dominated by diffusion / Nano Banana / Gemini class models that won't run on phone hardware in 2026.

**Threshold after edit.** ≥ 0.85 (lower bar than skin because hair can plausibly change without identity change). Flag any output < 0.80 even if the user requested a big change, with a "this looks like someone else" warning.

**Recommended providers.** Gemini's Nano Banana Pro for hair try-on — independent tests show it "maintains character identity across edits and angles" and is best-in-class for facial feature preservation ([getimg.ai comparison](https://getimg.ai/blog/gpt-image-15-vs-nano-banana-pro-comparison-which-ai-image-model-is-better)). Fallback to fal.ai Recraft V3 image-to-image at $0.04 per image ([fal.ai Recraft V3](https://fal.ai/models/fal-ai/recraft/v3/image-to-image)).

### 5.6 Facial hair (beard, stubble)

**Ship.** Add / remove beard, stubble try-on. Same cloud generative approach as hair.

**Defaults.** Show three variants per request (none / stubble / full), let user A/B inside the audit. Default selection is the user's *current* state — we don't preemptively suggest a different look.

**Threshold after edit.** ≥ 0.85.

### 5.7 Makeup

**Ship.** Soft, dating-appropriate makeup defaults (subtle eye, neutral lip, light cheek). No "Hollywood Glamour" preset; that pack reads as "trying too hard" in dating apps.

**Where.** On-device for static makeup (LUT-based overlay tied to facial landmarks). Cloud only for "AI Makeup" full-face restyle.

**Threshold after edit.** ≥ 0.90 (makeup can shift embeddings by ~0.05 in practice; we must measure and re-calibrate).

### 5.8 Background

**Ship.** Background swap (we have this in V2 `Features/BackgroundReplacer`). Critical caveats specific to dating:

- Default backgrounds are *plausibly real locations* (coffee shop, park, gym, kitchen), not fantasy landscapes.
- Every generated background gets a "*This is an AI background, not a place you've been*" footer in the export. We don't market this as a watermark; we market it as **anti-catfish honesty**.
- Add a "is the background consistent with the lighting on the user's face" check; reject inconsistent outputs.

**Where.** Cloud generative (Recraft V3 image-to-image, $0.04 / image; or Nano Banana for higher quality). On-device segmentation (Vision `VNGeneratePersonSegmentationRequest`) to cut the subject.

**Threshold after edit.** ≥ 0.95 (background swap should not touch the face).

### 5.9 Lighting

**Ship.** Relight tool, on-device. Vision-based face normal estimation + a relight LUT. Provider fallback: `lucataco/codeformer` on Replicate for cases where on-device relight degrades faces.

**Defaults.** Three presets: *Window light*, *Golden hour*, *Coffee shop*. No HDR.

**Threshold after edit.** ≥ 0.92.

### 5.10 Sharpness / detail

**Ship.** Face Restore using CodeFormer on Replicate, with `fidelity_weight = 0.7` as default (heavier identity preservation per CodeFormer's docs; w ∈ [0,1], higher = more identity-faithful) ([CodeFormer on Replicate](https://replicate.com/sczhou/codeformer), [CodeFormer GitHub](https://github.com/sczhou/CodeFormer)).

- Trigger automatically on any input photo below a quality threshold (Vision `VNDetectFaceCaptureQualityRequest`).
- Cost: ~$0.0056 per run on Replicate ([Replicate CodeFormer pricing](https://replicate.com/lucataco/codeformer)). 178 runs per $1 means we can include 5–10 runs per free user without affecting unit economics.

**Threshold after edit.** ≥ 0.90.

### 5.11 Expression (smile)

**Ship.** Smile *enhance* (mouth corner lift, lip parting), not smile *add*. The difference: enhance only operates on an already-smiling photo; add cannot guarantee identity preservation because a closed-mouth face has no teeth visible and the model has to invent them.

**Defaults.** Enhance only. "Add smile" is explicitly absent from our editor; we ship it as guidance instead ("re-take this photo while genuinely smiling").

**Where.** On-device warp on lip / mouth-corner landmarks.

**Threshold after edit.** ≥ 0.93.

### 5.12 What we don't ship (and say so)

A short "we don't do this" list, made visible in onboarding and on the editor screen:

- We don't reshape your face, jaw, nose, or eyes
- We don't change your eye color
- We don't slim your body
- We don't age you up or down
- We don't make you smile if you weren't smiling
- We don't put you in places you've never been (without disclosing it)

This list is itself a marketing asset. Every line is a feature FaceApp or Facetune ships.

---

## 6. Three category-killer features

These are the moves FaceApp and Facetune cannot copy because they would conflict with what makes those products work. Each is sized for an implementation sprint.

### 6.1 FaceCheck Pre-Flight

**What it does.** Before the user uploads a photo to a dating app, GigaRizz runs the photo against the user's verified selfie using on-device face embedding similarity. Shows a clear pass/fail indicator: *"Predicted to pass Hinge / Tinder / Bumble verification: 92%"*.

**Why FaceApp / Facetune won't build it.** Acknowledging that a heavily edited photo might fail verification implies their editor is the cause of the problem. It directly cannibalizes their power user behavior.

**Infrastructure required.**
- On-device face embedding. Apple Vision `VNFaceObservation` returns a 128-d face print. Alternatively, ship a custom CoreML model trained on identity-preservation tasks; this is more accurate but heavier.
- Calibration dataset: ~100 manual A/B tests across Hinge / Tinder / Bumble Face Check / Selfie Verification, recording threshold pass / fail. Use that to fit the per-platform similarity cutoff.
- A red / yellow / green badge wired into the photo grid and the export step.

**Touches existing surface.** `Features/PhotoAudit`, `Features/Preview`, `Features/Share`.

### 6.2 Identity Match Certificate

**What it does.** Every photo we export ships with a small, copyable JSON receipt: *Edits applied: skin polish 20, teeth whitening 15, background swap (AI-generated). Identity Match score vs. your reference selfie: 0.93.*

The user can show this to anyone (a date who asks "is this real?", a Hinge moderator, themselves on a bad self-esteem day) and prove the photo is them. The receipt also fingerprints the photo: hash + timestamp + edit list.

**Why FaceApp / Facetune won't build it.** A receipt makes the edit list legible. Their power feature is hiding how much was edited.

**Infrastructure required.**
- Edit ledger — we already have most of this from V2's `Features/Tools` flow. Wire it into a single JSON blob per export.
- Hash + sign with a per-user device key. Future-proofs us for [C2PA](https://c2pa.org/) content credentials, which Hinge / Match Group is likely to adopt as part of their verification roadmap.
- A simple "Show Receipt" UI on every exported photo.

**Touches.** `Features/Share`, `Features/Preview`, a new `Features/Receipt` module.

### 6.3 Audit-Driven Glow Up

**What it does.** Today our PhotoAudit identifies issues per category (lighting, expression, composition, etc.). The Glow Up button automatically applies the *correct* tool for each named issue, runs the full chain in one tap, and re-audits to confirm the score improved.

Example chain for one photo:
- Audit says *"Eyes are a bit closed, smile is forced, background is busy."*
- Glow Up automatically: re-runs smile enhance (subtle), opens eyes via eye landmark warp (skipped because we don't ship eye reshape — fallback to a brightness lift on the iris), swaps to a plausible coffee-shop background.
- Re-audit confirms improvement; Identity Match still ≥ 0.85.
- Show the user a diff: *Audit score 6.4 → 8.1. Identity Match 0.94.*

**Why FaceApp / Facetune won't build it.** They have no audit. They sell *manual editing tools as a destination*, not *photo improvement as a service*. An automatic, score-driven workflow inverts their entire UX.

**Infrastructure required.**
- Mapping table: audit issue → tool to apply → recommended strength.
- Re-audit pass after the chain (we already have audit infra).
- Diff UI that shows before / after with annotation per applied change.
- One Glow Up button per photo and a "Glow Up all 6" batch action.

**Touches.** `Features/PhotoAudit`, `Features/FaceEnhancement`, `Features/Preview`, `Features/Tools`.

### 6.4 (Honorable mention — Subtlety Lock)

The Subtlety Lock — a global maximum edit budget per photo, capped at the level needed to clear Face Check — is the connective tissue across all three killers. It is less a feature than a default. It should always be on; the user can override only with an explicit "more aggressive" toggle that surfaces the predicted Face Check fail probability.

---

## 7. Practical "build now" recommendation

> **The one feature to ship in two weeks of engineering time is FaceCheck Pre-Flight, plus the bare-minimum scaffolding for an Identity Match Certificate to make Pre-Flight legible.**

### 7.1 Justification

**(a) From the research, the dominant 1-star theme across both FaceApp and Facetune is *trust* — billing complaints sit alongside "results look fake" and an explicit catfishing reputation.** FaceCheck Pre-Flight is the only feature in the dating-photo space that *proves* the result is trustworthy, on the platform the user actually cares about.

**(b) GigaRizz V2 already has the surfaces this lands on.** `Features/PhotoAudit/PhotoAuditViewModel.swift` is the right host for the embedding compare. `Features/Preview` and `Features/Share` already render per-photo metadata. We do not need a new tab.

**(c) FaceCheck verification is the live, ascending trend in dating apps.** Tinder rolled out US-wide in 2025–2026; Hinge mandated it in UK / Australia and is rolling it out elsewhere; Match Group plans to ship Face Check to more apps in 2026 ([Identity Week](https://identityweek.net/tinder-expands-facial-verification-across-the-u-s-raising-the-bar-for-dating-app-safety/)). Every month that passes makes the wedge bigger. Shipping in two weeks lets us be first to market with a Face-Check-aware editor.

**(d) The infrastructure is small enough to ship in two weeks.** No new ML training. No new cloud spend. Apple Vision face print is on-device, free, and already permitted under our existing entitlements. The Identity Match score is one cosine-similarity call.

### 7.2 Two-week build plan

| Day | Deliverable |
|---|---|
| 1–2 | Add `FaceEmbeddingService` (Core/Services). Wraps Vision face print extraction. Returns 128-d vector. Unit tests on 20 sample photos. |
| 3 | Reference selfie capture flow in onboarding. One-time. Stored on-device (Keychain-backed). |
| 4–5 | Cosine-similarity scoring on every photo in `Features/PhotoAudit`. Wire into existing audit result. |
| 6 | Threshold calibration set — internal team takes 30 photos each, runs Hinge / Tinder selfie verification, logs pass/fail. (This is a TestFlight task assigned to the team, not engineering hours.) |
| 7–8 | Pre-Flight badge UI. Red / yellow / green dot in the photo grid. Per-photo detail screen shows the score and "predicted to pass" status per platform. |
| 9–10 | Export flow: every shared photo writes a minimal JSON receipt to a hidden side-channel (Photos extended attributes or a paired .json in a Files folder). UI shows "Identity Match: 0.93 · Verified". |
| 11–12 | Failing-photo flow. If a photo predicts fail, offer one-tap "Re-edit at lower intensity" using the existing Glow Up tools dialed back to half-strength. |
| 13 | Marketing copy + onboarding card: "GigaRizz is the only editor that checks your photo against your verified selfie before you upload." |
| 14 | TestFlight push, instrument the metric. |

### 7.3 What this unlocks

- **App Store screenshot 1:** *"Will this photo pass Hinge verification? GigaRizz checks before you post."*
- **Conversion driver:** Pre-Flight runs free; the auto-fix using Glow Up is a paid feature. This pushes the user from free audit into paid edit with a concrete justification.
- **Brand contract made literal:** "Keep me looking like me" is now a number on every photo.
- **Defense against future native AI:** Hinge / Tinder cannot ship FaceCheck Pre-Flight themselves — that would be advertising their own approval threshold to manipulators. The structural opening stays open for us.

---

## 8. Summary table — head-to-head feature posture

| Feature category | FaceApp default | Facetune default | GigaRizz Way |
|---|---|---|---|
| Skin smoothing | Moderate-strong | Up to 100, user-driven | Capped at 20% by default; on-device |
| Teeth whitening | Pro, slider | Slider + temperature | Subtle auto, on-device, embedding-invisible |
| Eye reshape | Pro | Yes | **Not shipped** — explicit non-feature |
| Eye color change | No | Yes | **Not shipped** |
| Face / jaw reshape | Pro | Yes | **Not shipped** — Subtlety Lock |
| Nose reshape | Pro | Yes | **Not shipped** |
| Hair try-on | Yes | Yes (Virtual Hair) | Yes — Nano Banana / Recraft, drift-checked |
| Beard try-on | Yes | Yes | Yes — drift-checked, three-variant compare |
| Makeup | Hollywood / Glamour packs | AI Makeup full restyle | Subtle dating-appropriate defaults; no glamour pack |
| Smile add | Cheshire-cat artifacts | No (Facetune doesn't have add-smile generative) | **Enhance only** — never invent teeth |
| Age shift | Core feature | No (sibling apps) | **Not shipped** — anti-aging lock from V4 plan |
| Background swap | Yes | Backdrop | Yes — plausible locations, "AI background" disclosed |
| One-tap enhance | Yes (impressions) | Yes (Enhance) | **Glow Up** — audit-driven, automatic, re-checked |
| Identity match score | None | None | **Per-photo, every export** |
| Verification pre-check | None | None | **Per-photo, per platform** |
| Edit receipt | None | None | **Signed JSON per export** |
| Subtlety cap | None | None | **Default on** |
| On-device share | No | Partial | Skin / teeth / eyes / smile / background segmentation all on-device |
| Pricing model | $19.99 / yr, $79.99 lifetime | $25/mo, $77.99/yr | Monthly + annual + credits (see V4 plan) — no weekly |
| Cancellation friction | High (top complaint) | High (top complaint) | One-tap in-app cancel (V4 plan) |

---

## 9. Open questions for follow-up

These are things we could not confirm in this pass and should resolve before shipping:

1. **Exact Face Check / Selfie Verification thresholds.** Tinder and Hinge do not publish their cutoffs. We have to derive them empirically from a calibration set. **Unverified** — initial 0.85 threshold is a starting hypothesis only.
2. **Whether Face Check stores a 128-d embedding compatible with Apple Vision.** Unlikely (Apple's face print is a private representation). We are using *similarity to user's own reference selfie* as a proxy. This is a defensible approximation but is not the same metric Match Group uses.
3. **2026 FaceApp model architecture.** GAN-based historically ([ScienceABC](https://www.scienceabc.com/innovation/how-does-faceapp-work.html)); whether they have migrated newer features (background editing, styles) to diffusion is **unverified.**
4. **Facetune AI Studio's on-device / cloud split.** Lightricks publishes that they have an LTEngine on-device library but does not document which 2026 features run where. **Unverified.**
5. **C2PA adoption by Match Group.** The Identity Match Certificate would compose with C2PA cleanly. Whether Match Group has signaled adoption is unconfirmed and worth tracking quarterly.

---

## 10. Sources

- [FaceApp.com](https://www.faceapp.com/)
- [FaceApp Privacy Policy](https://www.faceapp.com/en/privacy/)
- [FaceApp FAQ — pricing](https://www.faceapp.com/faq/how-much-does-faceapp-cost/)
- [FaceApp review 2026 (AI Chat Daily)](https://www.aichatdaily.com/tools/faceapp)
- [FaceApp Reviews — JustUseApp](https://justuseapp.com/en/app/1180884341/faceapp-ai-face-editor/reviews)
- [FaceApp Reviews — Trustpilot](https://www.trustpilot.com/review/faceapp.com)
- [FaceApp — PissedConsumer](https://faceapp.pissedconsumer.com/review.html)
- [FaceApp Pricing Plans — Alternatives.co](https://alternatives.co/software/faceapp/pricing/)
- [PBS: Is FaceApp a security risk?](https://www.pbs.org/newshour/science/is-faceapp-a-security-risk-3-privacy-concerns-you-should-take-seriously)
- [TechCrunch: FaceApp responds to privacy concerns](https://techcrunch.com/2019/07/17/faceapp-responds-to-privacy-concerns/)
- [SecurityBrief: FaceApp Pro version scams](https://securitybrief.asia/story/faceapp-pro-version-scams-privacy-concerns)
- [Common Sense Media: FaceApp review](https://www.commonsensemedia.org/app-reviews/faceapp-ai-face-editor)
- [FaceApp Wikipedia](https://en.wikipedia.org/wiki/FaceApp)
- [ScienceABC: How does FaceApp work?](https://www.scienceabc.com/innovation/how-does-faceapp-work.html)
- [Interesting Engineering: GANs behind FaceApp](https://interestingengineering.com/generative-adversarial-networks-the-tech-behind-deepfake-and-faceapp)
- [Dimensionless: FaceApp & GANs](https://dimensionless.in/trending-story-faceapp-gans/)
- [Facetune (Lightricks) homepage](https://www.facetuneapp.com/)
- [Facetune Pricing](https://www.facetuneapp.com/pricing)
- [Facetune Photo Retouch features](https://www.facetuneapp.com/features/photo-retouch)
- [Facetune AI Headshot Generator](https://www.facetuneapp.com/features/ai-headshot-generator)
- [Facetune Background Remover](https://www.facetuneapp.com/features/background-remover)
- [Facetune Blog: Skin tone editing](https://www.facetuneapp.com/blog/skin-tone-editing-facetune)
- [Facetune Blog: Best skin smoothing apps](https://www.facetuneapp.com/blog/best-skin-smoothing-app)
- [Facetune Blog: Dating profile photos](https://www.facetuneapp.com/blog/goodbye-photoshoots-for-dating-profiles)
- [Facetune Headshots for Men](https://www.facetuneapp.com/create/headshots-for-men)
- [Facetune Reviews — Trustpilot](https://www.trustpilot.com/review/facetuneapp.com)
- [Facetune — PissedConsumer](https://facetune.pissedconsumer.com/review.html)
- [Facetune Reviews — JustUseApp](https://justuseapp.com/en/app/1149994032/facetune2-by-lightricks/reviews)
- [Facetune 2026 review — GetApp](https://www.getapp.com/website-ecommerce-software/a/facetune-video/)
- [Facetune AI Tools review — Sonary](https://sonary.com/b/lightricks/facetune+ai-tools/)
- [Facetune AI Photo & Video Editor review — Sonary](https://sonary.com/b/lightricks/facetune+creative-tools/)
- [Facetune Wikipedia](https://en.wikipedia.org/wiki/Facetune)
- [Lightricks Wikipedia](https://en.wikipedia.org/wiki/Lightricks)
- [Lightricks homepage](https://www.lightricks.com/)
- [Pine AI: How to Cancel Facetune (2026)](https://www.19pine.ai/cancel-subscription/newspaper-magazine-and-online-learning/how-to-cancel-facetune)
- [I Spent Almost $80 on AI Headshots (independent test)](https://jobsearchwithai.substack.com/p/i-spent-almost-80-on-ai-headshots)
- [Girls Chase: FaceTune — The Online Dating Scourge](https://www.girlschase.com/article/dating-rules/facetune-online-dating-scourge)
- [Get Me Giddy: Facetune as catfishing](https://getmegiddy.com/facetune-new-way-to-catfish)
- [Identity Week: Tinder expands facial verification](https://identityweek.net/tinder-expands-facial-verification-across-the-u-s-raising-the-bar-for-dating-app-safety/)
- [Scripps News: Tinder facial verification rollout](https://www.scrippsnews.com/business/company-news/safe-swiping-tinder-launches-nationwide-facial-verification-to-fight-catfishing)
- [ID Tech: Hinge makes Face Check mandatory](https://idtechwire.com/hinge-makes-face-check-mandatory-as-uk-and-australia-age-verification-rules-drive-dating-app-biometrics/)
- [Hinge Help: What is Selfie Verification?](https://help.hinge.co/hc/en-us/articles/10303221435539-What-is-Selfie-Verification)
- [Hinge Help: Face Check Scan](https://help.hinge.co/hc/en-us/articles/45715796564243-Face-Check-Scan)
- [Engadget: Hinge video identity verification](https://www.engadget.com/hinge-video-selfie-verification-announced-202522227.html)
- [Apple Developer: VNDetectFaceLandmarksRequest](https://developer.apple.com/documentation/vision/vndetectfacelandmarksrequest)
- [Apple Developer: Vision framework](https://developer.apple.com/documentation/vision)
- [GitHub: YUCIHighPassSkinSmoothing](https://github.com/YuAo/YUCIHighPassSkinSmoothing)
- [Replicate: CodeFormer by sczhou](https://replicate.com/sczhou/codeformer)
- [Replicate: CodeFormer by lucataco (pricing)](https://replicate.com/lucataco/codeformer)
- [GitHub: CodeFormer source (NeurIPS 2022)](https://github.com/sczhou/CodeFormer)
- [fal.ai: CodeFormer](https://fal.ai/models/fal-ai/codeformer)
- [fal.ai: Recraft V3 image-to-image](https://fal.ai/models/fal-ai/recraft/v3/image-to-image)
- [fal.ai: Recraft V3 text-to-image](https://fal.ai/models/fal-ai/recraft/v3/text-to-image)
- [Google DeepMind: Gemini Image (Nano Banana)](https://deepmind.google/models/gemini-image/)
- [Google DeepMind: Nano Banana Pro](https://deepmind.google/models/gemini-image/pro/)
- [getimg.ai: GPT Image 1.5 vs Nano Banana Pro](https://getimg.ai/blog/gpt-image-15-vs-nano-banana-pro-comparison-which-ai-image-model-is-better)
- [Photalabs: Identity Preservation in photos](https://www.photalabs.com/blog/identity-preservation)
- [Springer / Multimedia Systems: Identity & structure preserving face editing via diffusion](https://link.springer.com/article/10.1007/s00530-025-02183-9)
- [Skywork: Character consistency in generative AI](https://skywork.ai/blog/character-consistency-generative-ai/)
- [DatingPhotoAI: 7 rules for better dating profile photos](https://www.datingphotoai.com/blog/7-rules-for-better-dating-profile-photos)
- [Smooch: Best dating profile photos data guide](https://www.smooch.com/guides/profile-tips/photos)
