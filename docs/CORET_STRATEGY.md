# CORET — Strategy & Positioning

Business strategy, brand positioning, and user-facing frameworks.
For product/implementation details, see [`CORET_V1_PRODUCT.md`](CORET_V1_PRODUCT.md).
For feature versioning and roadmap, see [`strategy/feature_roadmap_v1.md`](strategy/feature_roadmap_v1.md).

---

## Positioning

**Pitch:** "CORET shows how every garment strengthens or weakens your wardrobe."

**Analogy:** "Spotify for wardrobes" — people instantly understand it. Spotify maps your music identity; CORET maps your wardrobe identity.

**What CORET is:** A wardrobe intelligence system — not a digital closet.

**Strategic comparison:** Closer to Notion (structure), YNAB (control), Obsidian (system-thinking). Does NOT compete with Pinterest, Zara, or Instagram fashion culture.

---

## Core Philosophy — The Three C's

Every engine, every score, every recommendation in CORET traces back to three structural principles:

### 1. Coherence

Garments function as a system, not in isolation. A blazer isn't "good" or "bad" — it's coherent or incoherent with the rest of the wardrobe. CORET measures how well garments work together, not how they look individually.

**Engine expression:**
- CohesionEngine: 6-component scoring across the entire wardrobe
- ClarityEngine: identity coherence across archetypes
- IdentityResolver: "Structured · Warm" emerges from garment relationships, not tags

### 2. Coverage

A wardrobe must cover all structural layers and seasons. Gaps weaken the system. Coverage isn't about quantity — it's about structural completeness.

**Engine expression:**
- OptimizeEngineV2: gap detection (missing layers, missing categories)
- SeasonalEngineV2: seasonal coverage rings (høst/vinter/vår/sommer)
- ScoreProjector: "adding this fills layer:2" gap detection

### 3. Compatibility

Every garment either strengthens or weakens the whole. Compatibility is measurable, projectable, and actionable. "This coat opened 18 combinations" is a compatibility fact.

**Engine expression:**
- CohesionEngine.outfitStrength(): proportion + archetype + color harmony
- DailyOutfitScorer: per-outfit compatibility breakdown
- NetworkUnlockCalculator: "+N combinations" on garment add
- KeyGarmentResolver.connectedGarments(): which garments pair strongest

### How the Three C's map to tabs

| Tab | Primary C | What the user experiences |
|-----|-----------|--------------------------|
| Wardrobe | Coverage + Coherence | See what you have, Clarity score, identity in Profile |
| Studio | Compatibility | Build outfits, see live strength scoring |
| Discover | Compatibility | Swipe through outfits you can wear today |

---

## The 5 Wardrobe Rules

User-facing framework that explains engine results in plain language. The user learns style principles through their own wardrobe — not through articles or tips. Each rule maps to a specific engine score. No engine changes — ViewModel presentation only.

### 1. The Anchor Rule

*"A few key garments hold your wardrobe together."*

Some garments appear in far more outfits than others. These are structural anchors — removing one would collapse part of the network.

**Engine:** KeyGarmentResolver — garments at ≥20% of all combinations are anchors.
**UI text examples:**
- "Your brown coat is in 29% of all outfits. It's an anchor."
- "Removing this would break 14 combinations."

### 2. The Balance Rule

*"Contrast between upper and lower creates visual strength."*

Fitted top + relaxed bottom works. Oversized top + oversized bottom doesn't. Proportion balance is measurable.

**Engine:** CohesionEngine.proportionBalanceScore (weight 0.20) — via proportionScore(upper:lower:) silhouette matrix.
**UI text examples:**
- "Fitted shirt + regular chinos: strong balance."
- "Both oversized — consider a more fitted lower."

### 3. The Color Rule

*"Consistent temperature creates harmony."*

Mixing warm and cool tones in one outfit creates visual friction. Staying within one temperature — or using neutrals as bridges — creates coherence.

**Engine:** CohesionEngine.outfitColorHarmony() — warm + cool = 0.5 penalty, same temp = 1.0.
**UI text examples:**
- "This outfit mixes warm and cool — try a neutral shoe instead."
- "All warm tones — harmonious."

### 4. The Coverage Rule

*"A complete wardrobe has no structural gaps."*

Every category needs representation. Every layer (base, mid, outer) needs coverage. Missing a category doesn't just mean fewer clothes — it means fewer possible combinations.

**Engine:** CohesionEngine.layerCoverageScore (weight 0.25) + capsuleRatiosScore (weight 0.15).
**UI text examples:**
- "You have no mid-layer. Adding one would open 18 new outfits."
- "Upper/lower ratio is 3:1 — adding a bottom would balance the network."

