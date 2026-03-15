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
▦ Wardrobe  |  ✦ Studio  |  ◎ Optimize  |  ◈ Evolution
```

Profile → top-right menu icon (not a tab).
Dashboard content distributed: Clarity → Evolution, feed → Wardrobe hero block, gaps → Optimize.

---

## Design Principles

### One Hero Per Screen

Each tab has exactly one focal point. Everything else is secondary and either compact or expandable.

| Tab | Hero Element | Everything else |
|-----|-------------|----------------|
| Wardrobe | Garment grid | Hero block is compact summary above the grid |
| Studio | Outfit canvas | Feedback is a slim stripe, not a separate card |
| Optimize | Primary recommendation | Gap list and network graph are below the fold |
| Evolution | Clarity score | Identity, milestones, seasons build around it |

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
| 10 | **Gap analysis.** "You're missing a neutral mid-layer." Identity profile appears. | Optimize, Evolution | OptimizeEngineV2, IdentityResolver |
| 15 | **Network visualization.** X-Ray graph has enough nodes to be meaningful. | Optimize | CohesionEngine |
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

### Tap-to-Add, Not Drag-and-Drop

Studio uses tap-to-add as primary interaction. User taps a garment in the picker → it automatically fills the correct slot based on `garment.category` (upper → upper slot, lower → lower slot, shoes → shoes slot). Drag is secondary interaction, tap is primary.

**Why:** Tap is faster, works one-handed, has no learning curve. Drag requires precision and feels heavy on mobile.

**Implementation:** `garment.category` maps directly to slot type. If the slot is already filled, the new garment replaces it (with a brief swap animation). Tap the filled slot to remove.

---

## Optimize — Summary First, Network Last

Optimize opens with actionable information, not a visualization.

**Screen order (top to bottom):**
1. Summary numbers: Clarity score, combo count, gap count
2. Gap description: "2 strukturelle gap begrenser nettverket. Fyll dem for å nå 80+."
3. Gap cards with expandable suggestions and projected impact
4. Archetype breakdown (style profile)
5. X-Ray network graph (visual exploration, not hero)
6. Mini-legend: `● plagg · — kombinasjon · ◌ gap`
7. Strongest combinations grid

---

## Evolution — Progressive Disclosure

Evolution tab is progressive, not gated. Content reveals itself gradually based on data density — not time-based unlocks or paywalls. Empty states are motivating, not empty.

| Data threshold | What appears | Engine source |
|---------------|-------------|---------------|
| < 5 garments | Onboarding prompts: "Scan 5 plagg for din første score" | items.count |
| 5+ garments | Clarity score + progress bar | ClarityEngine.compute() |
| 10+ garments | Identity profile ("Structured · Warm") | IdentityResolver.resolve() |
| 3+ weeks | Milestone timeline | MilestoneTracker.milestones() |
| 2+ months (3+ snapshots) | Trend indicators (improving/stable/declining) | ClarityEngine trend from snapshots |
| 2+ what-if candidates | What-If Simulator | ScoreProjector.project() |
| 4 seasons covered | Seasonal coverage rings | SeasonalEngineV2 |

**Design principle:** Every empty state tells the user what's coming and how to get there. "Din stilprofil dukker opp etter 10 plagg" — not a blank card. The tab feels alive from day one.

**Not gamification:** Progressive disclosure is structural — more data enables more analysis. No artificial gates.

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
