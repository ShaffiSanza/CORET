"""
CORET Backend — Receipt Parser Service

Parser kvitteringer fra nettbutikker (HTML/tekst) og henter ut plagginformasjon.
Støtter: Zalando, H&M, ASOS, Arket.
"""

import re
from services.metadata_extractor import extract_metadata


# Regex-mønstre per forhandler
RETAILER_PATTERNS: dict[str, dict] = {
    "zalando": {
        "senders": ["noreply@zalando", "order@zalando", "zalando"],
        "item_pattern": r'(?:class="[^"]*item[^"]*"[^>]*>|<tr[^>]*>)\s*.*?(?:product[_-]?name|item[_-]?title|article)[^>]*>\s*([^<]+)',
        "brand_pattern": r'(?:brand|merke|designer)[^>]*>\s*([^<]+)',
        "fallback_pattern": r'(\d+)\s*x\s+([A-Za-zÆØÅæøå][\w\s&\'-]+?)(?:\s*[-–]\s*|\s+(?:Str|Size|Størrelse))',
    },
    "hm": {
        "senders": ["noreply@hm.com", "hm.com", "h&m"],
        "item_pattern": r'(?:product[_-]?name|art[_-]?name)[^>]*>\s*([^<]+)',
        "brand_pattern": None,  # H&M er alltid merket
        "fallback_pattern": r'(\d+)\s*x\s+([A-Za-zÆØÅæøå][\w\s&\'-]+?)(?:\s*[-–])',
    },
    "asos": {
        "senders": ["noreply@asos.com", "asos.com"],
        "item_pattern": r'(?:product[_-]?name|item[_-]?description)[^>]*>\s*([^<]+)',
        "brand_pattern": r'(?:brand)[^>]*>\s*([^<]+)',
        "fallback_pattern": r'([A-Za-z][\w\s&\'-]+?)(?:\s*[-–]\s*(?:Size|Colour))',
    },
    "arket": {
        "senders": ["noreply@arket.com", "arket.com"],
        "item_pattern": r'(?:product[_-]?name|item[_-]?title)[^>]*>\s*([^<]+)',
        "brand_pattern": None,  # Arket er alltid merket
        "fallback_pattern": r'(\d+)\s*x\s+([A-Za-zÆØÅæøå][\w\s&\'-]+)',
    },
}


def detect_retailer(sender: str) -> str | None:
    """Identifiser forhandler fra avsender-adresse."""
    sender_lower = sender.lower()
    for retailer, config in RETAILER_PATTERNS.items():
        for s in config["senders"]:
            if s in sender_lower:
                return retailer
    return None


def parse_receipt(email_html: str, sender: str) -> dict:
    """
    Parse en kvittering og hent ut plagg-kandidater.

    Parametere:
        email_html: HTML-innhold fra e-posten
        sender: Avsender-adresse (f.eks. 'noreply@zalando.no')

    Returnerer:
        {
            "items": [{"product_title": "...", "brand": "...", "suggested_base_group": "...", ...}],
            "retailer": "zalando",
            "success": True
        }
    """
    retailer = detect_retailer(sender)

    if not retailer:
        return {
            "items": [],
            "retailer": None,
            "success": False,
            "error": f"Ukjent forhandler: {sender}"
        }

    config = RETAILER_PATTERNS[retailer]
    items = []

    # Forsøk primær HTML-parsing
    if config["item_pattern"]:
        matches = re.findall(config["item_pattern"], email_html, re.IGNORECASE | re.DOTALL)
        for match in matches:
            title = match.strip() if isinstance(match, str) else match[-1].strip()
            if title and len(title) > 2:
                items.append(_build_item(title, retailer, config, email_html))

    # Fallback til enklere mønster
    if not items and config.get("fallback_pattern"):
        matches = re.findall(config["fallback_pattern"], email_html, re.IGNORECASE)
        for match in matches:
            title = match[-1].strip() if isinstance(match, tuple) else match.strip()
            if title and len(title) > 2:
                items.append(_build_item(title, retailer, config, email_html))

    # Fjern duplikater
    seen = set()
    unique_items = []
    for item in items:
        key = item["product_title"].lower()
        if key not in seen:
            seen.add(key)
            unique_items.append(item)

    return {
        "items": unique_items,
        "retailer": retailer,
        "success": len(unique_items) > 0
    }


def _build_item(title: str, retailer: str, config: dict, html: str) -> dict:
    """Bygg et plagg-objekt fra parsed data."""
    # Sett merke
    brand = None
    if config.get("brand_pattern"):
        brand_match = re.search(config["brand_pattern"], html, re.IGNORECASE)
        if brand_match:
            brand = brand_match.group(1).strip()

    if not brand:
        brand_map = {"hm": "H&M", "arket": "ARKET"}
        brand = brand_map.get(retailer)

    # Bruk metadata_extractor for å gjette baseGroup/category
    metadata = extract_metadata(title, brand)

    return {
        "product_title": title,
        "brand": brand,
        "suggested_base_group": metadata["suggested_base_group"].value if metadata["suggested_base_group"] else None,
        "suggested_category": metadata["suggested_category"].value if metadata["suggested_category"] else None,
        "confidence": metadata["confidence"],
    }
