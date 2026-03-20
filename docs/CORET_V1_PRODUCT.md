# CORET V1 — Product & Implementation

Product decisions, UX patterns, and implementation details for V1.
For business strategy and positioning, see [`CORET_STRATEGY.md`](CORET_STRATEGY.md).
For feature versioning and roadmap, see [`strategy/feature_roadmap_v1.md`](strategy/feature_roadmap_v1.md).

---

## V1 — The 7 Functions

What the user can do in V1. Each maps to existing engine output.

| # | Function | Tab | Engine |
|---|----------|-----|--------|
| 1 | See wardrobe structure (Clarity score, identity, coverage) | Wardrobe + Evolution | ClarityEngine, IdentityResolver |
| 2 | Build and score outfits in real-time | Studio | DailyOutfitScorer, CohesionEngine |
| 3 | Discover strongest outfit combinations | Studio | BestOutfitFinder |
| 4 | See structural gaps and what to add | Optimize | OptimizeEngineV2, ScoreProjector |
| 5 | Track wardrobe evolution over time | Evolution | MilestoneTracker, ClarityEngine |
| 6 | See each garment's structural role | Wardrobe detail | KeyGarmentResolver |
| 7 | Simulate adding/removing garments | Optimize + Detail | ScoreProjector, NetworkUnlockCalculator |

---

## 4 Tabs

```
▦ Wardrobe  |  ✦ Studio  |  🔍 Discover
```

Profile → top-right menu icon (not a tab).
3 tabs only. Evolution removed — too analytical for daily use. Content redistributed:
- Clarity score → Wardrobe hero block
- Identity profile → Profile menu
- Milestones → toast notifications on achievement
- Seasonal coverage → Profile menu
- What-if simulator → Studio ghost garments

---

## Design Principles

### One Hero Per Screen

Each tab has exactly one focal point. Everything else is secondary and either compact or expandable.

| Tab | Hero Element | Everything else |
|-----|-------------|----------------|
| Wardrobe | Garment grid | Hero block (Clarity + outfit + gap) is compact above the grid |
| Studio | Outfit canvas | Feedback is a slim stripe, not a separate card |
| Discover | Today's outfit | Swipe feed with owned outfits and rotation tips |

### Sub-Scores Are Hidden by Default

The user sees **"Clarity 78 · Fokusert"** — one number, one word. The 6 CohesionEngine sub-components (layerCoverage, proportionBalance, thirdPiece, capsuleRatios, combinationDensity, standaloneQuality) are not shown unless the user taps "Se detaljer."

**Why:** Most users don't need to know that proportionBalance is 0.72. They need to know their wardrobe is "Fokusert" and improving. The detail view exists for power users who want to understand _why_ their score moved.

**Implementation:** Clarity card has a discrete expand chevron. Tap → slides down sub-score breakdown. Collapsed by default. Same pattern on garment detail (archetype contribution bars hidden until tapped).

### Progressive Value Delivery — Outfit First, Analysis Later

The entire app follows one rule: **show the user something useful immediately, add analysis as data grows.** This applies to all tabs, not just Evolution.

| Garments | What unlocks | Where | Engine |
|----------|-------------|-------|--------|
| 1–2 | Garment grid only. "Add 1 more to see your first outfit." | Wardrobe | — |
| 3 | **First outfit.** "Here's a combination you can make." | Wardrobe hero, Studio | BestOutfitFinder |
| 5 | **Clarity score appears.** "Your wardrobe has a strong base." | Wardrobe hero, Evolution | ClarityEngine |
| 7 | **Outfit scoring active.** Studio feedback card lights up. | Studio | DailyOutfitScorer |
| 10 | **Gap analysis.** Ghost outfits appear in Discover feed. Identity profile appears. | Discover, Evolution | OptimizeEngineV2, IdentityResolver |
| 15 | **Full Discover feed.** Enough garments for meaningful outfit variety. | Discover | BestOutfitFinder, CohesionEngine |
| 20+ | **Full analysis.** Archetype breakdown, seasonal coverage, what-if simulator, all unlocked. | All tabs | All engines |

**The key insight:** At 3 garments the user already gets value (an outfit). They don't need to add 20 items before the app "works." Every milestone between 3 and 20 reveals something new — creating a natural pull to add more garments.

**Implementation:** ViewModel checks `items.count` at each threshold and conditionally renders sections. No engine changes — engines already handle small inputs gracefully (return 0 or defaults for insufficient data). This is purely presentation logic.

**Not gamification:** There are no "level up" notifications. Sections simply appear when they become meaningful. The user discovers them organically.

---

