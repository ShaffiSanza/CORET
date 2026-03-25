"""
CORET Backend - Metadata Extractor Tester
"""


from services.metadata_extractor import extract_metadata
from models.enums import BaseGroup, Category

def test_sneakers_match():
    """Test at 'snekaers' i tittlen gir BaseGroup.sneakers"""
    result = extract_metadata("Nike Air Force 1 sneakers")
    assert result["success"] is True
    assert result["suggested_base_group"] == BaseGroup.sneakers
    assert result["suggested_category"] == Category.shoes
    assert result["confidence"] == 0.8


def test_no_match():
    """Test at no match gir success=False og confidence=0.0"""
    result = extract_metadata("Uknown product 2312")
    assert result["success"] is False
    assert result["suggested_base_group"] is None
    assert result["suggested_category"] is None
    assert result["confidence"] == 0.0


def test_coat_match():
    """Test at 'coat' i tittlen gir BaseGroup.coat"""
    result = extract_metadata("Zara Whool Coat")
    assert result["success"] is True
    assert result["suggested_base_group"] == BaseGroup.coat
    assert result["suggested_category"] == Category.upper
    assert result["confidence"] == 0.8


def test_jeans_match():
    """Test at 'Jeans' i tittlen gir BaseGroup.jeans"""
    result = extract_metadata("Diesel 1990 Larkee Jeans")
    assert result["success"] is True
    assert result["suggested_base_group"] == BaseGroup.jeans
    assert result["suggested_category"] == Category.lower
    assert result["confidence"] == 0.8


def test_air_force_matches_sneakers():
    """Test at 'air force' i tittelen gir BaseGroup.sneakers"""
    result = extract_metadata("Nike Air Force 1 '07")
    assert result["success"] is True
    assert result["suggested_base_group"] == BaseGroup.sneakers
    assert result["suggested_category"] == Category.shoes


def test_shoes_matches_sneakers():
    """Test at 'shoes' i tittelen gir BaseGroup.sneakers"""
    result = extract_metadata("Running Shoes")
    assert result["success"] is True
    assert result["suggested_base_group"] == BaseGroup.sneakers
    assert result["suggested_category"] == Category.shoes


def test_oxford_shirt_matches_shirt():
    """Test at 'oxford shirt' gir BaseGroup.shirt, IKKE loafers"""
    result = extract_metadata("Uniqlo Oxford Shirt")
    assert result["success"] is True
    assert result["suggested_base_group"] == BaseGroup.shirt
    assert result["suggested_category"] == Category.upper


def test_oxford_shoes_matches_loafers():
    """Test at 'oxford shoe' gir BaseGroup.loafers, IKKE shirt"""
    result = extract_metadata("Allen Edmonds Oxford Shoes")
    assert result["success"] is True
    assert result["suggested_base_group"] == BaseGroup.loafers
    assert result["suggested_category"] == Category.shoes


def test_chelsea_boot_matches_boots():
    """Test at 'chelsea boot' gir BaseGroup.boots"""
    result = extract_metadata("Dr. Martens Chelsea Boot")
    assert result["success"] is True
    assert result["suggested_base_group"] == BaseGroup.boots
    assert result["suggested_category"] == Category.shoes


def test_denim_matches_jeans():
    """Test at 'denim' i tittelen gir BaseGroup.jeans"""
    result = extract_metadata("Slim Fit Denim")
    assert result["success"] is True
    assert result["suggested_base_group"] == BaseGroup.jeans
    assert result["suggested_category"] == Category.lower
