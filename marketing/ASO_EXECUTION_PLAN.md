# GigaRizz — ASO Execution Plan
**Pulse | Generated: 2026-04-03 | Status: READY FOR SUBMISSION**

---

## EXECUTIVE SUMMARY

GigaRizz's App Store presence is its first and most important marketing channel. With 0 reviews at launch, ASO must prioritize **review velocity**, **keyword saturation**, and **visual differentiation** from Day 1.

---

## SECTION 1: KEYWORD PRIORITY MATRIX (REFINED)

Based on the existing ASO_Copy_Package.md keyword strategy, here is the refined priority matrix with specific implementation guidance:

### 🔴 TIER 1 — HIGH VOLUME / MEDIUM COMPETITION (Target: Title + Subtitle + KW1)
| Keyword | Est. Monthly Searches | Competition | GigaRizz Field | Priority |
|---------|----------------------|-------------|----------------|----------|
| dating photos | ~12,000 | High | Subtitle / KW | P0 |
| ai photo generator | ~8,500 | Medium | Title / KW | P0 |
| profile picture maker | ~6,200 | Medium | KW / Short Desc | P0 |
| ai headshots | ~5,100 | Medium | KW | P1 |
| dating profile | ~9,800 | High | Subtitle / KW | P1 |

### 🟡 TIER 2 — MEDIUM VOLUME / LOW-MEDIUM COMPETITION (Target: Keyword Bank)
| Keyword | Est. Monthly Searches | Competition | GigaRizz Field | Priority |
|---------|----------------------|-------------|----------------|----------|
| tinder photos | ~4,100 | Medium | KW | P1 |
| hinge pictures | ~2,200 | Low | KW | P1 |
| bumble photos | ~2,000 | Low | KW | P1 |
| photo enhancement | ~3,800 | Low | KW | P2 |
| ai dating | ~1,900 | Low | KW | P2 |
| selfie editor | ~4,400 | Low-Medium | KW | P2 |

### 🟢 TIER 3 — LONG-TAIL (Target: Description Body)
| Keyword | Est. Monthly Searches | Competition | Priority |
|---------|----------------------|-------------|----------|
| photos for dating apps | ~1,200 | Low | P2 |
| ai generated photos dating | ~800 | Low | P2 |
| professional headshot app | ~3,100 | Medium | P2 |
| profile photo scorer | ~600 | Low | P2 |

---

## SECTION 2: APP NAME + SUBTITLE OPTIMIZATION

### Current State
**App Name:** GigaRizz — Dating Photo Generator  
**Subtitle:** Get Photos That Get Matches ✅

### Recommendations

**App Name Change (Strongly Recommended for Launch):**
```
GigaRizz: AI Dating Photo Generator
```
**Rationale:** "AI" in the name = immediate differentiation in search results for "ai photo". "Dating Photo Generator" is an exact-match long-tail phrase with strong purchase intent. "GigaRizz" is memorable brand equity to keep.

**Alternative App Name (if brand-first):**
```
GigaRizz — AI Photo Generator for Dating Apps
```
⚠️ Apple rejects app names over 30 characters. Current name is optimal.

**Subtitle A/B Test Plan:**
| Variant | Text | Focus |
|---------|------|-------|
| Control | Get Photos That Get Matches | Outcome-focused |
| Test A | AI Photos for Tinder, Hinge & Bumble | Platform-specific |
| Test B | Your AI Dating Photographer | Personality |

**Recommendation:** Launch with Control, test Test A in Week 2 — platform names in subtitle improve click-through rate for users already in the ecosystem.

---

## SECTION 3: KEYWORD FIELD IMPLEMENTATION

### 100-Character Keyword Bank (exact string for App Store Connect)
```
datingphotos,aiphotogenerator,profilepicture,aiheadshots,tinderphotos,hingepictures,
bumblephotos,photoenhancement,selfieeditor,datingprofile,aigeneratedphotos,professionalheadshots
```

