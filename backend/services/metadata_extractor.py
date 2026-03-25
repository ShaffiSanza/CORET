"""
CORET Backend - Metadata Extractor Service

Denne servien tar inn en produkttittel (f.eks. "Nike Air Force 1 Snkeares") 
og gjetter hvilken CORET-plaggtype (BaseGroup) og kategori (Category) det tilhører. 

Bruker: Kun keyword-matching - ingen AI, Ingen API-Kall, Ren python-logikk.
"""

from models.enums import BaseGroup, Category, BASEGROUP_TO_CATEGORY


KEYWORDS: dict[str, list[str]] = {
    # --- Upper (overdeler) ---
    "tee": ["t-shirt", "tee", "t shirt", "t-skjorte"],
    "shirt": ["shirt", "skjorte", "oxford shirt", "button-down", "blouse", "flannel"],
    "knit": ["knit", "knitwear", "crewneck", "sweater", "genser", "pullover", "cardigan"],
    "hoodie": ["hoodie", "sweatshirt", "hettegenser", "zip-up"],
    "blazer": ["blazer", "dressjakke", "suit jacket", "sport coat"],
    "coat": ["coat", "jacket", "jakke", "parka", "frakk", "trench", "overcoat", "windbreaker", "anorak"],
    # --- Lower (underdeler) ---
    "jeans": ["jeans", "denim"],
    "chinos": ["chinos", "chino"],
    "trousers": ["trousers", "pants", "slacks", "dressbukse", "bukse"],
    "shorts": ["shorts"],
    "skirt": ["skirt", "skjørt", "skjort"],
    # --- Shoes (sko) ---
    "sneakers": ["sneakers", "sneaker", "trainers", "running shoes", "joggesko",
                  "air force", "air max", "jordan", "yeezy", "dunk", "new balance",
                  "shoes", "shoe", "sko", "footwear"],
    "boots": ["boots", "boot", "støvlett", "chelsea boot", "combat boots", "hiking boot"],
    "loafers": ["loafers", "loafer", "moccasin", "mokkasin", "derby", "oxford shoe", "brogue"],
    "sandals": ["sandals", "sandal", "slides", "flip-flops", "espadrille"],
    # --- Accessory (tilbehør) ---
    "belt": ["belt", "belte"],
    "scarf": ["scarf", "skjerf", "sjal", "shawl", "wrap"],
    "cap": ["cap", "caps", "hat", "hatt", "beanie", "lue", "bucket hat"],
    "bag": ["bag", "backpack", "tote", "ryggsekk", "veske", "duffel", "messenger", "satchel"],
}

def extract_metadata(product_title: str, brand: str | None = None, description: str | None = None) -> dict:
    """ 
    Analyser en produktittel og foreslå CORET-verdier. 

    Parametere:
    product_title: Produktnavn, f.eks. "Nike Air Force 1 Sneakers"
    Brand: Valgfritt merke, f.eks "Nike"
    description: Valgfri beskrivelse fra produktsiden

    Returnerer; 
    {
    
        "suggested_base_group": BaseGroup.sneakers,
        "suggested_category": Category.shoes,
        "confidence":0.8,
        "success": True 
    }
    """
    title_lower = product_title.lower()

    # Søk gjennom alle keywords — longest match vinner (mest spesifikk)
    matched_group = None
    best_keyword_len = 0

    for base_group, keywords in KEYWORDS.items():
        for keyword in keywords:
            if keyword in title_lower and len(keyword) > best_keyword_len:
                matched_group = base_group
                best_keyword_len = len(keyword)
    if not matched_group:
        return {
            "suggested_base_group": None,
            "suggested_category": None,
            "confidence": 0.0,
            "success": False
        }
    
    # Foreslå kategori basert på BaseGroup
    base_group = BaseGroup(matched_group)
    category = BASEGROUP_TO_CATEGORY[base_group]
    return {
        "suggested_base_group": base_group,
        "suggested_category": category,
        "confidence": 0.8,
        "success": True
    }



