# CORET – Continue
Last updated: 2026-03-23

## Completed This Session (22-23 Mars 2026)

### Dag 1 (22. mars) — Backend + Discover + Shopify
- [x] Discover moodboard visual upgrade (TikTok-style actions, score watermark, scroll dots, 70/30+Full toggle)
- [x] Discover feed backend: 7030 + full modes, tag filter, style_context, brand_id
- [x] Discover bookmarks, action logging (like/pass/hook), seen-cards tracking
- [x] Shopify Admin API client: async httpx, pagination, rate limiting, style inference
- [x] Ghost catalog: brand registry, product sync + cache, gap-to-product matching, brand grid
- [x] Brand-rom i Full Discover: GET /api/discover/brands → brand grid → brand-filtered feed
- [x] User profile: GET/PUT /api/profile (style_context + archetype)
- [x] Style context: menswear/womenswear/unisex/fluid ghost-plagg filtering
- [x] 9 backend-forbedringer: sync cooldown, full-mode scoring, hook auto-bookmark, seen tracking, outfit dedup, reason generation, onboarding guard
- [x] Dark theme moodboard + light theme moodboard
- [x] Brand pitch (Nilah) med SVG mockup, premium HTML
- [x] UGC/Discover roadmap låst i feature_roadmap_v1.md
- [x] Full audit: docs synced med faktisk kodebase

### Dag 2 (23. mars) — Fashion Intelligence + Security + Shopify Live
- [x] Fashion Intelligence System: 29 JSON-regler, 9 moduler, FashionTheoryEngine + RulePriorityEngine + ExplanationEngine
- [x] i18n system: semantic tokens + templates (no.json + en.json), variable injection, locale fallback
- [x] Nye regler: color_depth (3), season_logic (2), shoe_matching (4), accessory_boost (3)
- [x] Security hardening: tokens ut av brands.json, security headers (HSTS/CSP/XSS), input validation (max_length + strip), webhook HMAC, security logger
- [x] Shopify OAuth: state+nonce+TTL, scope verification, token binding, preview tokens, idempotency, rate limit per shop
- [x] Strict auth mode: auth_type per brand (oauth/client_credentials), AuthError (ingen silent fallback), brand.status = auth_failed/active
- [x] Product Enrichment Layer: 3-lags system (category defaults → title heuristics → manual overrides), read-time, raw cache urørt
- [x] Shopify test-butikk live: bdsxrs-cz.myshopify.com, 18 produkter synket via Client Credentials Grant
- [x] Preview outfits generert: SAFE=90, CORE=76, UPGRADE=86 (+10), ASPIRATIONAL=89, WILDCARD=75
- [x] Missing piece felt: "siste plagget som fullfører outfiten" på DiscoverCard
- [x] Studio moodboard upgraded: atelier grid, SVG icons, deeper shadows
- [x] Architecture map fullstendig oppdatert og verifisert
- [x] Seed script: backend/scripts/seed_test_store.py (18 test-plagg via Admin API)

## Build Status
```
engine (V2): 387/387 passing (17 suites + Fashion Intelligence)
backend: 246/246 passing (49 endpoints)
archive/core-v1 (V1): 218/218 passing (archived)
ios/: NOT compilable on Linux — requires Mac + Xcode
Total: 633 tester, 0 feil
```

## In Progress
Nothing interrupted.

## Next Session Prompt
```
CORET — resuming. Read CLAUDE.md, then CONTINUE.md.

Engine: 387/387 tests (17 engines + Fashion Intelligence).
Backend: 246/246 tests (49 endpoints).
Shopify LIVE: bdsxrs-cz.myshopify.com, 18 products synced.
Missing piece field on DiscoverCard — ready for SwiftUI.

Remaining Arch Linux work:
- Oppdater Nilah-pitch med "siste plagget"-posisjonering
- Landing page / waitlist for beta users
- Cloud image storage (swap local disk → S3/R2)

When Mac is available:
- SwiftUI views (moodboards → SwiftUI)
- missing_piece UI: "Du mangler bare denne vesken"
- EngineCoordinator → Discover ViewModel
- TestFlight beta
```

## Decisions Made
- Shopify Admin REST API (not Storefront) — gives full product access
- Products cached locally as JSON per brand — avoids repeated API calls
- Ghost catalog tries live products first, falls back to placeholder
- Tokens ALDRI i brands.json — ENV first, brand_secrets.json fallback (gitignored)
- Strict auth: auth_type per brand (oauth | client_credentials), ingen silent fallback
- AuthError on failure (aldri tom liste), ConfigError on missing creds
- brand.status = "auth_failed" on 401, "active" on successful sync
- Client Credentials Grant for test-butikk (auto 24h token)
- Product Enrichment Layer: 3-lags (defaults → heuristics → overrides), read-time, raw cache urørt
- Webhook HMAC validation (raw body, timing-safe), security headers (HSTS preload, CSP)
- Fashion Intelligence: 29 regler i JSON, i18n med semantic tokens (no/en), locale fallback
- UGC: aldri egen tab/modus. Injiseres i 70/30 feed i V2 kun hvis thresholds. Låst mars 2026.
- Full Discover: V1 = brand-rom. V3 = algoritmisk feed.
- Pris: i data (missing_piece.price), men IKKE i feed-UI. SwiftUI bestemmer visning.
- Sett-støtte (tracksuit/co-ord): V1.5, ikke nå. Missing piece = single items only.
- Missing piece: present KUN med nøyaktig 1 ghost + user owns >= 2 items