### 5. The Network Rule

*"Each garment's value is measured by the combinations it creates."*

A garment isn't just an item — it's a node in a network. The more outfits it enables, the more structural value it has. Isolated garments weaken the system.

**Engine:** CohesionEngine.combinationDensityScore (weight 0.15) — strong outfits per garment.
**UI text examples:**
- "This coat enables 14 strong combinations — high network value."
- "This hoodie only works in 2 outfits — low network contribution."

### Rule-to-Engine Mapping

| Rule | Engine Function | CohesionEngine Weight |
|------|----------------|----------------------|
| Anchor | KeyGarmentResolver.role() | — (separate engine) |
| Balance | proportionBalanceScore | 0.20 |
| Color | outfitColorHarmony | via outfitStrength (0.25 internal) |
| Coverage | layerCoverageScore + capsuleRatiosScore | 0.25 + 0.15 |
| Network | combinationDensityScore | 0.15 |

---

## Viral Mechanics

Organic sharing driven by identity — not gamification. Spotify Wrapped analogy: people share who they are, not what they scored.

All mechanics consume existing engine data. No new engines required. Implementation is SwiftUI views with UIImage export (share sheet). Built in Xcode, not engine layer.

### 1. Wardrobe DNA Share Card (V1)

Generated image with the user's structural identity. CORET-branded, shareable to Instagram/TikTok/Twitter.

**Content:**
- Clarity score (from ClarityEngine)
- Dominant archetype + identity label (from IdentityResolver)
- Network strength: total combinations (from CohesionEngine.outfitCount)
- Strongest outfit (from BestOutfitFinder.findBest, top 1)
- X-Ray network visualization (already in Optimize moodboard)

**Implementation:** SwiftUI View → UIImage → UIActivityViewController. No engine changes.

### 2. Before/After Card (V1)

Auto-generated when a garment is added. Shows the structural ripple effect of that single addition.

**Content:**
- Clarity delta: "+N clarity" (from ScoreProjector.project.clarityDelta)
- Combinations gained: "+N new combinations" (from ScoreProjector.project.combinationsGained)
- Gaps filled (from ScoreProjector.project.gapsFilled)
- Top new outfit unlocked (from NetworkUnlockCalculator.calculateUnlocks.topNewOutfits)

**Implementation:** SwiftUI View → UIImage → share sheet. Triggered automatically on garment add. Engine data already available.

### 3. Outfit Share Card (V1)

Generated from Studio after building an outfit. The most shareable card — concrete and visual. "86 compatibility" is more interesting than just a photo of clothes.

**Content:**
- Garment list with thumbnails (the outfit)
- Compatibility score (from DailyOutfitScorer.totalStrength)
- Archetype match (from DailyOutfitScorer.archetypeMatch)
- 2–3 bullet points explaining why the outfit works:
  - Silhouette verdict: "Fitted upper + regular lower — balanced proportions" (from silhouetteVerdict)
  - Color verdict: "All warm tones — harmonious palette" (from colorVerdict)
  - Archetype: "Reinforces Smart Casual identity" (from archetypeMatch)

**Why it's the most shareable:** Wardrobe DNA is abstract. Before/After requires context. Outfit Card is immediate — people see clothes, a score, and a reason. It's the "here's what I'm wearing and here's why it works" moment.

**Implementation:** SwiftUI View → UIImage → share sheet. Share button in Studio after outfit is built. Engine data already computed by DailyOutfitScorer.scoreOutfit().

### 4. Wardrobe Wrapped (V1.5)

Annual/monthly summary of wardrobe evolution. The "year in review" moment.

**Content:**
- Clarity journey: start → end score over period
- Phase transitions (from MilestoneTracker)
- Garments added/removed count
- Identity shift: archetype distribution change
- Strongest outfit discovered
- Biggest single-garment impact

**Implementation:** Aggregates existing EvolutionSnapshots + MilestoneTracker data. SwiftUI views. Post-V1 launch.

### Design Constraints

- Cards must feel like structural identity, not achievement badges
- CORET branding: warm dark taupe, Instrument Serif, gold accent
- No social features, no follower counts, no likes
- User chooses to share — never prompted or nagged

---

## V1.5 Features — Image Intelligence

### Style Reference

User uploads a photo of an influencer, outfit inspiration, or style reference. CORET analyzes the image and compares it to the user's wardrobe.

