# CORET – Data Model V1

Designed for SwiftUI + SwiftData (local-first).

---

# Core Entities

## 1️⃣ WardrobeItem

id: UUID  
imagePath: String  

category: ItemCategory  
silhouette: Silhouette  

rawColor: ColorName  
baseGroup: BaseGroup  
temperature: Temperature  

archetypeTag: Archetype  

customColorOverride: Bool  

usageCount: Int  
lastWornDate: Date?  

createdAt: Date  

---

# Enums

## ItemCategory
- top
- bottom
- shoes
- outerwear

## Silhouette
- structured
- balanced
- relaxed

## BaseGroup
- neutral
- deep
- light
- accent

## Temperature
- warm
- cool
- neutral

## Archetype
- structuredMinimal
- relaxedStreet
- smartCasual
- etc (expandable)

---

## 2️⃣ UserProfile

id: UUID  

primaryArchetype: Archetype  
secondaryArchetype: Archetype  

seasonMode: SeasonMode  

createdAt: Date  

---

## SeasonMode
- springSummer
- autumnWinter

---

## 3️⃣ CohesionSnapshot

id: UUID  

alignmentScore: Double  
densityScore: Double  
paletteScore: Double  
rotationScore: Double  

totalScore: Double  
statusLevel: CohesionStatus  

createdAt: Date  

---

## CohesionStatus
- structuring
- refining
- coherent
- aligned
- architected

---

# Design Notes

- Local-first storage
- No ML dependency
- Deterministic engine
- Snapshots allow Structural Evolution tracking