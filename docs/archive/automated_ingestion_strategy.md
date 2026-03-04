# CORET — Automated Purchase Ingestion (Strategic Archive Document)

Status: Strategic Reserve Initiative  
Priority: High (Deferred)  
Scope: Email-Based Import (V2) + Direct Retailer API (V3 Potential)  
Decision: Open Banking / Transaction Scraping Rejected  
Owner: Council (GPT + Claude AI + Claude Code + Sanzino)

---

## 1. Council Decision Summary

We formally decide:

- ❌ Open Banking / transaction data scraping will NOT be pursued.
- ❌ Plaid / Tink / banking integrations are removed from roadmap.
- ✅ Email-based order confirmation parsing remains viable.
- ✅ Direct retailer APIs remain a long-term V3 strategic opportunity.
- ✅ This idea is preserved as a future breadwinner system.
- ❌ Not a V1 implementation priority.

Reason:  
CORET requires structural garment-level data.  
Banking data only provides merchant-level metadata.  
Structural analysis requires product-level granularity.

---

## 2. Why This Idea Matters

If executed correctly, this becomes CORET's strongest retention engine.

It:

- Removes onboarding friction
- Grows wardrobe passively
- Feeds structural engine automatically
- Triggers recalculation events
- Creates ongoing analytical engagement
- Makes CORET feel alive

This is not a "shopping tool".  
This is a wardrobe ingestion system feeding structural analysis.

CORET does not encourage consumption.  
CORET structures what already exists.

---

## 3. V2 — Email-Based Import Layer

### 3.1 Architecture Overview

User connects:

- Gmail API (OAuth)
- Outlook API (OAuth)

System reads:

- Order confirmation emails
- Only from whitelisted senders
- Only structured purchase lines extracted

Extracted metadata:

- Product name
- Image URL (if present)
- Color (if specified)
- Brand
- Merchant
- Purchase date

No inbox indexing.  
No full email storage.  
No background scraping.  
Privacy-first by design.

### 3.2 ImportedItem Staging Model

Future model:

```swift
public struct ImportedItem {
    public let id: UUID
    public let rawProductName: String
    public let imageURL: URL?
    public let detectedColor: String?
    public let merchant: String
    public let purchaseDate: Date
    public let requiresConfirmation: Bool
}
```

Imported items:

- Do NOT auto-enter wardrobe
- Must go through user confirmation
- Must be classified structurally

### 3.3 Confirmation Flow (2-Tap Model)

For each detected item:

1. User confirms category:
   - Top
   - Bottom
   - Shoes
   - Outerwear

2. User confirms silhouette:
   - Structured
   - Balanced
   - Relaxed

Only after confirmation:  
→ Convert to WardrobeItem  
→ Trigger full engine recalculation

No automatic classification without confirmation.

### 3.4 Engine Trigger Behavior

On confirmed import:

- Recompute cohesionScore
- Recompute densityScore
- Recompute structuralIdentity
- Recompute outfitBuilder
- Recompute rotation

All deterministic.  
No asynchronous mutation.  
No probabilistic scoring.

---

## 4. Privacy & Trust Model

Non-negotiable principles:

- Explicit OAuth opt-in
- Explicit merchant whitelist
- No full email body storage
- No indexing unrelated emails
- No selling data
- Easy disconnect

Trust > growth.  
If trust breaks, CORET dies.

---

## 5. V2.5 — Image-Based Classification Suggestion (Claude AI Addendum)

### Context

When an order confirmation includes a product image URL, CORET could use on-device vision to *suggest* category and silhouette — pre-filling the confirmation flow.

### How it works

1. Email import detects product image URL
2. On-device image analysis suggests: category (Top/Bottom/Shoes/Outerwear) + silhouette (Structured/Balanced/Relaxed)
3. User sees pre-filled suggestion
4. User taps "Bekreft" (1 tap) or adjusts (2 taps)

### Friction reduction

- Current 2-tap model: user selects category + silhouette from scratch
- With image suggestion: user confirms or adjusts a pre-filled answer
- Most cases reduce to 1 tap

### Why this is V2.5, not V2

This introduces ML — on-device image classification.

CORET V1 and V2 are fully deterministic. No ML. No AI-generated classification.

Image-based suggestion is a probabilistic system. It does not belong in V2.

However, because:

- It runs on-device (no server dependency)
- The user always confirms (system never auto-classifies)
- It reduces friction without removing structural authority

It is a natural V2.5 evolution once the deterministic foundation is proven.

### Boundary

The suggestion is never authoritative.  
The user always decides.  
CORET suggests structure. The user confirms structure.

---

## 6. V3 — Direct Retailer API Potential

If V2 email ingestion proves product-market value:

Then pursue:

- Zalando Partner API (if accessible via negotiation)
- Direct merchant partnerships
- Structured purchase feeds

This requires:

- Business agreements
- Legal contracts
- Merchant alignment
- Scale validation

Retailer APIs provide:

- Structured SKU data
- Product taxonomy
- High-resolution imagery
- Accurate color data

This would eliminate parsing ambiguity.

But:  
This is V3-level infrastructure.  
Not viable before scale.

---

## 7. Why Open Banking Was Rejected

Open Banking provides:

- Merchant name
- Transaction amount
- Timestamp

It does NOT provide:

- Product identity
- Garment type
- Color
- Silhouette
- Structural metadata

It would still require manual classification.

Therefore:  
It adds complexity without solving friction.

Rejected permanently unless regulatory landscape changes.

---

## 8. Roadmap Positioning

| Version | Scope |
|---------|-------|
| V1 | Manual wardrobe only. Engine locking. Structural trust. Determinism. UI stabilization. |
| V2 | Email import (optional). Confirmation flow. Automatic recalculation. Passive wardrobe growth. |
| V2.5 | On-device image suggestion for imported items. Pre-filled confirmation. Friction → 1 tap. |
| V3 | Retailer API partnerships. Structured product ingestion. Direct SKU pipeline. |

---

## 9. Strategic Classification

This initiative is classified as:

- High-Value Retention Engine
- Structural Growth Layer
- Long-Term Differentiator

It is NOT:

- A shopping companion
- A deal tool
- A recommendation engine

It is:  
An ingestion layer feeding structural analysis.

---

## 10. CLAUDE.md Integration Directive

Add section:

```
## Future Systems — Automated Ingestion Layer
```

Include:

- Email parsing architecture (V2)
- Image-based suggestion layer (V2.5)
- Retailer API strategy (V3)
- Explicit rejection of Open Banking
- Privacy-first principles
- Confirmation model
- Engine trigger integration

Mark as:  
**Deferred — Strategic Breadwinner Candidate**

---

## 11. Council Lock

This idea is:

- Real
- Strategically powerful
- Technically feasible (V2)
- Friction-reducible (V2.5)
- Commercially scalable (V3)
- But not immediate priority

We:

- Document it.
- Preserve it.
- Revisit after V1 maturity.

Status: **Archived Strategic Initiative — Locked.**

---

*Council reviewed: GPT ✅ · Claude AI ✅ · Pending: Claude Code*  
*Last updated: 28 February 2026*
