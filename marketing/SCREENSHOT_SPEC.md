# GigaRizz — App Store Screenshot Specification
## Complete Frame-by-Frame Creative Direction
**Version:** 1.0 | **Date:** 2026-04-03 | **Status:** Ready for execution

---

## OVERVIEW

GigaRizz's App Store presence must communicate: **premium, confident, flirty, AI-powered**.
The visual language is **dark-first** — deep charcoal backgrounds with flame-orange (#FF6B35) and gold (#FFE66D) accents.
Every frame should feel like it belongs in a premium dating app, not a photo filter tool.

**Design system reference:** `../SPEC.md` Section 2

---

## DEVICE FRAMEWORK

| Device | Dimensions | Frames | Purpose |
|--------|-----------|--------|---------|
| iPhone 16 Pro Max | 2556×1179 (status bar 90pt) | 5 | Primary listing — most prominent |
| iPhone SE (3rd gen) | 1334×750 | 5 | Budget/SE compatibility |
| iPad Pro 13" | 2048×2732 | 2 | iPad App Store |

**Status bar:** 9:41 AM, full signal (4 bars), WiFi, full battery  
**Insets:** Safe area respected; no important content within 60pt of edges

---

## iPHONE 16 PRO MAX — 5 FRAMES

### Frame 1: Hero — Before/After Comparison
**Purpose:** Instant value prop — show the transformation
**Headline:** "Your Dating Photos, Reimagined"  
**Subline:** "AI-generated. Platform-perfect. Ready to match."

**Layout (portrait, top → bottom):**
```
┌──────────────────────────────────────┐ 2556px wide
│ Status bar: 9:41 ···· WiFi 🔋100%    │ 90pt
├──────────────────────────────────────┤
│                                      │
│  ┌──────────────┐ ┌──────────────┐   │
│  │              │ │              │   │
│  │  BEFORE      │ │  AFTER 🏆   │   │
│  │  (blurry,    │ │  (GigaRizz   │   │
│  │  bad angle)  │ │   generated)  │   │
│  │              │ │              │   │
│  │   😬 4.2    │ │   🔥 9.1     │   │ ← Rizz Score badges
│  └──────────────┘ └──────────────┘   │
│                                      │
│  ← Before          After →           │  ← arrows
├──────────────────────────────────────┤
│  ┌─────────────────────────────────┐ │
│  │  Your Dating Photos,            │ │  ← Headline (34pt SF Pro Bold)
│  │  Reimagined                     │ │
│  └─────────────────────────────────┘ │
│  "AI-generated. Platform-perfect."  │  ← Subline (17pt SF Pro)
│                                      │
│  ┌─────────────────────────────────┐ │
│  │    ⭐⭐⭐⭐⭐  │ 4.9 · 2.3K    │ │  ← Social proof
│  └─────────────────────────────────┘ │
│                                      │
│  [   Get GigaRizz Plus — $4.99/mo   ]│  ← CTA button
│                                      │
│         ● ● ● ○ ○                   │  ← Page indicator (frame 1 of 5)
└──────────────────────────────────────┘
```

**Colors:**
- Background: `#0D0D14` (near black)
- Before photo: sepia/desaturated filter to convey "bad"
- After photo: vibrant, warm lighting, confident smile
- Score badge: `#FF6B35` (flame orange) with white text
- Headline: `#FFFFFF`, SF Pro Display Bold 34pt
- Subline: `#A0A0B0`, SF Pro Text 17pt
- CTA button: `#FF6B35` fill, white text, 56pt height, 16pt corner radius
- Page dot active: `#FF6B35`, inactive: `#3A3A4A`

**Typography:**
- Headlines: SF Pro Display Bold
- Body: SF Pro Text Regular
- Numbers/scores: SF Pro Rounded Semibold

**Animation hint (for App Preview):** Photos slide in from left/right with spring physics (0.5s, damping 0.7)

---

### Frame 2: Style Gallery — Photo Grid
**Purpose:** Showcase variety of AI styles
**Headline:** "10+ Styles. Infinite Possibilities."
**Subline:** "Cafe Warmth · Golden Hour · Urban Edge · Studio Professional"

**Layout:**
```
┌──────────────────────────────────────┐
│ Status bar                           │
├──────────────────────────────────────┤
│                                      │
│  10+ Styles. Infinite Possibilities. │  ← Headline
│                                      │
│  ┌────┐  ┌────┐  ┌────┐              │
│  │    │  │    │  │    │              │  ← 3-column grid
│  │ A  │  │ B  │  │ C  │              │
│  │    │  │    │  │    │              │
│  └──┬─┘  └──┬─┘  └──┬─┘              │
│     │       │       │                │
│  Cafe   Golden   Urban                │  ← Style labels (13pt, #A0A0B0)
│  Warmth  Hour   Edge                  │
│                                      │
│  ┌────┐  ┌────┐  ┌────┐              │
│  │    │  │    │  │    │              │
│  │ D  │  │ E  │  │ F  │              │
│  │    │  │    │  │    │              │
│  └──┬─┘  └──┬─┘  └──┬─┘              │
│     │       │       │                │
│ Studio  Rooftop  Sporty  …          │
│  Pro     Chic                   +4  │  ← "+4 more" chip
│                                      │
│  ─────────────────────────────────── │
│  "Swipe through your new look"       │
│                                      │
│         ● ● ○ ○ ○                   │
└──────────────────────────────────────┘
```

**Style photo requirements:**
- All 6+ photos must be of the SAME PERSON (consistent face across styles)
- Same person, different lighting/background/pose
- Neutral clothing (white/gray tee) so styles are the differentiator
- Genuine smile in all shots
- Photo quality: high-res, well-lit, professional

**Colors:**
- Grid background: `#1A1A2E` card with 12pt corner radius, 8pt padding
- Style label: `#A0A0B0` SF Pro Medium 13pt
- "+4 more" chip: `#FFE66D` with dark text

---

### Frame 3: Platform Optimization
**Purpose:** Show we optimize for Tinder, Hinge, Bumble
**Headline:** "Perfect Format for Every App"
**Subline:** "We deliver in 1:1, 4:5, and 9:16 — automatically."

**Layout:**
```
┌──────────────────────────────────────┐
│ Status bar                           │
├──────────────────────────────────────┤
│                                      │
│  Perfect Format for Every App        │
│  "We deliver in 1:1, 4:5, 9:16 —    │
│   automatically."                    │
│                                      │
│  ┌────────────────────────────────┐   │
│  │  ┌──────────────────────────┐ │   │
│  │  │   📱 Tinder              │ │   │  ← Platform badge
│  │  │   ┌────┐                 │ │   │
│  │  │   │    │  1:1 square     │ │   │
│  │  │   └────┘                 │ │   │
│  │  │   Optimized for          │ │   │
│  │  │   maximum visibility     │ │   │
│  │  └──────────────────────────┘ │   │
│  └────────────────────────────────┘   │
│                                      │
│  TINDER    HINGE    BUMBLE   MORE     │  ← Platform tabs
│                                      │
│         ● ● ● ○ ○                    │
└──────────────────────────────────────┘
```

**Key visual:** Each platform card shows the same photo cropped to that platform's ideal aspect ratio, with the platform logo badge.

---

### Frame 4: Rizz Coach Feature
**Purpose:** Show the AI intelligence / Rizz Coach
**Headline:** "Your AI Wingman, 24/7"
**Subline:** "Rizz Coach analyzes your photos and tells you exactly which one to lead with."

**Layout:**
```
┌──────────────────────────────────────┐
│ Status bar                           │
├──────────────────────────────────────┤
│                                      │
│  Your AI Wingman, 24/7              │
│                                      │
│  ┌────────────────────────────────┐   │
│  │  📊 Rizz Coach                │   │
│  │                                │   │
│  │  ┌────┐  Your Photo Score:    │   │
│  │  │ 👤 │  6.8 → ⚠️ Needs work  │   │
│  │  └────┘                        │   │
│  │                                │   │
│  │  💡 "Lead with this style.    │   │
│  │     Rizz Score: 9.1 🏆"         │   │
│  │                                │   │
│  │  ┌────┐ ┌────┐ ┌────┐          │   │
│  │  │    │ │ 🏆 │ │    │          │   │  ← Recommended photo highlighted
│  │  │ x  │ │ ✓  │ │ x  │          │   │
│  │  └────┘ └────┘ └────┘          │   │
│  │  Current  Best   Skip         │   │
│  └────────────────────────────────┘   │
│                                      │
│         ● ● ● ● ○                    │
└──────────────────────────────────────┘
```

**Colors:**
- Card background: `#1A1A2E`
- Rizz Score 9+: `#00C853` (green — positive)
- Rizz Score <7: `#FFB300` (gold — needs improvement)
- Recommended badge: `#FFE66D` (gold star)

---

### Frame 5: CTA — Subscription
**Purpose:** Convert browsers to subscribers
**Headline:** "Start Your Transformation Today"

**Layout:**
```
┌──────────────────────────────────────┐
│ Status bar                           │
├──────────────────────────────────────┤
│                                      │
│  Start Your Transformation Today     │
│                                      │
│  ┌────────────────────────────────┐   │
│  │  FREE                          │   │
│  │  ──────────                    │   │
│  │  3 generations/month           │   │
│  │  ✓                             │   │
│  └────────────────────────────────┘   │
│                                      │
│  ┌────────────────────────────────┐   │
│  │  ⭐ PLUS  $4.99/mo   MOST POPULAR│ │  ← Highlighted
│  │  ──────────                    │   │
│  │  ✓ Unlimited generations       │   │
│  │  ✓ All 10+ styles              │   │
│  │  ✓ All platforms               │   │
│  │  ✓ Face enhancement            │   │
│  │  ✓ Priority processing         │   │
│  │                                │   │
│  │  [   Get GigaRizz Plus   ]    │   │  ← CTA button
│  └────────────────────────────────┘   │
│                                      │
│  ┌────────────────────────────────┐   │
│  │  🌟 GOLD    $14.99/mo          │   │
│  │  ──────────                    │   │
│  │  Everything in Plus +          │   │
│  │  ✓ Rizz Coach AI               │   │
│  │  ✓ Exclusive styles            │   │
│  │  ✓ Priority support            │   │
│  └────────────────────────────────┘   │
│                                      │
│  "Cancel anytime. No commitment."   │
│                                      │
│         ● ● ● ● ●                    │
└──────────────────────────────────────┘
```

**Colors:**
- PLUS card: `#FF6B35` border (3pt), white background
- FREE/GOLD cards: `#1A1A2E` background, `#A0A0B0` text
- CTA button: `#FF6B35` fill, white bold text
- "Most Popular" badge: `#FFE66D` with dark text

---

## iPAD PRO 13" — 2 FRAMES

### Frame 1: Photo Gallery Hero (3-column)
**Dimensions:** 2048×2732 (portrait)
**Purpose:** Showcase the photo grid in iPad's larger canvas

**Layout (3-column iPad grid):**
```
┌────────────────────────────────────┐  2048px wide
│ Status bar: 9:41 ···· WiFi 🔋100% │  90pt
├────────────────────────────────────┤
│                                    │
│  Swipe Through Your New Look       │  ← Headline (34pt SF Pro Bold)
│  10+ AI styles. One tap away.     │  ← Subline (17pt)
│                                    │
│  ┌───────┐ ┌───────┐ ┌───────┐    │
│  │       │ │       │ │       │    │
│  │  A    │ │  B    │ │  C    │    │
│  │       │ │       │ │       │    │
│  │Cafe   │ │Golden │ │Urban  │    │
│  │Warmth │ │Hour   │ │Edge   │    │
│  └───────┘ └───────┘ └───────┘    │
│  ┌───────┐ ┌───────┐ ┌───────┐    │
│  │       │ │       │ │       │    │
│  │  D    │ │  E    │ │  F    │    │  ← 6 photos (2 rows × 3 columns)
│  │       │ │       │ │       │    │
│  │Studio │ │Rooftop│ │Sporty │    │
│  │Pro    │ │Chic   │ │       │    │
│  └───────┘ └───────┘ └───────┘    │
│                                    │
│  "Tap any style to preview"        │
│                                    │
│  ┌────────────────────────────────┐ │
│  │  ⭐⭐⭐⭐⭐  │ 4.9 · 2.3K ratings │ │
│  └────────────────────────────────┘ │
│                                    │
│  [    Get GigaRizz Plus — $4.99    ]│  ← CTA
│                                    │
│              ● ●                   │  ← Page indicator (frame 1 of 2)
└────────────────────────────────────┘
```

**Note:** iPad grid has more breathing room than iPhone. Use 24pt spacing between photos. Each photo card: 580×580px.

---

### Frame 2: Style Detail + CTA
**Dimensions:** 2048×2732 (portrait)
**Purpose:** Hero photo + style carousel + pricing + CTA

**Layout:**
```
┌────────────────────────────────────┐
│ Status bar                         │
├────────────────────────────────────┤
│                                    │
│  ┌────────────────────────────┐    │
│  │                            │    │
│  │                            │    │
│  │    HERO PHOTO              │    │  ← 1200×1200px centered
│  │    (selected style)        │    │
│  │                            │    │
│  │         🔥 9.1             │    │  ← Rizz score badge
│  └────────────────────────────┘    │
│                                    │
│  Style: Cafe Warmth                │  ← Style name (17pt, #A0A0B0)
│  ← ● ● ● ● ● ● ● →                │  ← Carousel dots (10 styles)
│                                    │
│  ┌────────────────────────────────┐ │
│  │  Compare Plans                │ │
│  │  ─────────────────────────── │ │
│  │  FREE  │  PLUS  │  GOLD      │ │
│  │  $0    │  $4.99 │  $14.99   │ │
│  │  3/mo  │  ∞     │  ∞ + AI   │ │
│  │  [Get] │ [★ Best]│  [Gold]  │ │
│  └────────────────────────────────┘ │
│                                    │
│  [     Get GigaRizz Plus — $4.99   ]│  ← Primary CTA (large, 64pt height)
│  "Cancel anytime · No commitment"  │
│                                    │
│              ● ●                   │
└────────────────────────────────────┘
```

---

## PRODUCTION NOTES

### Photo shoot / generation requirements
1. **Same model across ALL styles** — pick 1 person, shoot them 10× with consistent framing
2. **Natural, genuine expressions** — not model-perfect, relatable
3. **Consistent outfit** — white/gray tee for neutral base
4. **Varied backgrounds** — cafe, golden hour outdoors, urban wall, studio backdrop, rooftop, sports field
5. **Rizz Scores** — use consistent scale: 4.2-9.1 across before/after

### Frame compositing workflow
1. Generate/capture base photos
2. Add Rizz Score badges (Figma template with auto-layout)
3. Add typography overlays
4. Apply brand colors via Figma styles
5. Crop to exact dimensions
6. Export PNG (no alpha) at 2x resolution for Retina

### Screenshot export checklist
- [ ] iPhone 16 Pro Max: 2556×1179 (5 frames)
- [ ] iPhone SE: 1334×750 (5 frames)
- [ ] iPad Pro 13": 2048×2732 (2 frames)
- [ ] All status bars = 9:41 AM
- [ ] No device frames
- [ ] No alpha channel
- [ ] PNG format

---

## COMPETITOR SCREENSHOT REFERENCE

| Competitor | Frame Style | Strength | Weakness |
|-----------|------------|----------|----------|
| **Tonic** | Light mode, bright pastels | Friendly, approachable | Generic, no personality |
| **Zefplay** | Dark mode, neon accents | Viral/fun vibe | Too playful, not premium |
| **Rizz AI** | Chat UI screenshots | Shows features | No photo quality showcase |

**GigaRizz differentiator:** We are the PREMIUM midpoint — dark, confident, polished, but with warmth (flame orange) and personality (rizz scores). We look like the dating app you wish existed.
