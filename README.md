# CORET — Wardrobe Operating System

> "Your Wardrobe Operating System. Built Around Your Core."

CORET hjelper deg forstå garderoben din og gjøre den bedre over tid. Det er **ikke** en mote-app, shopping-plattform eller budsjett-verktøy — det er et system som måler hva du har, hva som mangler, og hva som bør bli neste kjøp.

---

## Hva den gjør

- **Måler** hvor godt garderoben henger sammen (dekning, balanse, kombinasjoner)
- **Foreslår** hva som mangler og hva du bør legge til
- **Følger** utviklingen din over tid med faser og milepæler
- **Tilpasser** seg sesong og hvor du bor

---

## Build Status

| Pakke | Tester | Status |
|-------|--------|--------|
| `engine/` — V2 motor (aktiv) | 244/244 | ✅ Alle består |
| `backend/` — Python/FastAPI | 24/24 | ✅ Alle består |
| `archive/` — V1 motor (arkivert) | 218/218 | ✅ Alle består |

```bash
cd engine  && swift build && swift test
cd backend && source .venv/bin/activate && python -m pytest tests/ -v
```

Krever Swift 6.2+. Ingen eksterne avhengigheter i motoren.

---

## Mappestruktur

```
CORET/
├── engine/         V2-motoren — ferdig, 244 tester
├── ios/            iOS-lag — skrevet, krever Mac for kompilering
│   ├── Persistence/    6 SwiftData-modeller
│   ├── Coordinators/   Bro mellom motor og lagring
│   └── ViewModels/     5 ViewModels (én per fane)
├── backend/        Python/FastAPI — bildepipeline + metadata
│   ├── services/       Fargeuttrekk, produktsøk, strekkode, metadata
│   ├── routers/        API-endepunkter
│   └── tests/          pytest (24 tester)
├── docs/           Spesifikasjoner og teknisk dokumentasjon
├── moodboard/      HTML-mockups og wireframes for alle faner
└── archive/        V1-motoren — arkivert, 218 tester
```

---

## V2-motoren — Ferdig

| Motor | Hva den gjør | Tester |
|-------|-------------|--------|
| `CohesionEngine` | Scorer hvor godt plaggene henger sammen | 70 |
| `ClarityEngine` | Totalscoren — stil + sammenheng | 23 |
| `ScoreProjector` | "Hva skjer hvis jeg legger til / fjerner dette?" | 22 |
| `IdentityResolver` | Finner stilen din — label, tagger, beskrivelse | 15 |
| `KeyGarmentResolver` | Finner hvilke plagg som er viktigst | 13 |
| `MilestoneTracker` | Følger reisen din — faser og fremgang | 38 |
| `SeasonalEngineV2` | Sesongdekning og vekttilpasning | 26 |
| `OptimizeEngineV2` | Finner hull og foreslår kjøp | 19 |

Alle formler og detaljer: [`docs/ENGINE_SPECS.md`](docs/ENGINE_SPECS.md)

---

## iOS-lag — Skrevet, ikke kompilert

`ios/`-mappen inneholder ferdigskrevet Swift-kode som krever **Mac + Xcode** for å kompilere.

**Skrevet (Pass 3):**
- 6 SwiftData-modeller for lagring (plagg, profil, snapshots, milepæler, antrekk, cache)
- `EngineCoordinator` — kobler lagring til motoren
- 5 ViewModels — Dashboard, Garderobe, Optimalisering, Utvikling, Profil

**Gjenstår (Pass 4 — krever Mac):**
- SwiftUI-views for alle 5 faner
- `COREApp.swift` startpunkt
- Xcode-prosjekt oppsett

---

## Hva gjenstår

| Oppgave | Blokkert av |
|---------|-------------|
| Kompilere + teste iOS-lag | Mac + Xcode |
| SwiftUI-views (5 faner) | Mac + Xcode |
| Xcode-prosjekt oppsett | Mac |
| TestFlight / App Store | Mac |

**På Linux (ingen blokkering):** motorforbedringer, moodboard-oppdateringer, dokumentasjon.

---

## Arkitektur

> Motor først. UI kan byttes ut. Motoren kan ikke det.

```
SwiftUI Views
     ↓
ViewModels
     ↓
EngineCoordinator
     ↓              ↓
V2-motoren     SwiftData
(engine/)      (ios/Persistence/)
```

---

## Designsystem

- **Bakgrunn**: `#2F2A26` — varm mørk taupe
- **Kort**: `#E7E2DA` — lys stein
- **Aksent**: `#2F4A3C` — dyp dempet skoggrønn
- **Font**: SF Pro (system)
- **Tone**: Rolig. Arkitektonisk. Ikke belærende.

Full UI-spec: [`docs/ENGINE_SPECS.md §9`](docs/ENGINE_SPECS.md)

---

## Viktige filer

| Fil | Innhold |
|-----|---------|
| `docs/ENGINE_SPECS.md` | Alle motorspecs, IA, UI, merkevare, monetisering |
| `docs/OPPORTUNITIES_UPGRADES.md` | Produkt- og forretningsmuligheter |
| `moodboard/*/` | HTML-mockups for hver fane (åpne i nettleser) |
