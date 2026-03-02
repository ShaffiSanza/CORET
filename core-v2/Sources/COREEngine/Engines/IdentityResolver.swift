import Foundation

/// Derives structural identity from wardrobe composition.
/// Produces labels, tags, and prose for Dashboard hero and Journey screen.
public enum IdentityResolver: Sendable {

    // MARK: - Public API

    /// Full identity resolution from wardrobe state.
    public static func resolve(items: [Garment], profile: UserProfile) -> WardrobeIdentity {
        guard !items.isEmpty else {
            return WardrobeIdentity(
                dominantSilhouette: nil,
                dominantColorTemperature: .neutral,
                dominantArchetype: profile.primaryArchetype,
                identityLabel: "Blandet · Nøytral",
                tags: ["Ukjent profil"],
                prose: "Legg til plagg for å utlede profil.",
                createdAt: Date()
            )
        }

        let silhouette = dominantSilhouette(items: items)
        let colorTemp = dominantColorTemperature(items: items)
        let archetype = dominantArchetype(items: items, profile: profile)
        let label = buildLabel(silhouette: silhouette, colorTemp: colorTemp)
        let tags = buildTags(items: items, silhouette: silhouette, colorTemp: colorTemp, archetype: archetype)
        let prose = buildProse(silhouette: silhouette, colorTemp: colorTemp, archetype: archetype)

        return WardrobeIdentity(
            dominantSilhouette: silhouette,
            dominantColorTemperature: colorTemp,
            dominantArchetype: archetype,
            identityLabel: label,
            tags: tags,
            prose: prose,
            createdAt: Date()
        )
    }

    /// Short identity label: "Strukturert · Varm"
    public static func identityLabel(items: [Garment], profile: UserProfile) -> String {
        guard !items.isEmpty else { return "Blandet · Nøytral" }
        let silhouette = dominantSilhouette(items: items)
        let colorTemp = dominantColorTemperature(items: items)
        return buildLabel(silhouette: silhouette, colorTemp: colorTemp)
    }

    /// Identity tags (3–4 descriptors).
    public static func identityTags(items: [Garment], profile: UserProfile) -> [String] {
        guard !items.isEmpty else { return ["Ukjent profil"] }
        let silhouette = dominantSilhouette(items: items)
        let colorTemp = dominantColorTemperature(items: items)
        let archetype = dominantArchetype(items: items, profile: profile)
        return buildTags(items: items, silhouette: silhouette, colorTemp: colorTemp, archetype: archetype)
    }

    // MARK: - Internal Resolution

    private static func dominantSilhouette(items: [Garment]) -> Silhouette? {
        let silhouettes = items.map(\.silhouette).filter { $0 != .none }
        return ScoringHelpers.plurality(silhouettes)
    }

    private static func dominantColorTemperature(items: [Garment]) -> ColorTemp {
        let temps = items.map(\.colorTemperature)
        return ScoringHelpers.plurality(temps) ?? .neutral
    }

    private static func dominantArchetype(items: [Garment], profile: UserProfile) -> Archetype {
        let scores = CohesionEngine.allArchetypeScores(items: items)
        let maxScore = scores.values.max() ?? 0
        let winners = scores.filter { $0.value == maxScore }.map(\.key)

        if winners.count == 1 {
            return winners[0]
        }
        // Tie → profile's primary archetype if it's among winners, else first alphabetically
        if winners.contains(profile.primaryArchetype) {
            return profile.primaryArchetype
        }
        return winners.sorted(by: { $0.rawValue < $1.rawValue }).first ?? profile.primaryArchetype
    }

    // MARK: - Label Building

    private static func buildLabel(silhouette: Silhouette?, colorTemp: ColorTemp) -> String {
        let silLabel = silhouetteLabel(silhouette)
        let tempLabel = colorTempLabel(colorTemp)
        return "\(silLabel) · \(tempLabel)"
    }

    private static func silhouetteLabel(_ silhouette: Silhouette?) -> String {
        guard let sil = silhouette else { return "Blandet" }
        switch sil {
        case .fitted:    return "Strukturert"
        case .relaxed:   return "Avslappet"
        case .tapered:   return "Tilspisset"
        case .oversized: return "Overdimensjonert"
        case .slim:      return "Slank"
        case .regular:   return "Klassisk"
        case .wide:      return "Vid"
        case .none:      return "Blandet"
        }
    }

    private static func colorTempLabel(_ temp: ColorTemp) -> String {
        switch temp {
        case .warm:    return "Varm"
        case .cool:    return "Kald"
        case .neutral: return "Nøytral"
        }
    }

    // MARK: - Tags

    private static func buildTags(items: [Garment], silhouette: Silhouette?, colorTemp: ColorTemp, archetype: Archetype) -> [String] {
        var tags: [String] = []

        // 1. Silhouette tag
        if let sil = silhouette {
            tags.append(silhouetteTag(sil))
        } else {
            tags.append("Blandet silhuett")
        }

        // 2. Color temperature tag
        tags.append(colorTempTag(colorTemp))

        // 3. Archetype tag
        tags.append(archetypeTag(archetype))

        // 4. Conditional layering tag
        let upperLayers = Set(items.filter { $0.category == .upper && $0.temperature != nil }.compactMap(\.temperature))
        if upperLayers.count >= 2 {
            tags.append("Lag-vennlig")
        }

        return tags
    }

