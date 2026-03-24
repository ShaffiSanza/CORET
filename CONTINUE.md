# CORET – Continue
Last updated: 2026-03-24

## Status
```
Engine:    387/387 ✅ (17 suites + Fashion Intelligence)
Backend:   248/248 ✅ (49 endpoints, security hardened)
iOS Views: ALL WRITTEN — needs Xcode build verification
Total:     853 tester, 0 feil (engine + backend)
```

## Completed This Session
- [x] Cloned repo on new Mac
- [x] Installed Python 3.12, backend 248/248 passing
- [x] Installed Swift 6.2.4 via swiftly, engine 387/387 passing
- [x] Added platform targets to Package.swift (macOS 13, iOS 17)
- [x] Added TestImports.swift for Category disambiguation
- [x] Wrote CORETApp.swift (entry point + SwiftData container)
- [x] Wrote ContentView.swift (custom floating tab bar, 3 tabs + profile)
- [x] Wrote WardrobeView.swift (hero, filters, 2-col grid, FAB, empty state)
- [x] Wrote StudioView.swift (flat lay slots, live scoring, accessory drawer)
- [x] Wrote DiscoverView.swift (swipe cards, 70/30+Full modes, actions)
- [x] Wrote ProfileView.swift (identity, archetype, season, milestones, settings)
- [x] Wrote AddGarmentSheet.swift (form + live projection preview)
- [x] Wrote GarmentDetailSheet.swift (role analysis, removal simulation)
- [x] Added DesignSystem.swift (color tokens, typography, glass card, theme)
- [x] Extended EngineCoordinator with bestOutfit(), primaryGap(), logWear()
- [x] Extended WardrobeViewModel with projectionForAdding(), profile accessor

## What Is Ready (DO NOT rebuild)
- Engine: 17 engines + Fashion Intelligence (29 rules, i18n)
- Backend: 49 endpoints, strict auth, 31 security vulns fixed
- Shopify: Client Credentials Grant, Product Enrichment Layer
- ViewModels: WardrobeVM, StudioVM, DiscoverVM, ProfileVM (all updated)
- Persistence: 6 SwiftData entities + EngineCoordinator
- Views: All 8 SwiftUI views written (see ios/Views/ and ios/App/)
- Design: DesignSystem.swift with full theme system

## Next Steps (Xcode Required)

### STEP 1: Open in Xcode and Build
1. Open Xcode → New Project → iOS App → "CORET" (or use existing .xcodeproj)
2. Interface: SwiftUI, Language: Swift, minimum deployment: iOS 17
3. File → Add Package Dependencies → Add Local → select `engine/` folder
4. Drag ALL ios/ folders into project:
   - App/ (2 files: CORETApp.swift, ContentView.swift)
   - Views/ (6 files)
   - ViewModels/ (4 files)
   - Persistence/ (7 files)
   - Coordinators/ (1 file)
   - Design/ (1 file)
5. Delete auto-generated ContentView.swift and App file from Xcode template
6. Build → fix any import issues

### STEP 2: Fix Compilation Errors
Known issues to resolve in Xcode:
- Ensure COREEngine package is properly linked to iOS target
- SwiftData @Model macros need Xcode compilation (not terminal)
- May need `import SwiftData` adjustments

### STEP 3: Run on Simulator
- Select iPhone 15 Pro simulator
- Build and Run (Cmd+R)
- Verify 3-tab navigation works
- Test add garment flow

### STEP 4: Polish
- Add custom fonts (Instrument Serif, DM Sans) to project
- Replace emoji garment placeholders with real images (camera capture)
- Connect to backend API (replace TODO stubs in ViewModels)

## Color Tokens (in DesignSystem.swift)
Already implemented — see ios/Design/DesignSystem.swift

## Key Architecture Rules
- ViewModels NEVER call engines directly — only through EngineCoordinator
- All public types: Codable, Sendable
- Engine is pure functions, no state
- SwiftData is local-first, no cloud sync in V1

## Decisions Locked
- 3 tabs: Wardrobe, Studio, Discover. Profile via menu icon.
- Missing piece: show on ghost cards, price hidden in feed (show on tap)
- Style context: invisible to user, controls ghost filtering
- UGC: never a tab, V2 injection only with thresholds
- Fashion Intelligence: 29 rules, i18n (no/en), ExplanationResult on OutfitScore

## Environment Notes (this Mac)
- Swift 6.2.4 installed via swiftly (not Xcode toolchain)
- Python 3.12 in backend/.venv
- Git HTTPS via gh auth (SSH not configured)
- Tailscale partially installed (needs App Store login for full setup)
