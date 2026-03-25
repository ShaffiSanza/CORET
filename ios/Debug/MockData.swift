import Foundation
import COREEngine

/// Pre-populated mock data from the live CORET Test Shopify store.
/// 18 real garments with correct categories, silhouettes, and color temperatures.
/// Used for simulator testing — gives all views real data from first launch.
///
/// Usage in EngineCoordinator:
///   if garments.isEmpty { let mocks = MockData.seedGarments(); ... }

enum MockData {

    static func seedGarments() -> [Garment] {
        let monthAgo = Date().addingTimeInterval(-2592000)
        let weekAgo = Date().addingTimeInterval(-604800)
        let dayAgo = Date().addingTimeInterval(-86400)

        return [
            // ═══ OUTERWEAR (4) ═══
            g("Navy Wool Coat",           .upper, .coat,     .relaxed,   .cool,    "#1E2A3A", key: true,  fav: false, date: monthAgo, img: ""),
            g("Burgundy Leather Jacket",  .upper, .coat,     .fitted,    .warm,    "#6B1A1A", key: true,  fav: true,  date: monthAgo, img: ""),
            g("Olive Bomber Jacket",      .upper, .coat,     .relaxed,   .neutral, "#4A5A30", key: false, fav: false, date: weekAgo,  img: ""),
            g("Black Wool Blazer",        .upper, .blazer,   .fitted,    .neutral, "#1A1A1E", key: true,  fav: false, date: monthAgo, img: ""),

            // ═══ TOPS (5) ═══
            g("White Oxford Shirt",       .upper, .shirt,    .fitted,    .neutral, "#F5F0EA", key: true,  fav: false, date: monthAgo, img: ""),
            g("Black Basic Tee",          .upper, .tee,      .fitted,    .neutral, "#1A1A1E", key: false, fav: false, date: monthAgo, img: ""),
            g("Grey Merino Knit",         .upper, .knit,     .regular,   .neutral, "#8A8A8A", key: true,  fav: false, date: weekAgo,  img: ""),
            g("Navy Cotton Polo",         .upper, .shirt,    .fitted,    .cool,    "#1E2A3A", key: false, fav: false, date: weekAgo,  img: ""),
            g("Cream Heavy Hoodie",       .upper, .hoodie,   .oversized, .warm,    "#E8DCC8", key: false, fav: false, date: dayAgo,   img: ""),

            // ═══ BOTTOMS (5) ═══
            g("Dark Wash Slim Jeans",     .lower, .jeans,    .slim,      .cool,    "#1A2030", key: true,  fav: false, date: monthAgo, img: ""),
            g("Beige Cotton Chinos",      .lower, .chinos,   .tapered,   .warm,    "#C4B89A", key: true,  fav: false, date: monthAgo, img: ""),
            g("Black Wool Trousers",      .lower, .trousers, .regular,   .neutral, "#1A1A1E", key: false, fav: false, date: weekAgo,  img: ""),
            g("Charcoal Flannel Pants",   .lower, .trousers, .wide,      .neutral, "#3A3A3E", key: false, fav: false, date: weekAgo,  img: ""),
            g("Navy Cotton Shorts",       .lower, .shorts,   .regular,   .cool,    "#1E2A3A", key: false, fav: false, date: dayAgo,   img: ""),

            // ═══ SHOES (4) ═══
            g("Black Leather Loafers",    .shoes, .loafers,  .none,      .neutral, "#1A1A1E", key: true,  fav: false, date: monthAgo, img: ""),
            g("White Minimalist Sneakers", .shoes, .sneakers, .none,     .neutral, "#F0EDE8", key: false, fav: false, date: monthAgo, img: ""),
            g("Brown Chelsea Boots",      .shoes, .boots,    .none,      .warm,    "#5A3020", key: false, fav: false, date: weekAgo,  img: ""),
            g("Black Derby Shoes",        .shoes, .loafers,  .none,      .neutral, "#1A1A1E", key: false, fav: false, date: weekAgo,  img: ""),

            // ═══ ACCESSORIES (3) ═══
            g("Brown Leather Belt",       .accessory, .belt,   .none,      .warm,    "#5A3820", key: false, fav: false, date: monthAgo, img: ""),
            g("Grey Wool Scarf",          .accessory, .scarf,  .none,      .neutral, "#7A7A7A", key: false, fav: false, date: weekAgo,  img: ""),
            g("Black Canvas Bag",         .accessory, .bag,    .none,      .neutral, "#2A2A2E", key: false, fav: false, date: dayAgo,   img: ""),
        ]
    }

    static func seedWearLogs(for garments: [Garment]) -> [WearLog] {
        var logs: [WearLog] = []
        let now = Date()
        for (index, garment) in garments.enumerated() {
            let wearCount = max(1, 5 - (index / 4))
            for day in 0..<wearCount {
                logs.append(WearLog(
                    garmentID: garment.id,
                    date: now.addingTimeInterval(-Double(day * 3 + index) * 86400)
                ))
            }
        }
        return logs
    }

    static func defaultProfile() -> UserProfile {
        UserProfile(primaryArchetype: .smartCasual)
    }

    // MARK: - Private Helper

    private static func g(
        _ name: String,
        _ category: Category,
        _ baseGroup: BaseGroup,
        _ silhouette: Silhouette,
        _ colorTemp: ColorTemp,
        _ dominantColor: String,
        key: Bool,
        fav: Bool,
        date: Date,
        img: String = ""
    ) -> Garment {
        Garment(
            id: UUID(),
            image: img,
            name: name,
            category: category,
            silhouette: silhouette,
            baseGroup: baseGroup,
            colorTemperature: colorTemp,
            dominantColor: dominantColor,
            isFavorite: fav,
            isKeyGarment: key,
            dateAdded: date,
            source: .manual,
            brand: "CORET Test"
        )
    }
}
