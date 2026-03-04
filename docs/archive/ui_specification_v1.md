# CORET – UI Specification V1

## Design Philosophy

CORET UI must feel:
- Calm
- Architectural
- Premium
- Gender-neutral
- Intentional
- Controlled
- Satisfying to open

It must NOT feel:
- Gamified
- Playful
- Trendy
- Busy
- Tech-startup flashy
- Social-media driven

CORET is a system interface, not a fashion app.
Every screen must communicate structural clarity.

---

## Color System

### Background (Primary)
Warm Dark Taupe: #2F2A26
Usage: App background, root canvas
Effect: Grounded, calm, architectural

### Card Surface (Secondary)
Light Stone: #E7E2DA
Usage: Cards, panels, containers
Effect: Contrast without harsh white. Premium and warm.

### Accent (Action / Active State)
Deep Muted Forest Green: #2F4A3C
Usage: Primary buttons, active tab indicator, highlighted values, positive structural signals
Effect: Controlled strength, not flashy

### Negative / Friction
Desaturated Deep Red: #7A3E3E
Used only for: Structural friction alerts, destructive actions
Never bright red.

### Text Colors
- Primary text (on light surface): #1F1C1A
- Secondary text: #6B625C
- Muted metadata: #9A918A
- Text on dark background: #EAE5DE

---

## Typography

Font Style: System Sans Serif (SF Pro / Inter equivalent)
Clean geometric. No decorative fonts.

Hierarchy:
- H1: 28–32pt, SemiBold
- H2: 22–24pt, Medium
- Body: 16pt, Regular
- Caption: 13–14pt, Regular

Line spacing: 1.25–1.35

No ALL CAPS. No excessive bold.
Typography must feel restrained.

---

## Layout System

### Spacing Grid
Base unit: 8pt

Standard paddings:
- Screen margin: 20pt
- Card internal padding: 16–20pt
- Vertical section spacing: 24pt
- Between small elements: 8pt

Nothing cramped. Nothing floating randomly.

### Card System
Corner radius: 18–22pt
Shadow: Very subtle (opacity < 8%)
Elevation difference minimal.
Cards must feel embedded, not floating.

---

## Dashboard Layout (Locked)

Primary purpose: Show system state. Not inspire visually.

Design principle: CORET is a system that handles clothes,
not a fashion app that has numbers.

Structure (top to bottom):

1. Greeting line
   "Good Morning. Your structure is Coherent."
   Small, calm, top of screen. Secondary text color.

2. Cohesion Score Block
   Large centered score (72pt, bold)
   Status label below ("Coherent")
   Thin horizontal progress bar, forest green fill, rounded edges
   No circular rings. No gamification visuals.

3. Component Grid (2x2)

   ┌─────────────────┬─────────────────┐
   │   Alignment     │    Density      │
   │      78         │      64         │
   │   Aligned       │   Refining      │
   ├─────────────────┼─────────────────┤
   │   Palette       │    Rotation     │
   │      71         │      85         │
   │   Coherent      │    Strong       │
   └─────────────────┴─────────────────┘

   Each card: stone background, 18-22pt corner radius
   Component name (caption), score (h2), descriptor (caption muted)
   Tap → Component Detail screen
   Cards feel modular and embedded, not floating

4. Outfit Preview (Should Have)
   Static. Small. Not animated. Not rotating.
   One outfit generated from wardrobe items.
   Outfit is proof of structure, not main attraction.
   Stone card, soft shadow, subtle presentation.
   Shows 2-4 items from wardrobe as clean flat lay.

5. Optimize Preview Card
   Full width stone card
   Primary recommendation headline
   Projected impact (e.g. "Density +9")
   Short structural explanation
   CTA: "View Optimize" → navigates to Optimize tab

6. Evolution Phase Card
   Current phase name (e.g. "Refining")
   One-line narrative
   Tap → Evolution tab

---

Rejected: Vertical column + rotating outfit center
Reason: Wrong hierarchy. Fashion feel, not system feel.

Outfit is present but as evidence of structure.
Not as hero or attraction.

---

## Wardrobe Screen

Default: 2-column masonry grid layout
Background: Warm Taupe
Items: Stone cards

Image style:
- Background auto-cleaned
- Cropped to neutral canvas
- No messy edges
- Soft drop shadow

Item tag badges:
Small subtle pill labels (Structured, Neutral, Primary)
No bright colors.

---

## Optimize Screen

Primary candidate: Large top card
Inside: Role Title, Component Impact, Total Impact, Structural explanation

Below: Two secondary smaller cards

Visual hierarchy: Primary > Secondary
Primary uses accent border or subtle green top bar.
Secondary uses neutral styling.

---

## Evolution Screen

No graphs.

Layout:
- Large Phase Title
- Narrative description
- Stability indicator bar
- Monthly snapshot list (Month, Score, Phase)

Clean chronological layout.

---

## Profile Screen

Vertical layout.

Sections:
- Identity: Primary archetype, Secondary archetype
- Environment: Location, Season mode
- System: Reset profile

All toggles minimal. No flashy switches.

---

## Animations

Duration: 200–300ms
Curve: Ease-in-out

Used for: Tab transitions, card expansion, score updates, optimize reveal

Never bouncy. Never springy. Never exaggerated.

---

## Interaction Feel

Taps: Subtle opacity reduction, soft haptic (medium impact)
Scroll: High frame rate, no heavy blur effects
Transitions: Fade + slight vertical movement (4–8pt)

---

## Micro-Polish Rules

- Numbers animate upward smoothly (count-up effect)
- No confetti
- No achievement badges
- No gamified rewards

Satisfaction must come from clarity, not stimulation.

---

## Image Treatment

User-uploaded clothing images:
- Background neutralization recommended
- Soft shadow
- Uniform padding
- Consistent crop ratio

Visual noise must be minimized.

---

## Accessibility

- Contrast ratio > 4.5:1
- Large text mode supported
- Touch targets minimum 44x44pt
- Dark mode compatible (taupe base adjusted darker)

---

## Overall Feeling

When opening CORET, the user should feel:
"I am entering a controlled system."

Not: "Let's play with clothes."

It should feel like:
- A design tool
- A personal architecture interface
- A calm control panel
- A premium object

---

## Final Standard

If any screen feels loud, busy, playful, or overstimulating: it is wrong.

CORET must feel:
Solid. Sexy. Smooth. Controlled. Perfect.
