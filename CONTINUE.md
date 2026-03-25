# CORET – Continue
Last updated: 2026-03-25 13:15

## Status
```
Engine:    387/387 ✅
Backend:   255/255 ✅
iOS:       BUILD SUCCEEDED ✅
Railway:   Volume at /app/data (persistent), ENABLE_REMBG=true (causes 502, FJERN)
```

## CRITICAL: Fjern ENABLE_REMBG fra Railway
```bash
railway variables set ENABLE_REMBG=""
```
rembg krasjer Railway (502 timeout, 53s). Må fjernes.

## Unsolved: Modeller i produktbilder
- Photoroom fjerner bakgrunn men beholder person
- rembg fjerner modeller men krasjer Railway (176MB modell, for tung)
- Google Images _find_clean_image() returnerer None — trenger debugging
- Beste løsning: pre-prosesser lokalt med rembg, last opp til Railway Volume

## Completed (25 March — to sesjoner)
- [x] Category mapping fix (CodingKeys)
- [x] Shoe keywords + longest-match
- [x] Apple Vision bg removal (iOS)
- [x] Race condition fix
- [x] Multiple search results + clothing filter
- [x] Prettifier pipeline (studio bg + shadow)
- [x] rembg integration (lokal, ikke Railway)
- [x] Splash + 4-step onboarding
- [x] Dual theme (light/dark + picker)
- [x] "Basics du sannsynligvis eier"
- [x] Studio editorial canvas med swipe
- [x] Railway Volume persistent storage
- [x] Google Images fallback endpoint
- [x] Onboarding validation
- [x] Code signing fix for Xcode
- [x] Studio: alle 4 lag like store (w*0.50, h*0.22)
- [x] Studio: color fallback = soft ellipse blur (ingen boks)
- [x] Discover: animert shimmer erstatter grå sirkler

## Next Session
```
Les CONTINUE.md.

1. Fjern ENABLE_REMBG fra Railway: railway variables set ENABLE_REMBG=""

2. Fiks modell-problemet:
   - Debug _find_clean_image() i product_search.py
   - Pre-prosesser basics lokalt med rembg → upload til Volume
   - Eller: finn retailer CDN-URLer med produktbilder uten modell

3. Studio polish:
   - Test swipe mellom plagg
   - Verifiser at bilder flyter uten ramme
   - Match HTML mockup bedre

4. Generell UI polish:
   - Wardrobe garment cards konsistens
   - Loading states overalt
```

## Architecture
- DATA_DIR=/app/data on Railway (Volume)
- image_isolate.py: rembg→Photoroom fallback
- image_normalize.py: studio bg #F8F6F2 + shadow
- Basics: hardkodede URLs i WardrobeView quickBasics
- AppTheme: @AppStorage("appTheme"), .light/.dark
- Studio: SwipeableLayer med DragGesture, Layer enum i ViewModel
- Onboarding: SplashView → OnboardingView → ContentView
