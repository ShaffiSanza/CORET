# CORET — Profile Wireframe (V1)

## Design Intent

Profile is the system control panel, accessed via the top-right menu icon (not a tab).
It is where the user defines *who they are* structurally — not how they look.

This is not a social profile. No avatar. No bio. No followers.
It is the control panel for the structural engine.

Six sections: Style Context, Identity (archetypes), Season, Favorite Fits, Import Sources, Settings.
Minimal interaction. Maximum clarity.

**Navigation:** 3 tabs (Wardrobe, Studio, Discover). Profile opens via menu icon on any tab.

---

## Screen Structure

```
    ┌─────────────────────────────────────┐
    │  9:41                     ●●●●  5G  │
    │                                     │
    │  ‹ Tilbake      Profil          ⚙  │
    │                                     │
    │  ┌─────────────────────────────────┐│
    │  │  [S·W]  Structured · Warm      ││
    │  │         Medlem siden jan 2026   ││
    │  │                                 ││
    │  │  [Tailored] [Smart Casual]      ││
    │  │  [Vår/Sommer] [Oslo] [42 plagg] ││
    │  └─────────────────────────────────┘│
    │                                     │
    │  ┌─────────────────────────────────┐│
    │  │  STRUKTURELL IDENTITET          ││
    │  │                                 ││
    │  │  ┌───┬────────────────────┐     ││
    │  │  │ ▭ │ PRIMÆR             │  →  ││
    │  │  │   │ Tailored           │     ││
    │  │  │   │ Rene linjer.       │     ││
    │  │  └───┴────────────────────┘     ││
    │  │  ┌───┬────────────────────┐     ││
    │  │  │ ▢ │ SEKUNDÆR           │  →  ││
    │  │  │   │ Smart Casual       │     ││
    │  │  │   │ Kontrollert.       │     ││
    │  │  └───┴────────────────────┘     ││
    │  │                                 ││
    │  │  [ Endre retning ]              ││
    │  └─────────────────────────────────┘│
    │                                     │
    │  ┌─────────────────────────────────┐│
    │  │  SESONG                         ││
    │  │                                 ││
    │  │  ❄ Vår / Sommer        Oslo    ││
    │  │                      Sist: 14/2 ││
    │  │                                 ││
    │  │  ┌──────────────────────────┐   ││
    │  │  │  ◉ Sesongskifte oppdaget │   ││
    │  │  │  Posisjonen din antyder: │   ││
    │  │  │  Høst / Vinter           │   ││
    │  │  │  [ Rekalibrér ]          │   ││
    │  │  └──────────────────────────┘   ││
    │  └─────────────────────────────────┘│
    │                                     │
    │  ┌─────────────────────────────────┐│
    │  │  FAVORITT-ANTREKK           3   ││
    │  │  [thumb][thumb][thumb][ + ]     ││
    │  └─────────────────────────────────┘│
    │                                     │
    │  ┌─────────────────────────────────┐│
    │  │  IMPORTKILDER                   ││
    │  │  📧 E-post          Koblet      ││
    │  │  🟠 Zalando         Koble til   ││
    │  │  🟡 Boozt           Koble til   ││
    │  └─────────────────────────────────┘│
    │                                     │
    │  ┌─────────────────────────────────┐│
    │  │  INNSTILLINGER                  ││
    │  │  Varsler                     →  ││
    │  │  Eksporter data              →  ││
    │  │  Personvern                  →  ││
    │  │  Om CORET              v1.0  →  ││
    │  │  Tilbakestill profil         →  ││
    │  └─────────────────────────────────┘│
    │                                     │
    │  ┌─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┐│
    │  │  CORET                          ││
    │  │  Ditt garderobe-operativsystem  ││
    │  └─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┘│
    │                                     │
    │  ┌─────────┬─────────┬─────────┐   │
    │  │ Wardrobe │ Studio  │ Discover│   │
    │  └─────────┴─────────┴─────────┘   │
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

## Section 3 — Favorite Fits

Horizontal scrollable carousel of the user's saved favorite outfits.

### Layout

```
┌─────────────────────────────────────┐
│  FAVORITT-ANTREKK                3  │
│                                     │
│  [thumb][thumb][thumb][ + ]         │
│   name    name    name   Legg til   │
└─────────────────────────────────────┘
```

- Each thumbnail: 82×106pt, rounded 10pt, outfit color blobs + emoji overlay
- Active (currently viewed): gold border
- "+" card: dashed border, opens outfit selection
- Max visible in scroll: ~3.5 cards

---

## Section 4 — Import Sources

Connected data sources for garment import.

### Layout

```
┌─────────────────────────────────────┐
│  IMPORTKILDER                       │
│                                     │
│  📧  E-post     12 plagg   Koblet   │
│  🟠  Zalando    Auto     Koble til  │
│  🟡  Boozt      Auto     Koble til  │
└─────────────────────────────────────┘
```

- Connected sources: green "Koblet" badge
- Available sources: muted "Koble til" button
- Future: add more retail integrations

---

## Section 5 — Settings

System settings. Minimal.

### Layout

```
┌─────────────────────────────────────┐
│  INNSTILLINGER                      │
│                                     │
│  🔔  Varsler                     →  │
│  ─────────────────────────────────  │
│  📊  Eksporter data              →  │
│  ─────────────────────────────────  │
│  🔒  Personvern                  →  │
│  ─────────────────────────────────  │
│  ℹ   Om CORET              v1.0 →  │
│  ─────────────────────────────────  │
│  ⟳   Tilbakestill profil        →  │  ← destructive color
└─────────────────────────────────────┘
```

### Settings Rows

| Row | Action | Notes |
|-----|--------|-------|
| Varsler | Push → Notification prefs | Milestone alerts, season reminders |
| Eksporter data | Push → Export screen | JSON/CSV wardrobe export |
| Personvern | Push → Privacy settings | Data handling info |
| Om CORET | Push → About screen | Version, tagline, credits |
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

- Background: Dark (#1a1714), body (#0E0C0A)
- Section cards: Glass effect — rgba(34,31,26,0.85), blur(20px), 18pt radius
- Section labels: 9pt uppercase, letter-spacing 2.5px, text-4 (#4a4540)
- Archetype badges: gold-soft background for primary, subtle grey for secondary
- Recalibration card: gold-tinted inner card with pulsing accent dot, left gold bar
- Settings rows: standard list pattern, right-aligned chevron, gradient dividers
- Destructive row: red (#B4705A) text for "Tilbakestill profil"
- Accent buttons: gold-tinted background + border for recalibration
- Ambient blobs: subtle gold + green, blurred, behind content
- Fonts: DM Sans (body) + Instrument Serif (headings, names)

---

## Data Ownership

Profile screen **owns** `UserProfile` (style_context, archetype, season).
Profile screen **reads** `SeasonalRecommendation` (from SeasonalEngine).
Profile screen **reads** garment count, favorite outfits, import source status.
Backend: `GET/PUT /api/profile` for style_context + archetype persistence.

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

- Avatar or profile picture (not a social profile — initials monogram used instead)
- Username or display name (not needed for V1)
- Theme customization (single dark theme in V1)
- Location permissions flow (handled by OS, not CORET UI)
- Pro-oppgradering (hidden until V1.5, no paywall in V1)