## Wardrobe — Home Screen with Hero Block

Wardrobe tab opens with a hero block at the top — not just the garment grid. This replaces the need for a separate Dashboard tab.

**Hero block content:**

| Element | Engine Source | What the user sees |
|---------|-------------|-------------------|
| Clarity score + status label | ClarityEngine.compute() | "78 — Fokusert" |
| Best Outfit Today | BestOutfitFinder.findUntriedBest(count: 1) | Strongest untried combination with garment thumbnails |
| One Optimization | OptimizeEngineV2 primary gap | "Legg til en blazer → +13 clarity" with tap to expand |

**Below hero:** Filter bar → garment grid (existing layout).

**Scroll behavior:** Hero block is a sticky/collapsible header. Collapses to a compact Clarity chip on scroll-down, expands on scroll-to-top. All data comes from existing engines — no new computation.

---

## Studio — Wardrobe Simulation

Studio is wardrobe simulation, not just outfit suggestion. The user doesn't just see a score — they see how the outfit affects the entire wardrobe: connected garments, new variations, swap impact.

**What Studio shows for a single outfit:**

| Layer | Engine Source | What the user sees |
|-------|-------------|-------------------|
| Outfit strength | DailyOutfitScorer.scoreOutfit() | Compatibility score + silhouette/color verdicts |
| Archetype alignment | CohesionEngine.allArchetypeScores() | Which archetype this outfit reinforces |
| Connected garments | ScoringHelpers.generateOutfits() | Other outfits these garments participate in |
| Swap impact | DailyOutfitScorer.suggestion | "Replace hoodie with blazer → +12 compatibility" |
| Network effect | NetworkUnlockCalculator | How this outfit's garments connect to the rest |
| Best untried | BestOutfitFinder.findUntriedBest() | Strongest combination the user hasn't worn |

Studio is the only place where the user interacts with the engine in real-time. Every other tab shows computed state. Studio shows live structural simulation.

### Swipe Flatlay System

Studio uses horizontal swipe rows — one per category (outer 140px, upper 90px, lower 150px, shoes 80px) stacked vertically with -14px overlap. User swipes to pick garments. Each swipe recalculates score live.

- **Active item:** scale 1.0, opacity 1.0
- **Inactive:** scale 0.92, opacity 0.6
- **During swipe:** other rows dim to opacity 0.45
- **Snap:** spring(response: 0.4, dampingFraction: 0.85)
- **Haptic:** UIImpactFeedbackGenerator(style: .light) on snap
- **Dynamic background:** blends dominantColor from all 4 selected garments via HSL averaging, 1.8s transition

### Studio → Wardrobe Outfit Flow

When user taps "Bruk i dag" in Studio:

1. **Save outfit:** Create SavedOutfitEntity with garment IDs from the 4 selected garments + auto-generated name (from IdentityResolver archetype + weekday, e.g. "Smart Casual · Tirsdag")
2. **Log wear:** WearLog entry for each garment via EngineCoordinator
3. **Confirm:** Checkmark fade animation (0.4s)
4. **Wardrobe sync:** Outfit appears in Wardrobe "Outfits" tab

**Wardrobe Outfits tab displays:**
- Horizontal scroll with outfit cards (garment silhouettes stacked vertically, dynamic background from dominantColor blending — same visual language as Studio)
- Outfit name + Clarity score + wear count
- Tap outfit → loads garments back into Studio swipe rows for replay/editing

**Garment Detail "Inngår i":** Shows all SavedOutfitEntities containing this garment. Tap → opens outfit in Studio.

### Ghost Garments — Explore Mode

Toggle "Utforsk" pill next to Surprise button. When active:

1. `OptimizeEngineV2.detectGaps()` runs
2. For each gap category: inject a ghost garment as last item in that SwipeRow
3. **Ghost visual:** Same silhouette shape but opacity 0.35, dashed border (2px, gold-dim), label "Mangler: Blazer" below
4. **Swipe to ghost:** `ScoreProjector.project()` runs, insight line shows "+13 clarity · +18 kombinasjoner"
5. **Background:** Ghost garment's assumed color (from gap suggestion colorTemp) included in HSL blend
6. **CTA changes:** "Bruk i dag" → "Legg til garderobe" → opens AddGarmentSheet pre-filled with gap suggestion's category and baseGroup

**Why this works:** User discovers wardrobe gaps while trying outfits, not in an abstract analysis tab. "There's no good outer option here... oh, a blazer would give 91 clarity." Optimize baked into the Studio experience.

