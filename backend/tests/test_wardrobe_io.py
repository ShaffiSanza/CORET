"""
CORET Backend — Wardrobe IO Tests

Tester validering av garderobe-import.
"""

from services.wardrobe_io import validate_import


def test_valid_import():
    """Test gyldig import med korrekte data."""
    data = {
        "garments": [
            {
                "name": "White Tee",
                "category": "upper",
                "baseGroup": "tee",
                "silhouette": "regular",
                "colorTemperature": "neutral",
                "dominantColor": "#FFFFFF",
            }
        ],
        "profile": {"primaryArchetype": "smartCasual"},
    }
    result = validate_import(data)
    assert result["valid"] is True
    assert result["garment_count"] == 1
    assert len(result["errors"]) == 0


def test_missing_category():
    """Test at manglende category gir feil."""
    data = {"garments": [{"baseGroup": "tee"}]}
    result = validate_import(data)
    assert result["valid"] is False
    assert any("category" in e for e in result["errors"])


def test_missing_base_group():
    """Test at manglende baseGroup gir feil."""
    data = {"garments": [{"category": "upper"}]}
    result = validate_import(data)
    assert result["valid"] is False
    assert any("baseGroup" in e for e in result["errors"])


def test_invalid_category():
    """Test at ugyldig category gir feil."""
    data = {"garments": [{"category": "invalid", "baseGroup": "tee"}]}
    result = validate_import(data)
    assert result["valid"] is False


def test_invalid_base_group():
    """Test at ugyldig baseGroup gir feil."""
    data = {"garments": [{"category": "upper", "baseGroup": "invalid"}]}
    result = validate_import(data)
    assert result["valid"] is False


def test_mismatched_category_warning():
    """Test at feil kategori for baseGroup gir advarsel."""
    data = {"garments": [{"category": "shoes", "baseGroup": "tee", "name": "test", "dominantColor": "#000"}]}
    result = validate_import(data)
    assert result["valid"] is True  # Advarsel, ikke feil
    assert len(result["warnings"]) > 0
    assert any("belongs to category" in w for w in result["warnings"])


def test_missing_name_warning():
    """Test at manglende navn gir advarsel."""
    data = {"garments": [{"category": "upper", "baseGroup": "tee", "dominantColor": "#000"}]}
    result = validate_import(data)
    assert result["valid"] is True
    assert any("name" in w for w in result["warnings"])


def test_empty_garments():
    """Test med tom plagg-liste."""
    data = {"garments": []}
    result = validate_import(data)
    assert result["valid"] is True
    assert result["garment_count"] == 0


def test_invalid_garments_type():
    """Test at garments ikke er liste."""
    data = {"garments": "not a list"}
    result = validate_import(data)
    assert result["valid"] is False


def test_invalid_profile_archetype():
    """Test ugyldig arketype i profil."""
    data = {"garments": [], "profile": {"primaryArchetype": "invalid"}}
    result = validate_import(data)
    assert result["valid"] is False


def test_valid_archetype():
    """Test gyldig arketype i profil."""
    data = {"garments": [], "profile": {"primaryArchetype": "tailored"}}
    result = validate_import(data)
    assert result["valid"] is True


def test_multiple_garments():
    """Test med flere plagg."""
    data = {
        "garments": [
            {"category": "upper", "baseGroup": "shirt", "name": "Oxford", "dominantColor": "#FFF"},
            {"category": "lower", "baseGroup": "chinos", "name": "Beige Chinos", "dominantColor": "#D2B48C"},
            {"category": "shoes", "baseGroup": "loafers", "name": "Brown Loafers", "dominantColor": "#8B4513"},
        ]
    }
    result = validate_import(data)
    assert result["valid"] is True
    assert result["garment_count"] == 3


def test_unknown_silhouette_warning():
    """Test ukjent silhouette gir advarsel."""
    data = {"garments": [{"category": "upper", "baseGroup": "tee", "silhouette": "boxy", "name": "t", "dominantColor": "#000"}]}
    result = validate_import(data)
    assert result["valid"] is True
    assert any("silhouette" in w for w in result["warnings"])
