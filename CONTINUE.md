# CORET – Continue
Last updated: 2026-03-23

## Status
```
Engine:    387/387 ✅ (17 suites + Fashion Intelligence)
Backend:   248/248 ✅ (49 endpoints, security hardened)
Shopify:   LIVE — bdsxrs-cz.myshopify.com, 18 products synced
iOS:       ViewModels + Persistence READY — Views NOT built yet
Total:     853 tester, 0 feil
```

## What Is Ready (DO NOT rebuild)
- Engine: 17 engines + Fashion Intelligence (29 rules, i18n)
- Backend: 49 endpoints, strict auth, 31 security vulns fixed
- Shopify: Client Credentials Grant, Product Enrichment Layer
- ViewModels: WardrobeVM, StudioVM, DiscoverVM, ProfileVM (all updated)
- Persistence: 6 SwiftData entities + EngineCoordinator
- Moodboards: 13 HTML files defining exact UI

## What Needs Building (Xcode on Mac)

### STEP 1: Create Xcode Project
1. Open Xcode → New Project → iOS App → "CORET"
2. Interface: SwiftUI, Language: Swift
3. File → Add Package Dependencies → Add Local → select `engine/` folder
4. Drag `ios/` files into project:
   - Persistence/ (6 files)
   - Coordinators/ (1 file)
   - ViewModels/ (4 files)
5. Build → fix any import issues

### STEP 2: ContentView.swift (Tab Bar)
```
TabView:
  Tab 1: WardrobeView — icon: wardrobe
  Tab 2: StudioView — icon: star
  Tab 3: DiscoverView — icon: magnifyingglass
Profile: top-right menu icon (not a tab)
```
Reference: moodboard/navigation/coret-nav-system.html

### STEP 3: WardrobeView.swift (Build First)
Hero block:
  - Clarity score (ClarityEngine)
  - Best outfit today (BestOutfitFinder)
  - Primary gap (OptimizeEngineV2)
Filter bar: Category, Archetype, Silhouette
2-column grid with garment cards
Gap cards (dashed border)
(+) FAB → Add Item Sheet

Reference: moodboard/wardrobe/coret-wardrobe-v4.html
ViewModel: WardrobeViewModel.swift (ready)

### STEP 4: StudioView.swift
Flat lay canvas with garment slots
Side drawer for accessories (grip tab)
Live score (Flyt/Farger/Balanse bars)
Archetype pill + "Bruk i dag" CTA
Surprise button

Reference: moodboard/studio/coret-studio.html
ViewModel: StudioViewModel.swift (ready)

### STEP 5: DiscoverView.swift
70/30 + Full toggle
Full-screen swipe cards
Right-side actions (Like/Hook/Pass)
Score watermark
Bottom info panel (brands, outfit name, tags)
Missing piece highlight
Brand grid (Full mode)

Reference: moodboard/discover/coret-discover.html
ViewModel: DiscoverViewModel.swift (ready)

### STEP 6: Connect to Backend
Backend runs on Railway or localhost.
Base URL: configure in app settings.
All endpoints documented in CLAUDE.md.

## Color Tokens (SwiftUI)
```swift
extension Color {
    // Light theme
    static let bg     = Color(hex: "FDFAF6")
    static let surface = Color(hex: "F5F0E8")
    static let gold   = Color(hex: "B8860B")
    static let sage   = Color(hex: "5A8A5E")
    static let text   = Color(hex: "18140C")
    static let text2  = Color(hex: "5A5040")
    static let text3  = Color(hex: "8A7D68")

    // Dark theme
    static let bgDark     = Color(hex: "0E0C0A")
    static let surfaceDark = Color(hex: "1A1714")
    static let goldDark   = Color(hex: "C9A96E")
}
```

## Typography
- Titles: Instrument Serif (add to project fonts)
- Body: DM Sans (add to project fonts)
- Fallback: system fonts until custom fonts added

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
