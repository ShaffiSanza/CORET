# CORET – Continue
Last updated: 2026-03-05

## Completed This Session

- [x] **metadata_extractor.py** — keyword-matching service (bygget av bruker)
- [x] **product_search.py** — SerpAPI integrasjon (bygget av bruker)
- [x] **barcode_lookup.py** — UPCitemdb integrasjon (bygget av bruker)
- [x] **image_polish.py** — Photoroom API proxy (bygget av bruker)
- [x] **Alle endpoints koblet** i pipeline.py
- [x] **Alle tester** — 37/37 passerer
- [x] **Railway deployment** — live på coret-production.up.railway.app
- [x] **Import-fix** — relative imports for Railway kompatibilitet
- [x] **Sikkerhet** — CORS strammet, rate limiting, API key auth, .gitignore fikset

## Build Status

```
engine (V2): swift test 244/244 passing
backend: python -m pytest 37/37 passing
archive/core-v1 (V1): 218/218 passing (archived)
ios/: NOT compilable on Linux — requires Mac + Xcode + Apple SDK
```

## Backend — COMPLETE

All services built, tested, deployed, and secured:
- color_extraction, metadata_extractor, product_search, barcode_lookup, image_polish
- Live: coret-production.up.railway.app/docs
- Security: rate limiting (30/min/IP), API key auth, CORS restricted

## Security Checklist

- [x] .env in .gitignore
- [x] API keys in environment variables (not hardcoded)
- [x] CORS restricted to own domains
- [x] Rate limiting (30 req/min per IP)
- [x] API key authentication (X-API-Key header)
- [x] HTTPS (Railway automatic)
- [ ] Set CORET_API_KEY on Railway (Variables tab) before launch

## Next Steps

1. **Set CORET_API_KEY on Railway** — Variables tab, generate with: `python -c "import secrets; print(secrets.token_urlsafe(32))"`
2. **Set API keys on Railway** — SERPAPI_KEY, PHOTOROOM_API_KEY
3. **iOS development** (requires Mac):
   - iOS image pipeline services (ios/Services/)
   - SwiftUI Views for all 5 tabs
   - Xcode project setup

## Next Session Prompt

```
CORET — resuming. Read CLAUDE.md, then CONTINUE.md.

Backend is COMPLETE and deployed:
- 5 services, 37/37 tests, live on Railway
- Security: rate limiting, API key auth, CORS

Next: iOS development (requires Mac).
Optional: set API keys on Railway Variables tab.
```
