# CORET – V1 Launch Scope Freeze

Dette dokumentet definerer nøyaktig hva som er inkludert i første publiserbare versjon av CORET.

Alt utenfor dette dokumentet er eksplisitt utsatt.
Ingen scope creep. Ingen "bare en liten ting til".

---

## Definisjon av V1

V1 skal:
- Være stabil
- Føles komplett
- Reflektere Wardrobe OS-visjonen
- Ha fungerende deterministisk motor
- Kunne brukes daglig

V1 skal IKKE:
- Være maksimal
- Være avansert
- Være "pro"

---

## MUST HAVE

### Engine
- CohesionEngine: Alignment, Density, Palette, Rotation, fast vekting, forklarbar scoring
- OptimizeEngine: Svakeste komponent, 1 primary + 2 secondary kandidater, removal kun ved sterk friksjon
- SeasonalEngine: Hemisfære-basert kalender, multiplikativ justering, manuell bekreftelse, ingen weather API
- StructuralEvolution: 5 faser, stabilitetskrav, volatility-modell, deterministisk narrativ

### Data & System
- WardrobeItem modell
- UserProfile
- CohesionSnapshot
- EvolutionSnapshot
- Engine recompute triggers

### UI
5-tab struktur: Dashboard, Wardrobe, Optimize, Evolution, Profile

Screens:
- Cohesion Score visning
- Component breakdown
- Optimize preview
- Evolution phase narrativ
- Wardrobe add/edit/delete

Brand design:
- Warm dark taupe (#2F2A26)
- Stone cards (#E7E2DA)
- Forest green accent (#2F4A3C)
- 200–300ms smooth transitions

### Interaction
Recompute ved: Item add, Item edit, Item delete, Archetype change, Seasonal recalibration
Ingen auto-AI. Ingen uforutsigbarhet.

---

## SHOULD HAVE (hvis tid og stabilitet tillater)
- Basic empty state illustrations
- Smooth score count-up animation
- Soft haptics
- Optimize explanation breakdown
- Component detail view

Hvis noe her skaper kompleksitet → fjernes.

---

## NOT ALLOWED IN V1
- Outfit generator
- Outfit synergy matrix
- ML / adaptive behavior
- Weather API
- Shopping / affiliate
- Budget tracking
- Social sharing
- Gamification, badges, streaks
- Push notifications
- Multi-profile support
- Roadmap Mode (Pro feature)
- Snapshot comparison

---

## Monetization Boundary

Gratis V1 inkluderer:
- Full CohesionEngine
- Basic Optimize
- StructuralEvolution
- SeasonalEngine

Pro aktiveres først i V1.5.
Ingen betalingsmur i første release.

---

## Scope Discipline Rule

Hvis en feature ikke direkte støtter:
"Measure and optimize wardrobe structure deterministically"
→ Den hører ikke hjemme i V1.

---

## V1 Definition of Done

V1 er ferdig når:
- Motor returnerer stabile og konsistente verdier
- Optimize gir meningsfulle strukturelle forslag
- Evolution fase endres korrekt
- UI føles rolig, solid og smooth
- Ingen engine-randomness
- Ingen uavklarte edge cases

---

## Endelig V1-Statement

CORET V1 er:
Et fullt fungerende Wardrobe Operating System
med deterministisk strukturmåling
og fremtidsrettet optimalisering.

Ingen distraksjon. Ingen gimmicks. Kun struktur.