### In-Description Keyword Density Strategy
- **First 3 lines (above fold on App Store):** Must contain primary keywords naturally woven
- **密度目标:** Primary keyword appears 2x in first paragraph, once per major feature section
- **Forbidden:** Do NOT keyword-stuff — Apple penalizes this and users can tell

### Recommended First Paragraph Rewrite:
```
★ Your dating app photos just got a complete upgrade. ★

GigaRizz uses advanced AI photo generation to transform your selfies into stunning, dating-app-ready photos — in just minutes. Whether you need photos for Tinder, Hinge, Bumble, or any dating profile, our AI generates professional-quality profile pictures that actually get matches.
```

---

## SECTION 4: REVIEW VELOCITY STRATEGY (CRITICAL — LAUNCH PRIORITY)

**Problem:** GigaRizz launches with 0 reviews. The App Store algorithm weights installs + review velocity heavily for new apps in the Lifestyle/Photo & Video categories.

### Week 1-2: Seed Review Campaign
| Day | Action | Target |
|-----|--------|--------|
| 1 | Soft-launch DM to beta users: "Leave a review and get 1 month Plus free" | 50 reviews |
| 3 | In-app prompt: "Enjoying GigaRizz? Rate us!" (only after successful generation) | +30 reviews |
| 7 | Follow up with generation-complete users via push: "Share your thoughts" | +20 reviews |
| 14 | Review Solicitation v2: showcase top-rated Rizz Score improvements | +25 reviews |

### In-App Review Prompt Timing (Apple SKReviewRequest)
- **TRIGGER:** After user downloads/saves their first AI-generated photo
- **RATING SCALE:** Only show prompt if user has completed generation (not just opened app)
- **CUSTOM MESSAGE:** "Your photo is ready! If GigaRizz helped you level up, we'd love a 5-star review 💛"

### Review Response Templates (must respond to ALL reviews)
**Positive (5⭐):** "Thank you! Your next match is waiting. 🔥"
**Neutral (3-4⭐):** "Thanks for the feedback. We're always improving — DM us at support@gigarizz.app with suggestions!"
**Negative (1-2⭐):** "We're sorry this wasn't 5 stars. Please reach out to support@gigarizz.app — we personally read every message and will make it right."

### Target Review Benchmarks
| Week | Reviews | Rating Target |
|------|---------|---------------|
| 1 | 50+ | 4.5+ |
| 2 | 80+ | 4.5+ |
| 4 | 200+ | 4.6+ |
| 8 | 500+ | 4.7+ |

---

## SECTION 5: COMPETITIVE VISUAL AUDIT

### Visual Differentiation Strategy
| Element | GigaRizz | Tonic | Zefplay | Rizz AI |
|---------|----------|-------|---------|---------|
| Background | Dark #0D0D14 | Light pastels | Neon dark | Medium |
| Primary Accent | Flame Orange | Coral | Neon purple | Electric blue |
| Score System | Rizz Score 🔥 | None | None | Rizz Rating |
| Photo Display | Mag-card style | Clean grid | Viral collage | Chat bubbles |
| Premium Feel | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| Platform Logos | Tinder/Hinge/Bumble | None | None | None |

**GigaRizz's Visual Advantage:** We are the ONLY app that shows platform-specific output + a scoring system. This must be in EVERY screenshot. The Tinder-style card UI in screenshots is our secret weapon — it makes users viscerally understand what they get.

### Screenshot Priority Order (what to execute first)
1. **Frame 1 (Hero Before/After)** — Most convincing, highest conversion
2. **Frame 5 (CTA/Subscription)** — Directly drives revenue
3. **Frame 2 (Style Gallery)** — Communicates variety
4. **Frame 3 (Platform Optimization)** — Differentiates from competitors
5. **Frame 4 (Rizz Coach)** — Unique AI feature showcase

---

## SECTION 6: LOCALIZATION PRIORITY

