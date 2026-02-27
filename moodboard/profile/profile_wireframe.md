# CORET — Profile Tab Wireframe (V1)

## Design Intent

Profile is the system configuration screen.
It is where the user defines *who they are* structurally — not how they look.

This is not a social profile. No avatar. No bio. No followers.
It is the control panel for the structural engine.

Three sections: Identity (archetypes), Season, Settings.
Minimal interaction. Maximum clarity.

---

## Screen Structure

```
    ┌─────────────────────────────────────┐
    │  9:41              CORET        ●●● │
    │                                     │
    │  PROFIL                             │
    │                                     │
    │  ┌─────────────────────────────────┐│
    │  │  STRUKTURELL IDENTITET          ││
    │  │                                 ││
    │  │  Primær                         ││
    │  │  ┌───┬────────────────────┐     ││
    │  │  │ ▭ │ Tailored           │     ││
    │  │  │   │ structuredMinimal  │     ││
    │  │  └───┴────────────────────┘     ││
    │  │                                 ││
    │  │  Sekundær                       ││
    │  │  ┌───┬────────────────────┐     ││
    │  │  │ ▢ │ Smart Casual       │     ││
    │  │  │   │ smartCasual        │     ││
    │  │  └───┴────────────────────┘     ││
    │  │                                 ││
    │  │  [ Endre retning ]              ││
    │  └─────────────────────────────────┘│
    │                                     │
    │  ┌─────────────────────────────────┐│
    │  │  SESONG                         ││
    │  │                                 ││
    │  │  Nåværende: Vår / Sommer        ││
    │  │                                 ││
    │  │  ┌──────────────────────────┐   ││
    │  │  │  ◉ Sesongskifte oppdaget │   ││
    │  │  │  System anbefaler:       │   ││
    │  │  │  Høst / Vinter           │   ││
    │  │  │  [ Rekalibrér ]          │   ││
    │  │  └──────────────────────────┘   ││
    │  │                                 ││
    │  └─────────────────────────────────┘│
    │                                     │
    │  ┌─────────────────────────────────┐│
    │  │  INNSTILLINGER                  ││
    │  │                                 ││
    │  │  Om CORET                    →  ││
    │  │  ─────────────────────────────  ││
    │  │  Pro-oppgradering            →  ││
    │  │  ─────────────────────────────  ││
    │  │  Tilbakestill profil         →  ││
    │  └─────────────────────────────────┘│
    │                                     │
    │  ┌─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┐│
    │  │  CORET v1.0                    ││
    │  │  Ditt garderobe-operativsystem ││
    │  └─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┘│
    │                                     │
    │  ┌───┬───┬───┬───┬───┐             │
    │  │ ◻ │ ◻ │ ◻ │ ◻ │ ● │  ← Profile │
    │  └───┴───┴───┴───┴───┘             │
    └─────────────────────────────────────┘
```

---

## Section 1 — Structural Identity

The user's archetype configuration. This is the most important section.

### Layout

```
┌─────────────────────────────────────┐
│  STRUKTURELL IDENTITET              │  ← section label (uppercase, textMuted)
│                                     │
│  Primær                             │  ← label (caption, textSecondary)
│  ┌───┬──────────────────────────┐   │
│  │ ▭ │ Tailored                 │   │  ← archetype name (h3, textPrimary)
│  │   │ Clean lines. Definerte   │   │  ← description (caption, textMuted)
│  │   │ former. Intensjonell.    │   │
│  └───┴──────────────────────────┘   │
│                                     │
│  Sekundær                           │
│  ┌───┬──────────────────────────┐   │
│  │ ▢ │ Smart Casual             │   │
│  │   │ Mellom formelt og        │   │
│  │   │ avslappet. Kontrollert.  │   │
│  └───┴──────────────────────────┘   │
│                                     │
│  [ Endre retning ]                  │  ← text button (accent, 14pt)
└─────────────────────────────────────┘
```

### Elements