| Mode | Available garments | CTA |
|------|-------------------|-----|
| Build (default) | Only owned garments | "Bruk i dag" → save + log wear |
| Explore | Owned + ghost garments from gaps | "Legg til garderobe" → add garment sheet |

All via EngineCoordinator. No direct engine calls from Views.

---

## Discover — Outfit Discovery Feed

Full-screen swipe feed. Tinder-style UX for outfit discovery. Replaces Optimize tab.

### V1: Only Owned Garments

Discover in V1 shows **only outfits from garments the user owns**. No ghost garments, no Utforsk toggle, no product suggestions. 100% positive — every outfit is something you can wear today.

Gap analysis lives elsewhere: Garment Detail (removal simulation) and Studio (ghost garments in Explore mode).

### Card Anatomy

```
Full-screen Outfit Card (swipe up for next)
├── Dynamic background (HSL blend of all garment colors, ambient blobs)
├── Bookmark icon (top-right, ☆ → ★ on save)
├── First card: "Anbefalt i dag" label (gold)
├── Stacked garments (4 layers, descending scale 1.0→0.96→0.92→0.88)
│   └── Each garment: ♡ like button (left) + "Name · Brand" label (right, 9px, opacity 0.25)
├── Outfit name (Instrument Serif italic)
├── Outfit Match score + feed-type badge
├── "Åpne i Studio" CTA
└── Swipe hint (first card only)
```

### Feed Algorithm

**Fixed rhythm (not random):**
- Pattern: owned-owned-owned-rotation (repeating)
- Rotation = outfit featuring an underused garment (`BehaviouralEngine.unusedRisk() >= 0.5`), badge: "Ikke brukt på X dager"
- First card always: `BestOutfitFinder.findUntriedBest()` → "Anbefalt i dag"
- Score label: "Outfit Match" (not "Clarity" — Clarity is a wardrobe metric, not an outfit metric)

**Max 20 outfits per session.** After card 20: "Du har sett alle forslag. Legg til flere plagg for nye kombinasjoner." This is honest and drives wardrobe growth.

**Gestures:**
- Swipe up: next card
- Swipe right: save/bookmark outfit (SavedOutfitEntity without wear log)
- Bookmark icon (top-right): alternative to swipe-right for save
- No "Neste" button — swipe only. Onboarding hint shown once on first card.

### Like Individual Garments

Each garment in the stack has a heart button. Tap → gold pulse animation (0.3s scale overshoot). Sets `garment.isFavorite = true`.

### Like Individual Garments

Each garment in the stack has a heart button. Tap → gold pulse animation (0.3s scale overshoot). Sets `garment.isFavorite = true`. Liked non-owned garments (in Utforsk mode) feed into V2 shopping guidance.

### Where Optimize Content Lives Now

| Old Optimize Feature | New Location |
|---------------------|-------------|
| Gap analysis | Studio ghost garments (Explore mode) + Garment Detail |
| Primary recommendation | Discover first card ("Anbefalt i dag") |
| Structural friction | Garment Detail (removal simulation — already built) |
| Network graph | Evolution tab or Profile (V1.5) |
| Archetype breakdown | Evolution identity section (already built) |

---

## Garment Aging

Garments evolve over time based on `dateAdded` and wear frequency (BehaviouralEngine).

| Status | Criteria | UI Treatment |
|--------|----------|-------------|
| **Pillar** | ≥ 20% of combinations + regular wear | ★ badge, gold accent, prominent in grid |
| **Wildcard** | Low combination count but recent wear | Neutral, no special treatment |
| **Dormant** | No wear in 60+ days, low combination count | Dimmed in grid, surfaced in Optimize as friction |

**Engine sources:**
- Pillar: KeyGarmentResolver.isKeyGarment + BehaviouralEngine wear frequency
- Dormant: BehaviouralEngine.lastWornDate + KeyGarmentResolver.combinationPercentage
- No new engine — ViewModel combines existing data

---

## Daily Outfit Engine — "What Should I Wear Today?"

The single most important feature for retention. When the user opens CORET each morning, they see one unified recommendation. This is what makes CORET a daily tool, not a wardrobe archive.

**Engine:** `DailyOutfitEngine.recommend()` — one function, one result.

**What it returns (DailyRecommendation):**

| Field | Source | What the user sees |
|-------|--------|-------------------|
| outfit | BestOutfitFinder.findUntriedBest() | "Navy shirt + Chinos + Loafers" with thumbnails |
| score | DailyOutfitScorer.scoreOutfit() | "Compatibility: 88%" + verdicts |
| rotationTips | BehaviouralEngine.unusedRisk() | "You haven't worn your bomber in 14 days" |
| clarityScore + band | ClarityEngine.compute() | "78 · Fokusert" |
| primaryGap | Gap detection | "Missing mid-layer — a blazer would add structure" |

