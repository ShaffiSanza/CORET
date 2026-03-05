# CORET – Continue
Last updated: 2026-03-05

## Completed This Session

- [x] Revert: removed overbygde features (wardrobe_io, receipt_parser archived to v1_5)
- [x] BehaviouralEngine (27 tests) — wear patterns, drift, rotation
- [x] SimilarityEngine (18 tests) — cosine sim, duplicates, redundancy
- [x] Docs: added §29 BehaviouralEngine + §30 SimilarityEngine to ENGINE_SPECS.md
- [x] Updated CLAUDE.md engine list and test counts

## Build Status

```
engine (V2): swift test 285/285 passing
backend: python -m pytest 50/50 passing
archive/core-v1 (V1): 218/218 passing (archived)
ios/: NOT compilable on Linux — requires Mac + Xcode + Apple SDK
```

## In Progress
Nothing interrupted.

## Next Steps

1. **iOS development** (requires Mac):
   - iOS image pipeline services (ios/Services/)
   - SwiftUI Views for all 5 tabs
   - Xcode project setup
2. **Set API keys on Railway** — CORET_API_KEY, SERPAPI_KEY, PHOTOROOM_API_KEY

## Next Session Prompt

```
CORET — resuming. Read CLAUDE.md, then CONTINUE.md.

Engine: 285/285 tests (10 engines). Backend: 50/50 tests.
All specs documented in ENGINE_SPECS.md (§3-30).

Next: iOS development (requires Mac).
```