- Section label: "STRUKTURELL IDENTITET" (11pt, uppercase, letter-spacing 2px, textMuted)
- Card: stone background (#E7E2DA), 20pt radius, 16–20pt padding
- Each archetype row:
  - Left: SVG silhouette icon (same as onboarding — sharp/balanced/rounded)
  - Right: archetype display name (h3, bold, textPrimary) + description (caption, textMuted)
- Divider between primary and secondary (cardDivider, 1px)
- "Endre retning" button: text-only, accent color, bottom of card

### Archetype Edit Sheet (Modal)

Triggered by "Endre retning":

```
    ┌─────────────────────────────────────┐
    │                                     │
    │  Endre strukturell retning          │
    │                                     │
    │  Primær retning                     │
    │  ┌───┬────────────────────────┐     │
    │  │ ▭ │ Tailored             ✓ │     │
    │  └───┴────────────────────────┘     │
    │  ┌───┬────────────────────────┐     │
    │  │ ▢ │ Smart Casual           │     │
    │  └───┴────────────────────────┘     │
    │  ┌───┬────────────────────────┐     │
    │  │ ◯ │ Street                 │     │
    │  └───┴────────────────────────┘     │
    │                                     │
    │  Sekundær retning                   │
    │  ┌───┬────────────────────────┐     │
    │  │ ▢ │ Smart Casual         ✓ │     │
    │  └───┴────────────────────────┘     │
    │  ┌───┬────────────────────────┐     │
    │  │ ◯ │ Street                 │     │
    │  └───┴────────────────────────┘     │
    │                                     │
    │  ┌──────────────────────────────┐   │
    │  │  ⚠ Endring rekalibrerer hele │   │
    │  │  cohesion-beregningen.       │   │
    │  └──────────────────────────────┘   │
    │                                     │
    │  [ Avbryt ]        [ Lagre ]        │
    │                                     │
    └─────────────────────────────────────┘
```

### Edit Sheet Rules

- Primary picker: all 3 archetypes, current selected
- Secondary picker: only shows archetypes that differ from primary selection
  - When primary changes, secondary resets if it equals new primary
- Warning: "Endring rekalibrerer hele cohesion-beregningen."
  - Shown always (textMuted, subtle warning style, NOT destructive red)
- Save: triggers full engine recompute (CohesionEngine + OptimizeEngine + EvolutionEngine)
- Cancel: discard changes, dismiss sheet
- Primary and secondary cannot be the same (enforced by exclusion)

---

## Section 2 — Season

Season configuration and recalibration.

### Layout — No Recalibration Suggested

```
┌─────────────────────────────────────┐
│  SESONG                             │
│                                     │
│  Nåværende modus                    │
│  Vår / Sommer                       │  ← h3, textPrimary
│                                     │
│  Sist rekalibrert: 14. feb 2026     │  ← caption, textMuted
│                                     │
│  [ Endre sesong manuelt ]           │
└─────────────────────────────────────┘
```

### Layout — Recalibration Suggested

```
┌─────────────────────────────────────┐
│  SESONG                             │
│                                     │
│  Nåværende modus                    │
│  Vår / Sommer                       │
│                                     │
│  ┌──────────────────────────────┐   │
│  │  ◉ Sesongskifte oppdaget     │   │  ← accent dot
│  │                              │   │
│  │  Posisjonen din antyder:     │   │
│  │  Høst / Vinter               │   │  ← bold, textPrimary
│  │                              │   │
│  │  Sesongvekter justerer       │   │
│  │  cohesion-beregningen.       │   │  ← caption, textMuted
│  │                              │   │
│  │  [ Rekalibrér ]              │   │  ← accent button
│  └──────────────────────────────┘   │
│                                     │
│  [ Endre sesong manuelt ]           │
└─────────────────────────────────────┘
```

### Season Display Labels

| Engine value | User sees |
|-------------|-----------|
| .springSummer | Vår / Sommer |
| .autumnWinter | Høst / Vinter |

### Recalibration Logic

Recalibration suggestion appears when:
1. `SeasonalEngine.recommend()` returns `shouldRecalibrate = true`
2. Detected season differs from current season
3. User has not recalibrated within cooldown period

### Recalibration Action

"Rekalibrér" button:
1. Updates `UserProfile.seasonMode` to detected season
2. Applies `SeasonalEngine.adjustedWeights()` for new season
3. Triggers full engine recompute with new weights
4. Updates `lastRecalibrationDate`
5. Recalibration card disappears
6. Brief confirmation: "Sesong oppdatert til Høst / Vinter."

### Manual Season Change

"Endre sesong manuelt" opens a simple picker:
- Two options: Vår / Sommer, Høst / Vinter
- Current selected
- Same recompute behavior as recalibration
- Bypasses location detection

---

## Section 3 — Settings

System settings. Minimal.

### Layout

```
┌─────────────────────────────────────┐
│  INNSTILLINGER                      │
│                                     │
│  Om CORET                        →  │
│  ─────────────────────────────────  │
│  Pro-oppgradering                →  │  ← hidden in V1 (no paywall)
│  ─────────────────────────────────  │
│  Tilbakestill profil             →  │
└─────────────────────────────────────┘
```

### Settings Rows

| Row | Action | Notes |
|-----|--------|-------|
| Om CORET | Push → About screen | Version, tagline, credits |
| Pro-oppgradering | Push → Pro screen | NOT in V1 launch. Hidden until V1.5. |
| Tilbakestill profil | Alert → Confirmation | Destructive. Full data wipe. |

### About CORET Screen (Push)

```
    ┌─────────────────────────────────────┐
    │  ← Profil                           │
    │                                     │
    │                                     │
    │           CORET                     │
    │                                     │
    │    Ditt garderobe-operativsystem.    │
    │    Bygget rundt din kjerne.          │
    │                                     │
    │    Versjon 1.0                       │
    │                                     │
    │                                     │
    └─────────────────────────────────────┘
```

- Logo: CORET (uppercase, spaced, 20pt, semibold)
- Tagline: "Ditt garderobe-operativsystem." (body, textSecondary)
- Secondary: "Bygget rundt din kjerne." (caption, textMuted)
- Version: "Versjon 1.0" (caption, textMuted)
- Calm, centered, spacious. No links. No social.

### Profile Reset (Destructive)

"Tilbakestill profil" triggers confirmation alert:

```
┌─────────────────────────────────┐
│                                 │
│  Tilbakestill profil?           │
│                                 │
│  Dette sletter alle plagg,      │
│  snapshots og retningsvalg.     │
│  Kan ikke angres.               │
│                                 │
│  [ Avbryt ]   [ Tilbakestill ]  │
│                            ↑    │
│                      destructive│
└─────────────────────────────────┘
```

- "Tilbakestill" button: destructive color (#7A3E3E)
- Action: deletes all WardrobeItems, all CohesionSnapshots, all EvolutionSnapshots, cache
- Resets UserProfile to defaults
- Redirects to onboarding flow
- No partial reset option in V1

---

## Footer

Below settings section:

```
┌─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┐
│  CORET v1.0                         │
│  Ditt garderobe-operativsystem      │
└─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┘
```

- Centered, textMuted, 12pt
- Subtle. Not distracting.

---

## Visual System

- Background: Warm Dark Taupe (#2F2A26)
- Section cards: Stone (#E7E2DA), 20pt radius, 16–20pt padding
- Section labels: 11pt uppercase, letter-spacing 2px, textMuted
- Archetype SVGs: same silhouette icons as onboarding
- Recalibration card: inner card within season section, accent-tinted border
- Settings rows: standard list pattern, right-aligned chevron, cardDivider between rows
- Destructive button: #7A3E3E for reset confirmation
- CTA buttons: accent (#2F4A3C) for recalibration and save

---

## Data Ownership

Profile tab **owns** `UserProfile`.
Profile tab **reads** `SeasonalRecommendation` (from SeasonalEngine).

### State Update Triggers from Profile

| User Action | Engine Impact |
|-------------|---------------|
| Change archetype (primary or secondary) | Full recompute: Cohesion + Optimize + Evolution |
| Recalibrate season | Recompute with new seasonal weights |
| Manual season change | Same as recalibrate |
| Reset profile | Delete all data, restart onboarding |

---

## Edge Cases

### First-time Profile View (After Onboarding)
All sections populated from onboarding choices. No empty state.
Season defaults to springSummer unless location detected during onboarding.

### Equatorial Location
No recalibration suggestion shown. Manual season change available.
SeasonalEngine returns nil for detection — recalibration card hidden.

### Same Season Detected
Recalibration card not shown. `shouldRecalibrate = false`.

### Archetype Change Impact
Warning text always visible in edit sheet. Change can significantly alter scores.
No confirmation beyond the warning — user has full control.

---

## What This Wireframe Does NOT Cover

- Avatar or profile picture (not a social profile)
- Username or display name (not needed for V1)
- Export/import data (future consideration)
- Notification preferences (no push notifications in V1)
- Theme customization (single theme in V1)
- Location permissions flow (handled by OS, not CORET UI)