**Flow:**
```
Profile → "Style Reference" → upload photo
                    ↓
CORET analyzes: silhouette pattern, color palette, archetype pattern
                    ↓
"This style is 78% Tailored, warm palette, fitted silhouettes"
                    ↓
Compare to user's wardrobe:
  "You're 37% Tailored. Gap: blazer, trousers, loafers."
  "Match: 42% — your coat and chinos already fit this direction."
```

**Requirements:** On-device vision model (Core ML) for silhouette/color detection. User always confirms analysis. Extends the V1 Style Direction (manual archetype selection) with image-based input.

### Find Similar

User takes a screenshot of a garment they like (from Instagram, a store, anywhere). CORET identifies the garment type and shows its structural impact.

**Flow:**
```
Camera/screenshot → CORET identifies: blazer, fitted, navy, cool tone
                    ↓
ScoreProjector.project() → "+14 clarity, +18 combinations, fills mid-layer gap"
                    ↓
Product search → similar items via backend product-search API
```

**Requirements:** On-device image classification (garment type + color). Backend `POST /api/product-search` already exists. ScoreProjector already computes hypothetical garment impact.

---

## V2+ Revenue Opportunities

Beyond subscription. Two engine-native revenue streams that no competitor can replicate — because they require the structural analysis layer.

### 1. Shopping Guidance (V2)

ScoreProjector already calculates the impact of a hypothetical garment. Connect that to real products via affiliate.

**User experience:**
```
Optimize tab → "A neutral mid-layer would add +14 clarity"
                                    ↓
                         [Show me options]
                                    ↓
              Affiliate results: blazers matching the structural role
              (category: upper, baseGroup: blazer, colorTemp: neutral)
                                    ↓
                    User buys → CORET earns affiliate fee
```

**Engine foundation:** `ScoreProjector.project(adding:to:profile:)` already returns clarityDelta, combinationsGained, gapsFilled for any hypothetical garment. The structural role description (category + baseGroup + colorTemp + silhouette) maps directly to product search filters.

**Not shopping recommendations.** CORET never says "buy this jacket." It says "a neutral structured mid-layer would strengthen your wardrobe by +14." The user decides if and where to buy.

### 2. Resale Pipeline (V2/V3)

OptimizeEngineV2 friction detection identifies garments that weaken the wardrobe. Turn that into a one-tap resale flow.

**User experience:**
```
Optimize tab → "These 3 garments weaken your network"
              → Garment detail → structural friction visible
                                    ↓
                              [Selg] (one tap)
                                    ↓
              CORET auto-generates listing:
              - Photo (from garment image in app)
              - Title (from Garment.name + baseGroup)
              - Category (from Garment.category)
              - Condition (user selects once)
                                    ↓
              Publishes directly to Tise / Finn.no via API
              User does one tap. CORET handles the rest.
```

**Engine foundation:** `OptimizeEngineV2` already identifies structural friction items. `ScoreProjector.reverseProject()` shows exact impact. `Garment` model already has name, category, baseGroup, image — everything needed for a listing.

**Unique angle:** No other wardrobe app can say "sell these 3 — they weaken your wardrobe structure." This is only possible with a structural scoring engine.

**Integration targets:** Tise (Norway), Finn.no (Norway), Vinted (EU), Depop (global).

### Revenue Model Summary

| Stream | Version | Engine Dependency | Revenue Type |
|--------|---------|------------------|-------------|
| Subscription | V1.5+ | All engines | SaaS ($9-12/mo) |
| Shopping Guidance | V2 | ScoreProjector | Affiliate commission |
| Resale Pipeline | V2/V3 | OptimizeEngineV2 + ScoreProjector | Transaction fee or referral |
| Discover Marketplace | V2/V3 | BestOutfitFinder + StyleDirectionEngine | Affiliate per purchase |

All four are engine-native. No competitor can copy them without building the structural analysis layer first.

### 3. Discover Marketplace (V2/V3)

V1 Discover is owned-garments only. No ghost cards, no product suggestions. Utforsk mode is V2+.

- **V1:** 100% owned outfits. No toggle. Gap analysis lives in Studio (ghost garments) and Garment Detail (friction).
- **V2:** "Utforsk" toggle added to Discover. Ghost outfits with 1-2 products from one partner (Zalando/H&M API). Price filter (budget/mid/premium). "Denne blazeren fra Zara, 799kr, gir deg 91 clarity."
- **V3:** Multi-brand catalog. Utforsk becomes full shopping inspiration feed — real products from all price classes styled with user's existing garments.
- **Revenue:** Affiliate/referral per purchase. Discover becomes the primary commerce channel.

---

## Stylist Mode (V3)

Stylists are a distribution channel, not a primary revenue source. But timing is critical — it requires proven retention with individual users first.

