# CORET V1 — Strategic Feature Roadmap

Status: Council Locked
Date: 1 March 2026
Approved by: GPT ✅ · Claude AI ✅ · Claude Code ✅
Purpose: Align the full team on feature scope, versioning, and engine implications before UI work begins.

> **Split docs:**
> - Strategy & positioning → [`../CORET_STRATEGY.md`](../CORET_STRATEGY.md)
> - Product & implementation → [`../CORET_V1_PRODUCT.md`](../CORET_V1_PRODUCT.md)
> - This file retains the council-locked feature decisions and roadmap.

---

## Strategic Direction

**C — Analyseplattform for personlig strukturell evolusjon.**

With A (struktur-verktøy) as foundation, and B (passiv bakgrunnsmotor) as V2/V3 distribution mode.

V1 proves: Structural analysis delivers value. Evolution can be tracked. The system is stable and comprehensible.

V1 does NOT prove: That it can style. That it needs AI. That it needs social features.

---

## Feature Decisions — Versioned

### V1 — Ships with launch

| Feature | Type | Engine Impact | Notes |
|---|---|---|---|
| Progressive Depth UX | Presentation | None — ViewModel logic | Use engine output as triggers (densityScore, volatility), not just items.count. Semantic, not hardcoded thresholds. |
| Dual-Layer Classification | Data model | `customLabels: [String]` on WardrobeItemEntity | Array, not single String — allows future predefined labels without schema migration. Labels do NOT affect engine scores. Filtering only. Lives on SwiftData entity, not engine WardrobeItem. |
| Structural Simulation Visual | UI (Optimize tab) | None — OptimizeEngine already provides data | Ghosted silhouette represents a **role** ("Relaxed mid-layer"), never a specific garment ("Grey hoodie"). Protects against becoming a styling app. |
| Local-First Positioning | Communication | None — SwiftData is already local-first | Marketing message: "CORET calculates locally. Your wardrobe is not stored on a styling server." |

### V1.5 — Post-launch iteration

| Feature | Type | Engine Impact | Notes |
|---|---|---|---|
| Comparative Archetype Lens | UI (Profile tab) | None — reuse `compute(items:profile:)` with alternate profile | Call it "Explore Structural Direction", not "Compare". Language matters. Consider testing as free feature before paywall. |
| Structural Drift Warning | Presentation + Engine extension | Minor — compare structuralIdentity across N snapshots + distribution ratios | Drift must be observational, never normative. "Silhouette distribution shifted 18% toward Structured over last 6 snapshots." Not: "You have become more structured." May need `structuralDistribution()` engine extension for percentage-based drift. |
| Snapshot Explainability | Presentation | None — data already exists | Show component-delta between snapshots: "Alignment +8, Density -3 since last snapshot." Reinforces the evolution vision. |
| iCloud Sync | Infrastructure | None — SwiftData supports this | Users who lose their phone lose their wardrobe without it. Plan for it, build after V1 stability. |

### V2 — Growth mode

| Feature | Type | Engine Impact | Notes |
|---|---|---|---|
| Email-Based Auto-Import | New ingestion layer | Engine must tolerate partial data | Gmail/Outlook OAuth. Whitelisted senders only. 2-tap confirmation (category + silhouette). Privacy-first. |
| Image-Based Classification Suggestion (V2.5) | ML layer | On-device vision suggests, user confirms | Introduces ML — breaks V1/V2 deterministic philosophy. Acceptable because user always confirms. |
| UGC as passive data in Studio | Presentation | None — aggregated wear-log display | "Worn by 12 wardrobes with similar Clarity." One line in Studio, not a feed. Requires backend auth + anonymised aggregation. |
| UGC injection in 70/30 feed | Feed extension | DailyOutfitScorer scores UGC outfits | Fifth card type in rhythm: owned→owned→owned→rotation→[community]. Only if thresholds met: ≥500 active users, ≥1000 logged outfits, avg UGC outfit score >70. NOT a separate modus — injected into existing feed. |

### V3 — Scale mode

