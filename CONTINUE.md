# CORET – Continue
Last updated: 2026-03-25 06:35

## Status
```
Engine:    387/387 ✅
Backend:   255/255 ✅ (6 new metadata tests, prettify endpoint, rembg)
iOS:       BUILD SUCCEEDED ✅ (onboarding, dual theme, studio canvas, basics)
Railway:   Deployed, health OK
```

## Completed This Session (25 March, Mac)
- [x] Fix category mapping: CodingKeys mismatch (suggested_category)
- [x] Add shoe keywords (jordan, air force, shoes, yeezy, dunk, etc.)
- [x] Fix oxford keyword conflict with longest-match-wins algorithm
- [x] Apple Vision on-device background removal (ImageProcessor.swift)
- [x] Fix race condition (isProcessingImage/isProcessingMetadata)
- [x] Fix main thread blocking (Task.detached for Vision)
- [x] Handle file:// URLs in GarmentCard (UIImage for local)
- [x] Make /api/images/ public (AsyncImage can't send auth)
- [x] Multiple search results (was 1, now up to 8)
- [x] Clothing filter via metadata extractor
- [x] "product" keyword in SerpAPI queries
- [x] Prettifier pipeline (studio bg #F8F6F2 + soft drop shadow)
- [x] /api/prettify-image endpoint
- [x] rembg integration (local, CPU, fallback for Photoroom)
- [x] Splash screen (CORET wordmark, 1.8s auto-proceed)
- [x] 4-step onboarding (style, lifestyle, theme, start)
- [x] Dual theme system (AppTheme .light/.dark, @AppStorage)
- [x] Theme picker in onboarding + settings toggle
- [x] "Basics du sannsynligvis eier" with pre-prettified product images
- [x] Basics persist until all added
- [x] Studio editorial canvas (overlapping garments, swipe chips)

## Known Issues (Next Session)
1. **Product images still show models** — Photoroom keeps person as foreground. rembg fixes this but too heavy for Railway. Need: either upgrade Railway RAM, use external rembg service, or find product-only image source
2. **Studio empty state is ugly** — dashed boxes on black bg when no garments. Needs: illustration, CTA to add garments, or auto-surprise
3. **Studio design needs polish** — editorial canvas concept is right but execution needs refinement. Reference: moodboard/studio/ HTML mockup
4. **Some basics show color swatches** — prettified images may not load if Railway was still deploying

## Build Status
```
cd engine  && swift build && swift test     # 387/387
cd backend && source .venv/bin/activate && python -m pytest tests/ -v  # 255/255
xcodebuild -project CORET.xcodeproj -scheme CORET -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Next Session Prompt
```
Les CONTINUE.md og CLAUDE.md. Fokus:

1. Studio UI polish — match HTML moodboard kvalitet:
   - Editorial canvas med ekte produktbilder (overlappende, rotert)
   - Empty state: "Legg til plagg i garderoben for å bygge antrekk" med illustrasjon
   - Score display som pulser, FI feedback integrert
   - Swipe-gesture for å bytte plagg i hver slot

2. Modell-problemet — best solution:
   - Prøv remove.bg API (bedre enn Photoroom for garment isolation)
   - Eller: bruk Google Images engine i SerpAPI med "product white background"
   - Eller: oppgrader Railway til 512MB+ for rembg

3. Garment card design — match Alta quality:
   - Produktbilde sentrert på off-white bg
   - Subtil skygge under produkt
   - Navn + kategori under bildet
   - Konsistent størrelse/spacing
```

## Architecture Notes
- AppTheme enum in DesignSystem.swift (.light/.dark)
- Onboarding in ios/Views/Onboarding/ (SplashView, OnboardingView)
- ImageProcessor.swift in ios/Services/ (Apple Vision bg removal)
- image_isolate.py in backend/services/ (rembg, Photoroom fallback)
- Prettifier: image_normalize.py adds studio bg + shadow
- Basics: hardcoded QuickBasic[] in WardrobeView with pre-prettified URLs
- Search: "product" keyword appended to all SerpAPI queries
