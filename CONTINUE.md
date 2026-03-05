# CORET – Continue
Last updated: 2026-03-05

## Completed This Session

- [x] **metadata_extractor.py** — keyword-matching service som gjetter BaseGroup + Category fra produkttittel (bygget av bruker)
- [x] **product_search.py** — SerpAPI Google Shopping-integrasjon, returnerer studiobilde (bygget av bruker)
- [x] **pipeline.py metadata endpoint** — koblet `extract_metadata` til `/api/product-metadata`
- [x] **pipeline.py import** — fikset import av `extract_metadata`

## Build Status

```
engine (V2): swift build pass, swift test 244/244 passing
backend: python -m pytest 24/24 passing
archive/core-v1 (V1): 218/218 passing (archived)
ios/: NOT compilable on Linux — requires Mac + Xcode + Apple SDK
```

## Backend Services Status

| Service | Fil | Status |
|---------|-----|--------|
| Color extraction | `services/color_extraction.py` | ✅ Ferdig (Claude) |
| Metadata extractor | `services/metadata_extractor.py` | ✅ Ferdig (bruker) |
| Product search | `services/product_search.py` | ✅ Ferdig (bruker) |
| Barcode lookup | `services/barcode_lookup.py` | ⛔ Ikke startet |
| Image polish | `services/image_polish.py` | ⛔ Ikke startet |

| Endpoint | Koblet til service? |
|----------|-------------------|
| POST /api/extract-colors | ✅ Ja |
| POST /api/product-metadata | ✅ Ja |
| POST /api/product-search | ⚠️ Nei — service finnes, men endpoint returnerer dummy |
| POST /api/barcode-lookup | ⛔ Nei — service mangler |
| POST /api/image-polish | ⛔ Nei — service mangler |

## In Progress

Bruker lærer Python ved å implementere backend-services selv med steg-for-steg veiledning.

## Next Steps

1. Koble `search_product` inn i pipeline.py product-search endpoint
2. Skriv `barcode_lookup.py` (UPCitemdb API)
3. Koble barcode endpoint i pipeline.py
4. Skriv `image_polish.py` (Photoroom API, Pro-funksjon)
5. Koble image-polish endpoint i pipeline.py
6. Skriv tester for nye services
7. Railway deployment

## After Backend (krever Mac)

- iOS image pipeline services (ios/Services/)
- SwiftUI Views for alle 5 tabs
- Xcode project setup

## Next Session Prompt

```
CORET — resuming. Read CLAUDE.md, then CONTINUE.md.

Backend er under utvikling. Bruker lærer Python og bygger services selv.
Ferdig: color_extraction, metadata_extractor, product_search.
Gjenstår: koble product-search endpoint, barcode_lookup, image_polish, tester, deployment.

Fortsett steg-for-steg veiledning. Bruker vil ha forklaringer på hva koden gjør.
```

## Decisions Made

- Bruker skriver kode selv for å lære — Claude guider steg for steg
- Alle forklaringer på norsk
- Bruker vil ha kommentarer på hva kodelinjer betyr