| Feature | Type | Engine Impact | Notes |
|---|---|---|---|
| Retailer API Partnerships | Business + infrastructure | Structured SKU data eliminates parsing | Zalando, H&M, COS. Requires business agreements, legal contracts, scale validation. |
| Algorithmic Full Discover | Feed algorithm | BestOutfitFinder + BehaviouralEngine + UGC signals | Replaces brand-grid navigation with smart mixed feed. Brand-rom accessible via "Se mer fra [brand]". Only when enough brands + user data. |

---

## Discover Structure — Locked Decision (March 2026)

```
V1 (current):
├── 70/30: brukerens garderobe + ghost fra alle brands
└── Full: brand-rom (grid → én brands lifestyle-looks)

V1.5 (post-launch, med brukere):
└── UGC som passiv data i Studio: "Worn by 12 similar wardrobes"
    Ikke synlig som feed. Krever auth + anonymisert aggregering.

V2 (kun hvis thresholds nådd):
├── 70/30: owned → owned → owned → rotation → [community]
│   Community-kort kun hvis: ≥500 users, ≥1000 outfits, avg score >70
└── Full: brand-rom (uendret)

V3 (nok brands + data):
└── Full: algoritmisk feed erstatter brand-grid
    Brand-rom tilgjengelig via "Se mer fra [brand]"
```

**UGC policy:** CORET er et verktøy, ikke et sosialt nettverk. UGC er alltid engine-kuratert, anonymisert, og beslutningsstotte — aldri fritt postet innhold. Ingen Community-tab. Ingen Community-modus. UGC injiseres i eksisterende flyt kun nar signal quality rettferdiggjor det.

**Beslutning lokt av:** Claude Code, GPT, Claude AI — mars 2026.

---

## Engine Resilience Note (V2 Preparation)

When auto-import arrives, some items may have partial data:

- Missing silhouette
- Missing temperature
- Missing baseGroup

Engine must handle this gracefully. Not a V1 requirement, but the team should be aware that `WardrobeItem` may need optional structural fields in V2.

**Current V1 contract:** All fields are required. This is correct for V1 where all items are manually entered.

**V2 consideration:** Either enforce complete data at import confirmation (user must select all fields), or engine handles optionals. Decision deferred.

---

## Paywall Strategy

| Tier | Includes |
|---|---|
| **Free** | Full engine analysis, full wardrobe, 1 archetype pair, Progressive Depth UX, structural simulation |
| **Premium** | Comparative Archetype Lens (test free first), seasonal simulations, snapshot timeline history (older than 30 days), auto-import (V2), structural drift warnings |

Principle: Premium = deeper analysis. Not basic functionality.

Users should never feel locked out of understanding their wardrobe. They should feel invited to explore it further.

---

## What CORET Will Never Build

- No social feed (UGC is engine-curated decision support, never freely posted content)
- No share outfits publicly
- No trend analysis
- No Pinterest-style moodboards
- No influencer alignment
- No AI-generated styling text
- No gamification (streaks, achievements, badges)
- No Community tab or modus (UGC injected into existing feed only, if signal quality thresholds met)

**Clarified since V1 launch:**
- Brand partnerships (Shopify ghost-plagg) are structural gap-filling, not shopping recommendations
- Discover feed is engine-scored outfit presentation, not "Outfit of the day"
- UGC is anonymised aggregate data ("12 similar wardrobes wore this"), not user-generated content posting

These break the philosophical foundation. Non-negotiable.

---

## Claude Code — Integration Notes

No engine changes are required from this document. All features listed as V1 are either:

- ViewModel/presentation logic (Progressive Depth, Simulation Visual)
- Minor data model additions (customLabels on WardrobeItemEntity)
- Communication/positioning (Local-First)

For V1.5 features (Comparative Archetype, Structural Drift, Snapshot Explainability):

- Comparative Archetype requires NO new engine code — existing `compute()` with alternate profile
- Structural Drift requires a minor EvolutionEngine extension — compare structuralIdentity across snapshots, plus potential `structuralDistribution()` for percentage-based drift reporting
- Snapshot Explainability requires NO new engine code — component deltas from existing snapshot data

None of these block V1 launch. All are post-launch iterations.

`customLabels: [String]` should be added to `WardrobeItemEntity` in the SwiftData model spec when convenient. It lives on the persistence layer only — engine `WardrobeItem` remains unchanged.

---

*Council locked. Filed in `docs/strategy/`.*
*Last updated: 22 March 2026*