**The daily loop:**
```
Open app (morning)
    ↓
See today's outfit recommendation
    ↓
Wear it (or swap pieces in Studio)
    ↓
Log wear (one tap)
    ↓
BehaviouralEngine learns preferences
    ↓
Better recommendation tomorrow
```

**Implementation:** Already built as `DailyOutfitEngine.swift` (13 tests passing). Wardrobe hero block displays the result. No new engines needed — wraps existing BestOutfitFinder, DailyOutfitScorer, BehaviouralEngine, and ClarityEngine.

---

## V1 Engagement Mechanisms

Three mechanisms drive daily engagement. All implemented as engine-layer wrappers. No new scoring logic.

### 1. Daily Outfit Score

User logs today's outfit → `DailyOutfitScorer.scoreOutfit()` → structural feedback.

- **Output:** OutfitScore with totalStrength, silhouetteVerdict, colorVerdict, archetypeMatch, suggestion
- **Where:** Studio tab, after saving an outfit
- **Not gamification:** No streaks, no daily reminders. User-initiated.

### 2. Best Outfit Discovery

Studio surfaces the strongest combination the user hasn't tried yet.

- **Function:** `BestOutfitFinder.findUntriedBest()`
- **Output:** [RankedOutfit] with garments, strength, archetypeMatch, auto-generated label
- **Value:** Reveals hidden structural potential in what the user already owns.

### 3. Network Unlocks

When a garment is added: "+N new combinations unlocked."

- **Function:** `NetworkUnlockCalculator.calculateUnlocks()`
- **Output:** UnlockResult with newCombinationCount, topNewOutfits (best 3), gapsFilled
- **Value:** Makes the network effect of each garment tangible and immediate.

### Engine Mapping

| Mechanism | Engine File | Function | Wraps |
|-----------|------------|----------|-------|
| Daily Outfit Score | DailyOutfitScorer.swift | scoreOutfit() | outfitStrength, proportionScore, allArchetypeScores |
| Best Outfit Discovery | BestOutfitFinder.swift | findBest(), findUntriedBest() | generateOutfits, outfitStrength |
| Network Unlocks | NetworkUnlockCalculator.swift | calculateUnlocks() | generateOutfits, ScoreProjector.project |

---

## Onboarding — 3 Seconds Per Garment

The #1 reason wardrobe apps fail: input takes too long. CORET target: **3 seconds per garment**.

**Flow:**
```
📸 Camera → auto-detect category → 2 questions (baseGroup + silhouette) → done
```

**How to achieve 3 seconds:**
1. Camera captures garment photo
2. Backend pipeline: image_normalize → color_extraction → auto-suggest category
3. User confirms category (1 tap) — smart defaults filter baseGroup options
4. User selects baseGroup (1 tap) — e.g., shoes → only sneakers/boots/loafers/sandals shown
5. Silhouette auto-defaults to `.regular` (can override)
6. Done. Garment saved.

**Backend support (already built):**
- `POST /api/garments/{id}/image` → image pipeline
- `POST /api/extract-colors` → dominantColor + colorTemp
- `POST /api/barcode-lookup` → auto-fill from product database
- `POST /api/product-metadata` → name, category from product data

**5 garments in under 1 minute** → first Clarity score → immediate value.

---

## Garment Image Priority

Always use the best available image. Ranked fallback system:

| Priority | Method | Image Quality | V1? |
|----------|--------|--------------|-----|
| 1 | **Text search** "merke + type" → `product_search` | Studio product image | V1 primary |
| 2 | **Own photo** → camera → `image_polish` (bg remove) | User photo, bg removed | V1 fallback |
| 3 | **Barcode scan** → `barcode_lookup` | Studio product image | V1.5 |
| 4 | **Image search** → ML match against catalog | Studio product image | V2 |
| 5 | **Email receipts** → auto-import from order confirmations | Studio product image | V2 |
| 6 | **SVG silhouette** with dominantColor | Generated shape | Last resort |

**V1 onboarding flow:**
```
"Søk etter plagget" → user types "Zara navy blazer"
    ↓
product_search returns studio image + brand + title
    ↓
User confirms with one tap → garment saved with studio image
    ↓
Not found? → "Ta bilde selv" → camera → bg remove
```

**Studio images are used everywhere:** Wardrobe grid, Discover feed, Studio, Garment Detail. If `product_search` finds a match later for a garment that has a user photo, the studio image replaces it automatically.

