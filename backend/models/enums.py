"""
CORET Backend — Enums

Disse enum-klassene speiler Swift-engine sine typer NOYAKTIG.
Kilde: core-v2/Sources/COREEngine/Models/Garment.swift

Viktig: Hvis du endrer en enum her, MÅ du ogsa oppdatere Swift-versjonen
i Garment.swift — de to må alltid vaere identiske.

Python-enum med (str, Enum) betyr at verdien er en tekststreng.
Det gjor at FastAPI automatisk serialiserer dem som JSON-strenger.
"""

from enum import Enum


class Category(str, Enum):
    """Plagg-kategori — 4 hovedgrupper.
    Brukes av engine for å beregne garderobebalanse."""
    upper = "upper"          # Overdel: t-skjorte, genser, jakke
    lower = "lower"          # Underdel: bukser, shorts, skjort
    shoes = "shoes"          # Sko: sneakers, boots, loafers
    accessory = "accessory"  # Tilbehor: belte, skjerf, caps, veske


class BaseGroup(str, Enum):
    """Spesifikk plaggtype — 19 typer fordelt på 4 kategorier.
    Engine bruker dette for å beregne capsule wardrobe-ratios."""

    # --- Upper (overdeler) ---
    tee = "tee"              # T-skjorte
    shirt = "shirt"          # Skjorte (button-down, oxford)
    knit = "knit"            # Strikk (genser, pullover, cardigan)
    hoodie = "hoodie"        # Hoodie / sweatshirt
    blazer = "blazer"        # Blazer / dressjakke
    coat = "coat"            # Ytterjakke / kåpe / parka

    # --- Lower (underdeler) ---
    jeans = "jeans"          # Jeans / denim
    chinos = "chinos"        # Chinos
    trousers = "trousers"    # Bukser (dressbukser, slacks)
    shorts = "shorts"        # Shorts
    skirt = "skirt"          # Skjort

    # --- Shoes (sko) ---
    sneakers = "sneakers"    # Sneakers / treningssko
    boots = "boots"          # Boots / stoveletter
    loafers = "loafers"      # Loafers / mokkasiner
    sandals = "sandals"      # Sandaler / slides

    # --- Accessory (tilbehor) ---
    belt = "belt"            # Belte
    scarf = "scarf"          # Skjerf / sjal
    cap = "cap"              # Caps / lue / hatt
    bag = "bag"              # Veske / ryggsekk / tote


class ColorTemp(str, Enum):
    """Fargetemperatur — brukes av CohesionEngine for fargeharmoni.
    Warm + cool i samme antrekk = 0.5 score (clash).
    Samme temperatur = 1.0 score (harmoni)."""
    warm = "warm"        # Varme toner: rod, oransje, gul
    cool = "cool"        # Kalde toner: blå, gronn, lilla
    neutral = "neutral"  # Noytral: svart, hvit, grå, beige


class ImportSource(str, Enum):
    """Hvordan plagget ble lagt til i CORET.
    Brukes for analyse og sporing av input-metode."""
    camera = "camera"                # Fotografert med kamera
    email = "email"                  # Importert via e-post
    zalando = "zalando"              # Fra Zalando
    hm = "hm"                       # Fra H&M
    manual = "manual"                # Manuelt lagt inn
    barcode = "barcode"              # NY: Skannet strekkode
    product_search = "productSearch" # NY: Sokt etter produkt


# Mapping: BaseGroup -> Category
# Samme mapping som OptimizeEngineV2.categoryForBaseGroup i Swift-engine.
# Brukes av metadata_extractor for å utlede kategori fra plaggtype.
BASEGROUP_TO_CATEGORY: dict[str, Category] = {
    # Upper
    "tee": Category.upper,
    "shirt": Category.upper,
    "knit": Category.upper,
    "hoodie": Category.upper,
    "blazer": Category.upper,
    "coat": Category.upper,
    # Lower
    "jeans": Category.lower,
    "chinos": Category.lower,
    "trousers": Category.lower,
    "shorts": Category.lower,
    "skirt": Category.lower,
    # Shoes
    "sneakers": Category.shoes,
    "boots": Category.shoes,
    "loafers": Category.shoes,
    "sandals": Category.shoes,
    # Accessory
    "belt": Category.accessory,
    "scarf": Category.accessory,
    "cap": Category.accessory,
    "bag": Category.accessory,
}
