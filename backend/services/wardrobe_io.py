"""
CORET Backend — Wardrobe Export/Import Service

Validerer og forbereder garderobe-data for import/eksport.
Støtter JSON-basert backup, migrasjon, og B2B-deling.
"""

from models.enums import Category, BaseGroup, ColorTemp, BASEGROUP_TO_CATEGORY


# Gyldige verdier for validering
VALID_CATEGORIES = {e.value for e in Category}
VALID_BASE_GROUPS = {e.value for e in BaseGroup}
VALID_COLOR_TEMPS = {e.value for e in ColorTemp}
VALID_SILHOUETTES = {"fitted", "relaxed", "tapered", "oversized", "slim", "regular", "wide", "none"}
VALID_ARCHETYPES = {"tailored", "smartCasual", "street"}
VALID_USAGE_CONTEXTS = {"everyday", "smart", "active"}
VALID_IMPORT_SOURCES = {"camera", "email", "zalando", "hm", "manual", "barcode", "productSearch"}


def validate_import(data: dict) -> dict:
    """
    Valider garderobe-data for import.

    Parametere:
        data: {"garments": [...], "profile": {...}}

    Returnerer:
        {
            "valid": True/False,
            "warnings": [...],
            "errors": [...],
            "garment_count": int,
            "success": True
        }
    """
    warnings = []
    errors = []

    garments = data.get("garments", [])
    profile = data.get("profile")

    if not isinstance(garments, list):
        return {
            "valid": False,
            "warnings": [],
            "errors": ["'garments' must be a list"],
            "garment_count": 0,
            "success": True
        }

    # Valider profil
    if profile:
        if not isinstance(profile, dict):
            errors.append("'profile' must be an object")
        else:
            archetype = profile.get("primaryArchetype")
            if archetype and archetype not in VALID_ARCHETYPES:
                errors.append(f"Invalid primaryArchetype: '{archetype}'. Valid: {sorted(VALID_ARCHETYPES)}")

    # Valider hvert plagg
    for i, garment in enumerate(garments):
        if not isinstance(garment, dict):
            errors.append(f"garments[{i}]: must be an object")
            continue

        # Påkrevde felter
        category = garment.get("category")
        base_group = garment.get("baseGroup")

        if not category:
            errors.append(f"garments[{i}]: missing 'category'")
        elif category not in VALID_CATEGORIES:
            errors.append(f"garments[{i}]: invalid category '{category}'. Valid: {sorted(VALID_CATEGORIES)}")

        if not base_group:
            errors.append(f"garments[{i}]: missing 'baseGroup'")
        elif base_group not in VALID_BASE_GROUPS:
            errors.append(f"garments[{i}]: invalid baseGroup '{base_group}'. Valid: {sorted(VALID_BASE_GROUPS)}")

        # Sjekk at baseGroup matcher category
        if base_group and category and base_group in VALID_BASE_GROUPS and category in VALID_CATEGORIES:
            expected_category = BASEGROUP_TO_CATEGORY.get(base_group)
            if expected_category and expected_category.value != category:
                warnings.append(
                    f"garments[{i}]: baseGroup '{base_group}' belongs to category "
                    f"'{expected_category.value}', not '{category}'"
                )

        # Valgfrie felter
        silhouette = garment.get("silhouette")
        if silhouette and silhouette not in VALID_SILHOUETTES:
            warnings.append(f"garments[{i}]: unknown silhouette '{silhouette}'")

        color_temp = garment.get("colorTemperature")
        if color_temp and color_temp not in VALID_COLOR_TEMPS:
            warnings.append(f"garments[{i}]: unknown colorTemperature '{color_temp}'")

        usage = garment.get("usageContext")
        if usage and usage not in VALID_USAGE_CONTEXTS:
            warnings.append(f"garments[{i}]: unknown usageContext '{usage}'")

        # Manglende men anbefalte felter
        if not garment.get("name"):
            warnings.append(f"garments[{i}]: missing 'name' (recommended)")
        if not garment.get("dominantColor"):
            warnings.append(f"garments[{i}]: missing 'dominantColor' (recommended)")

    valid = len(errors) == 0
    return {
        "valid": valid,
        "warnings": warnings,
        "errors": errors,
        "garment_count": len(garments),
        "success": True
    }