**Why text search is primary over camera:** Most people remember "H&M black tee" or "Zara navy blazer." Text search gives studio-quality images in 5 seconds. Camera requires good lighting, flat surface, and produces variable quality.

---

## Accessories — V1.5

Not in V1. Focus is upper + lower + shoes. `Category.accessory` exists in the data model but is not used in outfit generation.

**V1.5 plan:**
- Accessories added to wardrobe like any garment
- NOT included in combinatorial outfit generation (avoids explosion: 27 outfits → 432)
- Instead: shown as "styling suggestions" per outfit — "Add: watch, ring, scarf"
- BehaviouralEngine tracks which accessories pair with which outfits → learns patterns

---

## Style Direction (V1)

User chooses a target archetype they want to move toward: Tailored, Smart Casual, or Street. CORET shows current match percentage and a concrete gap list to reach the target.

**Flow:**
```
Profile menu → "Style Direction" → select target: Tailored
                    ↓
"You are 37% Tailored now."
                    ↓
Gap list:
  → Add blazer (+12% Tailored)
  → Add trousers (+8% Tailored)
  → Add loafers (+6% Tailored)
                    ↓
"Reaching 65% Tailored is achievable with 3 additions."
```

**Engine:** `CohesionEngine.allArchetypeScores()` for current match. `OptimizeEngineV2` gap detection with target archetype as filter — surface garments that specifically boost the target archetype's affinity score.

**Implementation:** `StyleDirectionEngine.analyzeDirection()` — new engine wrapper. Takes current items, profile, and target archetype. Returns current %, projected % after each suggested addition, and gap list. Profile menu is the natural placement.

**No image analysis.** User picks from 3 archetypes manually. V1.5 adds image-based style reference (see CORET_STRATEGY.md).

---

## Weather-Aware Outfit Suggestion (V1.5)

BestOutfitFinder filters outfits based on today's weather (temperature + precipitation from weather API). SeasonalEngineV2 already maps garments to seasons. Connect season mapping to live weather for contextual daily recommendations.

**Flow:**
```
Weather API → current temp + conditions
                    ↓
SeasonalEngineV2 → which garments suit this weather
                    ↓
BestOutfitFinder.findUntriedBest() → filtered to weather-appropriate garments
                    ↓
Wardrobe hero block → "Best outfit for today (12°C, rain)"
```

**Requirements:**
- Location access (Core Location, user-granted)
- Weather API (WeatherKit or OpenWeatherMap)
- SeasonalEngineV2 already assigns season coverage per garment — map temperature ranges to seasons

**Engine impact:** Minor — BestOutfitFinder needs a pre-filter step for weather-appropriate garments. SeasonalEngineV2 season mapping already exists. No new engine, just a filtered input set.

**Not V1:** Requires location permission and API key. Documented for V1.5 implementation.

---

## Body-Aware Scoring (V2)

User enters height and build in Profile menu. `proportionBalanceScore()` adjusts based on body type — different builds have different ideal silhouette pairings.

**Examples:**
- Compact + muscular: `fitted + tapered` scores higher (elongates silhouette)
- Tall + slim: `relaxed + wide` scores higher (adds visual weight)
- Athletic: `fitted + regular` scores higher (follows natural proportions)

**Language rule:** Never negative about body. Always proportion-balance terminology.
- Never: "Your body doesn't suit this."
- Always: "This combination gives better proportion balance for your frame."

**Engine:** `proportionBalanceScore()` gains an optional `UserProfile` parameter. If `height` and `build` are present, the silhouette matrix adjusts weights. If nil, falls back to the universal matrix (current V1 behavior).

**Data model:** `UserProfile.height: Int?` and `UserProfile.build: String?` already added in V1 (default nil, unused by engines). No migration needed in V2.

---

## Feature Decision Tables

*(Preserved from council-locked roadmap — see `strategy/feature_roadmap_v1.md` for full context)*

### V1 — Ships with launch

| Feature | Type | Engine Impact |
|---|---|---|
| Progressive Depth UX | Presentation | None — ViewModel logic |
| Dual-Layer Classification | Data model | `customLabels: [String]` on entity |
| Structural Simulation Visual | UI (Optimize) | None — engine data exists |
| Local-First Positioning | Communication | None — SwiftData is local |

### V1.5 — Post-launch

| Feature | Type | Engine Impact |
|---|---|---|
| Comparative Archetype Lens | UI (Profile) | None — reuse compute() |
| Structural Drift Warning | Presentation | Minor — snapshot comparison |
| Snapshot Explainability | Presentation | None — delta from snapshots |
| iCloud Sync | Infrastructure | None — SwiftData supports it |
