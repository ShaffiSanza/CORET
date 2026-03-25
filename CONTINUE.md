# CORET – Continue
Last updated: 2026-03-25

## Status
```
Engine:    387/387 ✅ (17 suites + Fashion Intelligence)
Backend:   248/248 ✅ (49 endpoints, security hardened)
iOS Views: ALL WRITTEN — Xcode project exists (CORET.xcodeproj)
Shopify:   LIVE — bdsxrs-cz.myshopify.com, 18 products (no images yet)
Photoroom: API key set ✅ (Pro plan, background removal working)
Railway:   CRITICAL BUG — 500 on all auth endpoints (see below)
Total:     853 tester, 0 feil (engine + backend locally)
```

## What Works Now
- Engine: 387/387 tests, all engines + Fashion Intelligence
- Backend: 248/248 tests locally, all endpoints work on localhost
- Shopify: 18 test products synced, Client Credentials Grant auth
- Photoroom: API key configured, background removal verified working
- Product search: SerpAPI → download thumbnail → Photoroom bg removal → normalize → save
- iOS: All SwiftUI views written, 4-tab nav, MockData with 18 real products

## CRITICAL BUG: Railway Deploy Returns 500

**All authenticated endpoints return 500 Internal Server Error on Railway.**
Health + docs work fine.

Root cause: `BaseHTTPMiddleware` in Starlette 0.52.1 crashes when
`raise HTTPException` is called inside `dispatch()`. Causes
`ExceptionGroup: unhandled errors in a TaskGroup`.

Three middlewares affected:
- `SecurityHeadersMiddleware` — line 125 in main.py
- `APIKeyMiddleware` — raises 401, line 113
- `RateLimitMiddleware` — raises 429, line 78

**Fix (not yet applied):**
Replace `raise HTTPException(...)` with `return JSONResponse(status_code=..., content={...})`
in all three middlewares. This avoids the Starlette TaskGroup bug entirely.

```python
# BEFORE (crashes on Railway):
raise HTTPException(status_code=401, detail="...")

# AFTER (works):
from starlette.responses import JSONResponse
return JSONResponse(status_code=401, content={"detail": "..."})
```

File: `backend/main.py`
Test after fix: `curl -H "X-API-Key: <key>" https://coret-production.up.railway.app/api/garments`

**Already tried (did not fix):**
- fcntl graceful fallback — not the issue (Railway is Linux)
- SecurityHeadersMiddleware try/except — doesn't help (Starlette internals)

## What Was Done This Session (Arch Linux, 25 March)

### Fixes pushed:
- [x] fcntl graceful fallback in all 4 store files (garment, outfit, wear_log, clarity)
- [x] SecurityHeadersMiddleware try/except (partial fix, not sufficient)
- [x] Documented Railway bug in CLAUDE.md with root cause + solution

### Moodboard alignment:
- [x] Wardrobe moodboard: Bento hero, colored rects, gold key borders, stagger
- [x] Studio moodboard: removed "Flat Lay", score pulse, primary/secondary CTA, drawer hint
- [x] Discover moodboard: missing piece above reason, swipe feedback, haptic hint
- [x] Profile moodboard: tab 4, avatar 60pt, identity 26pt, elevation, text3 contrast

### Photoroom:
- [x] Photoroom Pro activated
- [x] API key set in backend/.env (PHOTOROOM_API_KEY)
- [x] Background removal tested and verified working
- [x] product_search.py already has full pipeline: search → download → bg removal → normalize → save

### HTTPS verification:
- [x] Railway enforces HTTPS (HTTP → 301 redirect)
- [x] HSTS header present with preload
- [x] All references in docs use https://

## What Is Ready (DO NOT rebuild)
- Engine: 17 engines + Fashion Intelligence (29 rules, i18n)
- Backend: 49 endpoints, strict auth, security hardened
- Shopify: Client Credentials Grant, Product Enrichment Layer
- ViewModels: WardrobeVM, StudioVM, DiscoverVM, ProfileVM
- Persistence: 7 SwiftData entities + EngineCoordinator
- Views: All SwiftUI views + sheets + design system
- Photoroom: Background removal pipeline working
- Moodboards: All 4 aligned with SwiftUI views

## Next Steps

### PRIORITY 1: Fix Railway 500 (Mac session)
Fix `backend/main.py` — replace `raise HTTPException` with `return JSONResponse`
in all three BaseHTTPMiddleware classes. Push → Railway auto-deploys.

### PRIORITY 2: Add images to Shopify test products
Products have no images. Update seed script or manually add via Shopify Admin.
Pipeline is ready: search → Photoroom bg removal → normalize → variants.

### PRIORITY 3: Xcode build + simulator
- Verify all views compile in Xcode
- Run on simulator with MockData
- Test add garment flow with product search + Photoroom

### PRIORITY 4: Apple Vision background removal (production)
For on-device camera flow. Use VNGenerateForegroundInstanceMaskRequest (iOS 17+).
Eliminates need for Photoroom API in production.

## Decisions Locked
- 4 tabs: Wardrobe, Studio, Discover, Profile
- Missing piece: show on ghost cards, price hidden in feed (show on tap)
- Style context: invisible to user, controls ghost filtering
- Full Discover: brand-rom (one brand at a time), not cross-brand mix (V1)
- Background removal: Photoroom for backend/search, Apple Vision for iOS camera (V2)
- UGC: never a tab, V2 injection only with thresholds

## Environment
- Arch Linux: engine + backend development
- Mac: iOS/SwiftUI + Xcode + Railway CLI
- Photoroom Pro: API key in backend/.env
- SerpAPI: key in backend/.env
- Shopify: bdsxrs-cz.myshopify.com (Client Credentials in .env)
