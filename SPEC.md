# GigaRizz — Dating Photo Generator
## SPEC.md

> *Rizz your way to more matches. AI-powered photo generation, profile optimization, and dating assistant.*

---

## 1. Concept & Vision

**GigaRizz** is an AI-powered dating photo generator that transforms ordinary photos into magazine-quality dating app shots — no photographer required. The app analyzes a user's existing photos, generates stunning new ones using AI, writes Rizz-ready bios, coaches on opening lines, and acts as an always-available dating wingman. The soul: confident, flirty, evidence-backed (Tinder/Hinge optimization data), never cringe.

**Core differentiator**: We don't just optimize — we *generate* photos. One selfie → unlimited variations.

**Tagline**: *"Your AI dating photographer."*
**App Store Category**: Photo & Video / Lifestyle

---

## 2. Design Language

### Colors (Hex codes as Swift literals)
- Primary: `#FF6B35` (Flame Orange — warm, confident, flirty)
- Secondary: `#1A1A2E` (Deep Night — premium dark UI)
- Accent: `#FFE66D` (Gold Star — achievement, premium rewards)
- Background: `#0D0D14` (Near Black)
- Surface: `#1A1A2E`
- Text Primary: `#FFFFFF`
- Text Secondary: `#A0A0B0`
- Success/Match: `#00C853` (Rizz Green — new matches)
- Warning: `#FFB300` (Caution Gold)
- Error: `#FF3D71` (Alert Red)

### Typography (SF Pro + custom Rizz fonts)
- Headlines: SF Pro Display Bold, 28-34pt
- Body: SF Pro Text Regular, 16-17pt  
- Captions: SF Pro Text Medium, 13-14pt
- Buttons: SF Pro Semibold, 17pt
- Emojis: Native emoji rendering

### Spacing (4pt grid)
- Micro: 4pt
- XS: 8pt
- S: 12pt
- M: 16pt
- L: 24pt
- XL: 32pt
- XXL: 48pt

### Motion Philosophy
- **Photo generation**: Loading shimmer → reveal animation (400ms spring)
- **Match notifications**: Confetti burst + haptic burst
- **Tab switches**: 200ms ease-out
- **Cards**: 300ms spring(duration: 0.5, bounce: 0.3)
- **Success states**: Gold particle shower

### Haptics
- Light: `.impact(style: .light)` — button taps
- Medium: `.impact(style: .medium)` — photo generation complete
- Heavy: `.impact(style: .heavy)` — match/like sent
- Success: `.notification(type: .success)` — profile saved
- Warning: `.notification(type: .warning)` — unmatch detected
- Error: `.notification(type: .error)` — upload failed

---

## 3. Layout & Structure

### Tab Bar (4 tabs)
1. **Generate** (wand icon) — Photo generation
2. **Profile** (person icon) — Dating profile setup
3. **Coach** (brain icon) — Rizz GPT, openers, bio reviews
4. **Matches** (heart icon) — Inbox + match tracking

### Navigation
- NavigationStack per tab
- Sheet presentations for photo picker, generation settings
- Full screen cover for photo preview + share

---

## 4. Core Features

### F1: AI Photo Generation
- Pick 3-5 existing photos
- AI generates 8-12 variations (lighting, background, style, pose)
- Style presets: Confident, Adventurous, Mysterious, Sporty, Casual Chic
- Background replacer (cafe, rooftop, golden hour, studio, urban)
- Face enhancement (subtle — don't look filtered)
- Aspect ratios: 1:1 (Tinder), 4:5 (Hinge), 9:16 (Instagram Stories)

### F2: Rizz Coach
- Opening lines personalized to their profile
- Bio generator (3 tones: Flirty / Direct / Funny)
- Photo critique (what works, what kills matches)
- Conversation starters generated from profile cues

### F3: Profile Audit
- Photo scoring 1-10 on first impression
- Prompt user to replace weakest photo
- Track profile completion %

### F4: Match Reminders
- "Reply rate" tracker
- Gentle nudges to respond to stale matches

---

## 5. Technical

### Stack
- **iOS**: SwiftUI + Xcode 26+
- **Backend**: Firebase (Auth, Firestore, Storage)
- **AI**: Giphy/random API for demo, OpenAI for bio/Rizz generation
- **Analytics**: PostHog
- **Subscriptions**: RevenueCat

### Bundle ID
`com.gigarizz.app`
