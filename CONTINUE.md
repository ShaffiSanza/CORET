# CORET – Continue
Last updated: 2026-03-26 00:30

## Status
```
Engine:    387/387 ✅
Backend:   257/257 ✅
iOS:       BUILD SUCCEEDED ✅
Railway:   500-bug FIXED (middleware refactor), needs deploy to verify
```

## Completed This Session (26 March)

### Backend — Middleware & Pipeline
- [x] Railway 500-bug fixed: converted RateLimitMiddleware + APIKeyMiddleware from BaseHTTPMiddleware to pure ASGI
- [x] Moved security_logger import to top-level, removed unused HTTPException
- [x] Image normalize v2: category-aware canvases (top 1200x1400, pants 1000x1400, shoes 900x700, outerwear 1300x1500)
- [x] Transparent PNG output (no baked background, no baked shadow)
- [x] Alpha fringe cleanup (erode/dilate for white halo removal)
- [x] Fill ratio normalization per category (tops 81%, pants 85%, shoes 75%)
- [x] Anchor point metadata (anchor_x, anchor_y, visual_weight, bounding_box)
- [x] Garment model extended: image_width, image_height, image_anchor_x, image_anchor_y, image_visual_weight
- [x] Router passes category to normalizer, stores metadata, fixed polish_result bug
- [x] Re-processing script for existing images (scripts/reprocess_images.py)
- [x] Architecture boundary comment in wardrobe_analysis.py
- [x] CLAUDE.md updated: Railway 500-bug marked RESOLVED
- [x] 12 new normalize tests, updated storage tests (257/257 total)

### iOS — Studio Complete Redesign
- [x] Gallery art direction: warm stone background #F3EEE7 → #EDE6DD (no dark mode)
- [x] Glass restricted to UI surfaces only (insight card, nav, controls)
- [x] Per-category shadow system: tops 0.10/24/12, pants 0.09/20/10, shoes 0.08/16/8
- [x] ZStack overlap composition: top→pants overlap 24pt, pants→shoes gap 14pt
- [x] Fixed size ratios: top 180pt (1.00), pants 154pt (0.85), shoes 85pt (0.47)
- [x] Single vertical center axis — all garments aligned
- [x] Hero zone 340pt fixed height (fits all iPhones without scrolling)
- [x] Insight card as museum label: gallery descriptors, 48pt score, max 2 metrics
- [x] Bottom nav softened: warm border, muted gold icons, no forced dark scheme
- [x] Hero-only debug mode (triple-tap to enter, cycles 3 test outfits)
- [x] 3 fixed test outfits in StudioViewModel (tee+denim+sneaker, knit+trousers+loafer, jacket+pants+boot)
- [x] Art direction frozen with spec block at top of StudioView.swift
- [x] No hero effects: no spotlight, aura, glow, vignette

### Known Issues
- White garments (shirt, AF1 shoes) lost detail during color-key reprocessing — need fresh source images through full pipeline (rembg → normalize v2)
- Railway deploy not yet done — push needed to verify 500-fix in prod

## Next Session
```
Les CONTINUE.md.

1. Deploy til Railway og verifiser:
   curl -H "X-API-Key: <key>" https://coret-production.up.railway.app/api/garments

2. Last opp nye bilder for hvite plagg:
   POST /api/garments/{id}/image — full pipeline håndterer hvite plagg riktig

3. Test Studio i simulator:
   - Triple-tap for hero-only mode
   - Verifiser at alle 3 test-outfits ser premium ut
   - Sjekk at insight card + actions + nav passer på skjermen

4. Neste UI-arbeid:
   - Wardrobe tab: match gallery-retning
   - Discover tab: match gallery-retning
   - Profile tab: match gallery-retning
```

## Architecture
- Middleware: pure ASGI (no BaseHTTPMiddleware)
- Image pipeline: isolate (rembg/Photoroom) → normalize v2 (category canvas, transparent) → store
- Studio: frozen gallery art direction, ZStack overlap, per-category shadows
- Bottom nav: floating .ultraThinMaterial pill, warm tones
- Art direction spec: top of StudioView.swift (frozen, requires design review to change)
