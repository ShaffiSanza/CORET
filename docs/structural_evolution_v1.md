> SUPERSEDED – This document describes the original specification.
> The actual implementation differs. See CLAUDE.md section 7 for current truth.

# CORET – StructuralEvolution V1

## Purpose

StructuralEvolution tracks long-term structural development of the wardrobe.

It is NOT:
- A score graph
- A gamification layer
- A streak system
- A dopamine loop

It is a narrative structural maturity model.

It answers: "Where is my wardrobe in its structural development?"

---

## Core Concept

StructuralEvolution evaluates progression across time snapshots of Cohesion.

Based on:
- CohesionScore history
- Component stability
- Structural volatility
- Optimize adoption behavior

Does NOT depend on outfit frequency.
Depends on structural change.

---

## Key Distinction: Status vs Evolution

CohesionStatus = structural state (now)
StructuralEvolution = structural maturity (over time)

Status: reactive, snapshot-based, can change quickly
Evolution: time-based, requires stability, intentionally slower

Analogy:
- Status = pulse
- Evolution = physical fitness

You can have high pulse today.
That does not mean you are in peak condition.

---

## Evolution Phases

5 deterministic phases:

### 1. Structuring
Criteria:
- Total Cohesion < 55
OR
- Density < 45
OR
- High component volatility (>15 variance in 30 days)

Meaning: System is unstable or forming.

### 2. Refining
Criteria:
- Cohesion 55–69
AND
- At least 2 components above 60
AND
- Volatility decreasing

Meaning: System gaining shape but still inconsistent.

### 3. Coherent
Criteria:
- Cohesion 70–79
AND
- No component below 60
AND
- Volatility < 10 variance over 30 days

Meaning: System structurally balanced.

### 4. Aligned
Criteria:
- Cohesion 80–89
AND
- Alignment > 75
AND
- Density > 70
AND
- Stability maintained 60 days

Meaning: Identity and structure aligned.

### 5. Architected
Criteria:
- Cohesion >= 90
AND
- All components >= 80
AND
- Stability maintained 90 days
AND
- No structural friction events

Meaning: Fully architected wardrobe system.

---

## Volatility Model

volatility = standardDeviation(totalScore over last 30 days)

If insufficient data (<14 days): volatility ignored.

Volatility affects:
- Phase eligibility
- Regression logic

---

## Phase Transition Logic

### Upward Transition
Triggered only if:
- Phase criteria satisfied
- Stability window satisfied
- No major regression in last 14 days

Upgrade occurs immediately when criteria are met.

### Regression Logic
Triggers if:
- Cohesion drops >15 points
OR
- Any component drops below threshold for current phase
OR
- Volatility spikes >20

System regresses one phase.
Never drops more than one phase at once.

---

## Snapshot System

StructuralEvolution stores monthly snapshots.

EvolutionSnapshot fields:
- date
- totalScore
- alignment
- density
- palette
- rotation
- phase

Snapshots stored when:
- First day of each month
OR
- Major structural shift (>10 total score change)

---

## Narrative Output

StructuralEvolution never shows a raw progression graph.
Generates deterministic narrative states tied to phase.

Structuring: "Your system is forming. Structural gaps are still significant."
Refining: "Your wardrobe is stabilizing. Core identity emerging."
Coherent: "Structure is balanced. Your wardrobe supports itself."
Aligned: "Your identity and structure are aligned."
Architected: "Your wardrobe operates as a complete system."

No dynamic AI text.

---

## Edge Cases

### New User
If <14 days of data:
- Phase locked to Structuring
- Volatility ignored

### Massive Wardrobe Import
If >20 items added in 24h:
- Volatility suppressed for 7 days

### Seasonal Recalibration
Seasonal modifiers do NOT affect StructuralEvolution.
Evolution uses base (non-season-adjusted) Cohesion.

### Manual Profile Reset
If user creates new profile:
- Evolution resets
- Historical snapshots archived

---

## Determinism Guarantee

Given identical historical data: phase outcome must always be identical.
No ML. No probabilistic modeling. No gamification mechanics.

---

## Summary

StructuralEvolution is:
- A deterministic structural maturity tracker
- Based on measurable stability and component integrity
- Narrative-driven, not score-driven

It reflects structural growth, not engagement.