    private static func silhouetteTag(_ sil: Silhouette) -> String {
        switch sil {
        case .fitted:    return "Strukturert form"
        case .relaxed:   return "Avslappet form"
        case .tapered:   return "Tilspisset form"
        case .oversized: return "Overdimensjonert form"
        case .slim:      return "Slank form"
        case .regular:   return "Klassisk form"
        case .wide:      return "Vid form"
        case .none:      return "Blandet silhuett"
        }
    }

    private static func colorTempTag(_ temp: ColorTemp) -> String {
        switch temp {
        case .warm:    return "Varme toner"
        case .cool:    return "Kalde toner"
        case .neutral: return "Nøytral base"
        }
    }

    private static func archetypeTag(_ archetype: Archetype) -> String {
        switch archetype {
        case .tailored:    return "Formell profil"
        case .smartCasual: return "Smart casual"
        case .street:      return "Gatestil"
        }
    }

    // MARK: - Prose

    private static func buildProse(silhouette: Silhouette?, colorTemp: ColorTemp, archetype: Archetype) -> String {
        let silKey = silhouette ?? .none
        switch (silKey, colorTemp, archetype) {
        // Fitted variations
        case (.fitted, .warm, .tailored):
            return "Garderoben din er strukturert og varm, med en tydelig formell retning."
        case (.fitted, .cool, .tailored):
            return "En skarp, kjølig garderobe med sterk formell identitet."
        case (.fitted, .neutral, .tailored):
            return "Nøytral og strukturert — en klassisk formell base."
        case (.fitted, .warm, .smartCasual):
            return "Strukturert form med varme toner gir en tilgjengelig, polert stil."
        case (.fitted, .cool, .smartCasual):
            return "Kjølige toner og stram passform skaper en moderne smart casual profil."
        case (.fitted, .neutral, .smartCasual):
            return "En balansert og strukturert garderobe med smart casual fundament."
        case (.fitted, .warm, .street):
            return "Stramme linjer møter varme farger i en urban profil."
        case (.fitted, .cool, .street):
            return "Kjølig og stramt — en skarp gatesilhuett."
        case (.fitted, .neutral, .street):
            return "Nøytral base med strukturert gatestil."

        // Relaxed variations
        case (.relaxed, .warm, .tailored):
            return "En avslappet varme med formell undertone — uanstrengt eleganse."
        case (.relaxed, .cool, .tailored):
            return "Kjølige toner i en avslappet ramme med formell dybde."
        case (.relaxed, .neutral, .tailored):
            return "Rolig og avslappet med formell struktur i bunn."
        case (.relaxed, .warm, .smartCasual):
            return "Varm og avslappet — en naturlig smart casual profil."
        case (.relaxed, .cool, .smartCasual):
            return "Kjølig og avslappet med en smart casual balanse."
        case (.relaxed, .neutral, .smartCasual):
            return "Nøytral og avslappet — en allsidig smart casual garderobe."
        case (.relaxed, .warm, .street):
            return "Avslappet og varm — en autentisk gategarderobe."
        case (.relaxed, .cool, .street):
            return "Kjølige toner og løs passform gir en avslappet urban identitet."
        case (.relaxed, .neutral, .street):
            return "Nøytral og avslappet med tydelig gatepreg."

        // Tapered variations
        case (.tapered, .warm, _):
            return "Tilspissede linjer med varme toner gir en moderne, definert profil."
        case (.tapered, .cool, _):
            return "Kjølige toner og tilspisset passform skaper en skarp silhuett."
        case (.tapered, .neutral, _):
            return "Nøytral og tilspisset — en ren, moderne garderobe."

        // Oversized variations
        case (.oversized, .warm, _):
            return "Overdimensjonerte former med varme farger — dristig og uttrykksfull."
        case (.oversized, .cool, _):
            return "Kjølige toner i store proporsjoner gir en avantgarde silhuett."
        case (.oversized, .neutral, _):
            return "Nøytral og overdimensjonert — en stille, voluminøs profil."

        // Lower-body dominant silhouettes (slim, regular, wide)
        case (.slim, _, _):
            return "Slanke linjer dominerer — en stram og fokusert garderobe."
        case (.regular, _, _):
            return "Klassiske proporsjoner gir en allsidig og balansert profil."
        case (.wide, _, _):
            return "Vide former skaper en romslig og uttrykksfull silhuett."

        // Mixed / nil silhouette
        case (.none, .warm, _):
            return "Varme toner i en blandet silhuett — garderoben søker sin form."
        case (.none, .cool, _):
            return "Kjølige farger uten tydelig formretning — strukturen utvikler seg."
        case (.none, .neutral, _):
            return "En nøytral garderobe uten dominerende form — rom for utvikling."
        }
    }
}
