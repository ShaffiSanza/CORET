# CORET – Continue
Last updated: 2026-03-25 12:00

## Status
```
Engine:    387/387 ✅
Backend:   255/255 ✅
iOS:       BUILD SUCCEEDED ✅
Railway:   Volume mounted at /app/data (persistent images)
```

## CRITICAL UNSOLVED: Product images show models

**Root cause:** Photoroom removes background but keeps person wearing clothes.

**What DOESN'T work:**
- rembg on Railway → 502 timeout (176MB model too heavy, 53s inference)
- Google Images search → _find_clean_image() returns None (needs debugging)
- "product" keyword in SerpAPI → helps slightly but doesn't eliminate models

**What DOES work (locally):**
- rembg on Mac → successfully removes models (tested, 46% transparent)
- Install: `pip install "rembg[cpu]"` in backend/.venv

**Best remaining solutions:**
1. Pre-process basics locally with rembg, upload to Railway Volume
2. Debug why _find_clean_image() returns None — may need different Google Images query
3. Use external rembg service (Replicate/Modal, ~$0.001/image)
4. Manual curation: find product-only image URLs from retailer CDNs

**Quick win for next session:**
```bash
# Run locally to pre-process basics with rembg:
cd backend && source .venv/bin/activate
python3 -c "
from services.image_isolate import isolate_garment
from services.image_normalize import normalize_image
import httpx, asyncio

# Download thumbnail → rembg → normalize → save locally
# Then upload to Railway Volume via scp or API
"
```

## Completed This Session (25 March)
- [x] Category mapping fix (CodingKeys mismatch)
- [x] Shoe keywords + longest-match algorithm
- [x] Apple Vision bg removal (ImageProcessor.swift)
- [x] Race condition fix (separate processing flags)
- [x] Multiple search results + clothing filter
- [x] Prettifier pipeline (studio bg + shadow)
- [x] rembg integration (works locally, NOT on Railway)
- [x] Splash + 4-step onboarding
- [x] Dual theme system (light/dark)
- [x] "Basics du sannsynligvis eier" with product images
- [x] Studio editorial canvas (empty state + garment stack)
- [x] Railway Volume for persistent storage (DATA_DIR=/app/data)
- [x] Google Images fallback endpoint (needs debugging)
- [x] Onboarding validation (disabled continue button)

## Known Issues
1. **Models in images** — see above, CRITICAL
2. **Railway ephemeral** — FIXED with Volume at /app/data
3. **Google Images _find_clean_image()** — returns None, needs debug
4. **Studio needs more polish** — canvas works but needs better visuals
5. **ENABLE_REMBG=true set on Railway** — causes 502, should be removed

## Architecture
- DATA_DIR env var → /app/data on Railway, local data/ in dev
- image_isolate.py: rembg primary (if ENABLE_REMBG), Photoroom fallback
- image_normalize.py: studio bg #F8F6F2 + soft shadow
- Basics: hardcoded QuickBasic[] in WardrobeView with Railway image URLs
- AppTheme in DesignSystem.swift, persisted via @AppStorage("appTheme")
- Onboarding: SplashView → OnboardingView (4 steps) → ContentView

## Next Session Prompt
```
Les CONTINUE.md. Hovedproblem: produktbilder viser modeller.

Prioritet 1: Fiks bilder
- Debug _find_clean_image() i product_search.py — hvorfor returnerer den None?
- Pre-prosesser basics lokalt med rembg og last opp til Railway
- Fjern ENABLE_REMBG fra Railway (forårsaker 502)

Prioritet 2: Studio polish
- Match HTML mockup i moodboard/studio/
- Bedre empty state, garment overlapping, score animation

Prioritet 3: Garment card design
- Konsistent bildevisning
- Loading shimmer i stedet for blank placeholder
```

## Environment
- Railway Volume: /app/data (persistent)
- Railway env: DATA_DIR=/app/data, ENABLE_REMBG=true (FJERN DENNE)
- rembg installed locally in backend/.venv
- SerpAPI key: only on Railway, not local