### Reality Check

1. **Most stylists work analog.** iPhone photos, WhatsApp, Pinterest boards, spreadsheets. They're not using structured tools. Adoption barrier is high — CORET must prove its value to stylists through their own wardrobe before they'll use it for clients.
2. **Multi-client is SaaS architecture, not an app feature.** Requires auth, multi-tenant data, client switching UI. That's a backend rewrite, not a feature toggle.
3. **Clients pay stylists to not think.** The flywheel (stylist → client → app) assumes clients want to self-manage after seeing a report. Many won't. The conversion rate is uncertain.
4. **The value is distribution, not subscription.** 1 stylist = 30 potential users. That's a growth lever, not a revenue line.

### Correct Sequencing

| Phase | Focus | Why |
|-------|-------|-----|
| V1 | Prove retention with individual users | If individuals don't return daily, stylists won't adopt |
| V1.5–V2 | Shopping guidance, resale pipeline, style direction | Revenue diversification + deeper engagement |
| V3 | Stylist Mode | Product is proven, infrastructure is ready |

### Features (When Ready)

| Feature | Engine Source | What the stylist gets |
|---------|-------------|---------------------|
| Multi-client switching | Separate wardrobe data per client | Switch between client profiles, each with full engine analysis |
| Shareable Clarity Report | ClarityEngine + IdentityResolver | PDF/image: Clarity score, archetype breakdown, identity profile |
| Shopping List with Impact | OptimizeEngineV2 + ScoreProjector | Auto-generated from gap analysis with projected impact |
| Stylist-branded Share Cards | Viral Mechanics cards | DNA Card, Outfit Card with stylist logo/name overlay |
| Client Progress Tracking | MilestoneTracker + ClarityEngine | "Client went from 42 → 78 Clarity over 3 months" |

### Architecture Note for V1

Don't hardcode 1 wardrobe per app. Use a `user_id` / `wardrobe_id` concept from the start even if V1 only ever has one. This keeps the door open for multi-tenant later without a data migration.

- SwiftData: `WardrobeItemEntity` should have a `wardrobeID: UUID` field (default to a single fixed UUID in V1)
- Backend: `garment_store` already keys by garment ID — adding a wardrobe_id filter is trivial
- Engine: already stateless — takes `[Garment]` as input, doesn't care where they came from

No implementation now. Strategic direction only.

---

## Visual System — Design Decisions

### One Visual Style Per Feed

Never mix image styles in the same scrollable feed. Discover shows one consistent visual treatment for all outfits. Breaking the visual rhythm breaks the swipe-trance.

- V1/V2: SVG silhouettes as prototype. Production uses real images (studio product images or user photos with bg remove)
- V3 Utforsk: retailer product images displayed in CORET's layout — brands adapt to CORET, not the other way around
- Ghost garments: same visual style as owned garments, but opacity 0.4 + subtle dashed outline. One label ("Mangler: Blazer"). No badge overload.

### Never Mix Inspiration and Commerce

Product details (price, buy link, retailer logo) are NEVER shown in the Discover feed. They appear only in a modal after the user taps a ghost garment.

**Why:** Product in feed → brain says "ad" → user builds resistance. Product after tap → brain says "discovery" → user feels in control.

```
Discover feed (clean, inspirational)
    ↓
User taps ghost garment (curious)
    ↓
Modal opens: product image, price, "Kjøp" link
    ↓
User chose to see this — it wasn't pushed on them
```

### Brands Adapt to CORET

In V3, retailer products are displayed using CORET's visual treatment — not the retailer's product page. CORET controls layout, typography, color grading. The product image is the only element from the retailer. This is what makes CORET a platform, not a marketplace widget.

---

## Data Model Forward-Compatibility

Fields added in V1 for future use (nil defaults, no engine impact):

- `UserProfile.height: Int?` — cm, for V2 body-aware proportionBalanceScore
- `UserProfile.build: String?` — e.g. "compact", "tall-slim", "athletic", for V2 silhouette matrix adjustment
- `wardrobeID: UUID` (planned for SwiftData entity) — single fixed value in V1, enables multi-tenant in V3

These cost nothing now and prevent data migrations later.

---

## What CORET Will Never Build

- No social feed
- No share outfits (sharing identity cards ≠ social feed)
- No "Outfit of the day"
- No trend analysis
- No Pinterest-style moodboards
- No influencer alignment
- No shopping recommendations (structural guidance ≠ shopping recs)
- No AI-generated styling text
- No gamification (streaks, achievements, badges)

These break the philosophical foundation. Non-negotiable.