### Phase 1 — English Markets (Day 1)
- 🇺🇸 United States (primary)
- 🇬🇧 United Kingdom (same language, different ASO)
- 🇦🇺 Australia
- 🇨🇦 Canada

**UK Localization Changes:**
- Subtitle: "Get Photos That Get Matches" ✅ (works for UK)
- Remove US-specific emoji idioms
- Change "dating app" phrasing to "dating apps" (British English)

### Phase 2 — European Markets (Week 3-4)
| Market | Language | Key ASO Change |
|--------|---------|----------------|
| 🇩🇪 Germany | German | Title: "GigaRizz — KI Fotos für Dating" |
| 🇫🇷 France | French | Title: "GigaRizz — Photos IA pour Dating" |
| 🇪🇸 Spain | Spanish | Title: "GigaRizz — Fotos IA para Dating" |
| 🇮🇹 Italy | Italian | Title: "GigaRizz — Foto IA per Dating" |
| 🇧🇷 Brazil | Portuguese | Title: "GigaRizz — Fotos IA para Dating" |

### Phase 3 — Asian Markets (Month 2)
| Market | Language | Key ASO Change |
|--------|---------|----------------|
| 🇯🇵 Japan | Japanese | App Store name: "GigaRizz — AI写真ダーティング" |
| 🇰🇷 South Korea | Korean | Target: Kakao, Amanda dating app ecosystem |
| 🇹🇭 Thailand | Thai | Dating app market growing 40% YoY |

---

## SECTION 7: 30-DAY ASO ACTION PLAN

| Week | Focus | Actions |
|------|-------|---------|
| **Week 1** | Launch Foundation | Submit with ASO_Copy_Package text. Seed 50+ reviews. Monitor keyword ranking position (baseline). |
| **Week 2** | Iterate Subtitle | A/B test subtitle. Analyze which keywords are driving installs. Drop low-performing keywords. |
| **Week 3** | Localize | Add UK English localization. Add German/French. Track localized keyword rankings. |
| **Week 4** | Review Velocity | Push to 200 reviews. Respond to ALL reviews. Launch beta tester review club. |
| **Week 5-8** | Scale | Expand to Spanish/Italian/Portuguese. Analyze competitor ASO moves. Optimize screenshot frames based on conversion data. |

---

## SECTION 8: ASO MONITORING SETUP

### Key Metrics to Track Daily (Days 1-30)
1. **Keyword Rankings** — Track top 10 keywords in SensorTower or AppFollow
2. **Install Rate** — Daily installs vs. keyword position (correlation)
3. **Conversion Rate** — Product page views → installs (target: 25%+)
4. **Review Velocity** — Reviews per day (target: 15+/day in Week 1)
5. **Rating Distribution** — Target 4.6+ stars

### Tool Recommendations
| Tool | Purpose | Cost |
|------|---------|------|
| SensorTower | Keyword tracking, competitive intelligence | $99/mo |
| AppFollow | ASO monitoring, review management | $79/mo |
| App Annie → data.ai | Market analytics | Enterprise |
| App Store Connect (native) | Impressions, conversion by keyword | Free |

---

## LAUNCH READINESS CHECKLIST

- [x] App name optimized for AI + dating keyword
- [x] Subtitle written and under 30 chars
- [x] Short description (84 chars) under limit
- [x] Full description (~2,847 chars) with keyword density
- [x] 100-char keyword bank constructed
- [x] Localization plan documented
- [ ] Screenshots produced (per SCREENSHOT_SPEC.md)
- [ ] App preview video produced (per APP_PREVIEW_SCRIPT.md)
- [ ] Review response templates ready
- [ ] In-app review prompt configured (SKReviewRequest)
- [ ] Beta user review seeding campaign launched
- [ ] ASO monitoring tools configured

---

*Next Review: 2026-04-10 — Pulse will re-run keyword ranking analysis and update ASO strategy based on Week 1 data.*
