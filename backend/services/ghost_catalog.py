"""
CORET Backend — Ghost Catalog Service

Replaces the static GHOST_CATALOG placeholder in discover_feed.py
with live products from registered brand partners' Shopify stores.

Ghost garments fill structural gaps detected by wardrobe analysis:
- Category gaps (missing upper/lower/shoes)
- Proportion imbalance (too many uppers vs lowers)
- Layer gaps (missing color temperature diversity)

Products are cached locally (JSON) after sync to avoid repeated API calls.
Cache is refreshed on brand sync (POST /api/brands/{id}/sync).
"""

import json
import logging
import os
import re
import uuid
from datetime import datetime, timezone
from pathlib import Path

logger = logging.getLogger(__name__)

_SHOPIFY_DOMAIN_RE = re.compile(r"^[a-z0-9][a-z0-9\-]*\.myshopify\.com$")

from services.shopify_client import fetch_products, map_product_type

DATA_DIR = Path(__file__).parent.parent / "data"
BRAND_SECRETS_FILE = DATA_DIR / "brand_secrets.json"
BRANDS_FILE = DATA_DIR / "brands.json"
PRODUCT_CACHE_DIR = DATA_DIR / "shopify_cache"


# ═══ TOKEN MANAGEMENT ═══
# ENV first, encrypted secrets file fallback. Never in brands.json.

import base64
import hashlib

def _get_encryption_key() -> bytes:
    """Derive a 32-byte key from CORET_API_KEY or fallback."""
    from config import settings as _s
    seed = _s.coret_api_key or "coret-dev-key-not-for-production"
    return hashlib.sha256(seed.encode()).digest()

def _xor_crypt(data: bytes, key: bytes) -> bytes:
    """Simple XOR encryption — sufficient for at-rest token obfuscation."""
    return bytes(b ^ key[i % len(key)] for i, b in enumerate(data))

def _load_secrets() -> dict[str, str]:
    if not BRAND_SECRETS_FILE.exists():
        return {}
    raw = BRAND_SECRETS_FILE.read_bytes()
    try:
        # Try encrypted format first
        decrypted = _xor_crypt(base64.b64decode(raw), _get_encryption_key())
        return json.loads(decrypted)
    except Exception:
        # Fallback: legacy plaintext JSON
        return json.loads(raw)


def _save_secrets(secrets: dict[str, str]):
    key = _get_encryption_key()
    plaintext = json.dumps(secrets).encode()
    encrypted = base64.b64encode(_xor_crypt(plaintext, key))
    BRAND_SECRETS_FILE.write_bytes(encrypted)


def _store_token(brand_id: str, token: str):
    """Store token encrypted in secrets file. In production, prefer env vars."""
    secrets = _load_secrets()
    secrets[brand_id] = token
    _save_secrets(secrets)


def _get_token(brand_id: str) -> str | None:
    """Get token: ENV first (SHOPIFY_TOKEN_{brand_id}), secrets file fallback."""
    env_key = f"SHOPIFY_TOKEN_{brand_id.replace('-', '_').upper()}"
    token = os.environ.get(env_key)
    if token:
        return token
    secrets = _load_secrets()
    return secrets.get(brand_id)


# ═══ BRAND REGISTRY ═══

def _load_brands() -> list[dict]:
    if BRANDS_FILE.exists():
        return json.loads(BRANDS_FILE.read_text())
    return []


def _save_brands(brands: list[dict]):
    BRANDS_FILE.write_text(json.dumps(brands, indent=2))


def register_brand(name: str, shopify_domain: str, access_token: str,
                   archetype: str = "smartCasual",
                   cover_image_url: str | None = None) -> dict:
    """Register a new brand partner."""
    if not _SHOPIFY_DOMAIN_RE.match(shopify_domain.lower()):
        return {"error": "Invalid Shopify domain. Must be *.myshopify.com"}

    brands = _load_brands()

    # Don't duplicate
    for b in brands:
        if b["shopify_domain"] == shopify_domain:
            return b

    brand_id = str(uuid.uuid4())

    # Determine auth_type and store token if OAuth
    if access_token and access_token.startswith("shp"):
        auth_type = "oauth"
        _store_token(brand_id, access_token)
    else:
        auth_type = "client_credentials"
        # No token to store — will use Client Credentials Grant

    brand = {
        "id": brand_id,
        "name": name,
        "shopify_domain": shopify_domain,
        "archetype": archetype,
        "cover_image_url": cover_image_url,
        "auth_type": auth_type,
        "status": "registered",
        "product_count": 0,
        "synced_at": None,
    }
    brands.append(brand)
    _save_brands(brands)
    return brand


def get_brand(brand_id: str) -> dict | None:
    brands = _load_brands()
    for b in brands:
        if b["id"] == brand_id:
            return b
    return None


def list_brands() -> list[dict]:
    brands = _load_brands()
    # Strip access_token from response
    return [{k: v for k, v in b.items() if k != "access_token"} for b in brands]


def delete_brand(brand_id: str) -> bool:
    brands = _load_brands()
    new = [b for b in brands if b["id"] != brand_id]
    if len(new) == len(brands):
        return False
    _save_brands(new)
    # Clean up cache + secrets
    cache_file = PRODUCT_CACHE_DIR / f"{brand_id}.json"
    if cache_file.exists():
        cache_file.unlink()
    secrets = _load_secrets()
    secrets.pop(brand_id, None)
    _save_secrets(secrets)
    return True


def get_brand_card(brand: dict) -> dict:
    """Build a BrandCard dict for the brand grid.
    Uses cover_image_url if set, otherwise first product image from cache."""
    brand_id = brand["id"]
    cover = brand.get("cover_image_url")
    style_tags: list[str] = []
    products = _load_cached_products(brand_id)

    if not cover and products:
        # Fallback to first product image
        for p in products:
            if p.get("image_url"):
                cover = p["image_url"]
                break

    # Extract top 5 style tags from products
    from collections import Counter
    tag_counts: Counter = Counter()
    for p in products:
        for t in p.get("tags", []):
            tag_counts[t.lower()] += 1
    style_tags = [tag for tag, _ in tag_counts.most_common(5)]

    return {
        "id": brand_id,
        "name": brand["name"],
        "archetype": brand.get("archetype", "smartCasual"),
        "product_count": brand.get("product_count", 0),
        "cover_image": cover,
        "style_tags": style_tags,
    }


def get_brand_grid() -> list[dict]:
    """Get all brands as BrandCards for the Discover brand grid."""
    brands = _load_brands()
    return [get_brand_card(b) for b in brands]


# ═══ PRODUCT SYNC ═══

def _cache_path(brand_id: str) -> Path:
    PRODUCT_CACHE_DIR.mkdir(parents=True, exist_ok=True)
    return PRODUCT_CACHE_DIR / f"{brand_id}.json"


def _load_cached_products(brand_id: str) -> list[dict]:
    """Load cached products and apply enrichment layer (color_temperature, silhouette).
    Raw cache is never modified — enrichment is applied at read time."""
    path = _cache_path(brand_id)
    if path.exists():
        raw = json.loads(path.read_text())
        from services.product_enricher import enrich
        return enrich(raw)
    return []


def _save_cached_products(brand_id: str, products: list[dict]):
    path = _cache_path(brand_id)
    path.write_text(json.dumps(products, indent=2))


SYNC_COOLDOWN_SECONDS = 900  # 15 minutes between syncs per brand


async def sync_brand_products(brand_id: str) -> dict:
    """Fetch all products from a brand's Shopify store and cache them.
    Returns sync status with product count. Rate limited to 1 sync per 15 min."""
    brand = get_brand(brand_id)
    if not brand:
        return {"success": False, "error": "Brand not found"}

    # Rate limit: check last sync time
    last_sync = brand.get("synced_at")
    if last_sync:
        last_dt = datetime.fromisoformat(last_sync)
        elapsed = (datetime.now(timezone.utc) - last_dt).total_seconds()
        if elapsed < SYNC_COOLDOWN_SECONDS:
            remaining = int(SYNC_COOLDOWN_SECONDS - elapsed)
            return {
                "success": False,
                "error": f"Sync cooldown active. Retry in {remaining}s.",
                "retry_after": remaining,
            }

    # Strict auth — deterministic, no fallback
    from config import settings
    from services.shopify_client import AuthError, ConfigError
    from services.security_logger import logger

    auth_type = brand.get("auth_type", "client_credentials")
    logger.info("Sync brand %s via %s", brand_id, auth_type)

    try:
        if auth_type == "oauth":
            token = _get_token(brand_id)
            if not token:
                raise AuthError("No stored token for OAuth brand")
            products = await fetch_products(
                domain=brand["shopify_domain"],
                access_token=token,
                limit=500,
            )
        else:  # client_credentials
            if not settings.shopify_api_key or not settings.shopify_api_secret:
                raise ConfigError("Missing SHOPIFY_API_KEY or SHOPIFY_API_SECRET in config")
            products = await fetch_products(
                domain=brand["shopify_domain"],
                client_id=settings.shopify_api_key,
                client_secret=settings.shopify_api_secret,
                limit=500,
            )
    except AuthError as e:
        logger.warning("Auth failed for brand %s (%s): %s", brand_id, auth_type, e)
        # Set brand status to auth_failed
        brands = _load_brands()
        for b in brands:
            if b["id"] == brand_id:
                b["status"] = "auth_failed"
        _save_brands(brands)
        return {"success": False, "error": "auth_failed", "message": "Authentication failed for this brand"}
    except ConfigError as e:
        logger.error("Config error during brand sync %s: %s", brand_id, e)
        return {"success": False, "error": "config_error", "message": "Server configuration error"}

    # Filter to only CORET-mappable products (has category)
    mappable = [p for p in products if p.get("category")]

    _save_cached_products(brand_id, mappable)

    # Update brand record — set status active (recovery from auth_failed)
    brands = _load_brands()
    for b in brands:
        if b["id"] == brand_id:
            b["product_count"] = len(mappable)
            b["synced_at"] = datetime.now(timezone.utc).isoformat()
            b["status"] = "active"
            break
    _save_brands(brands)

    return {
        "success": True,
        "brand_id": brand_id,
        "total_fetched": len(products),
        "mappable": len(mappable),
        "unmappable": len(products) - len(mappable),
    }


def get_brand_products(brand_id: str) -> list[dict]:
    """Get cached products for a brand."""
    return _load_cached_products(brand_id)


# ═══ GAP-TO-PRODUCT MATCHING ═══

def get_ghost_garments(gaps: list[dict], max_ghosts: int = 8,
                       style_context: str = "unisex",
                       brand_id: str | None = None) -> list[dict]:
    """Match detected wardrobe gaps to products from registered brands.

    Args:
        gaps: From wardrobe_analysis.detect_gaps() — list of GapResult dicts
        max_ghosts: Max ghost garments to return
        style_context: User's style context for filtering (menswear/womenswear/unisex/fluid)
        brand_id: If set, only use products from this specific brand

    Returns list of product dicts with is_ghost=True, ready for DiscoverGarment.
    """
    # Load cached products — from specific brand or all brands
    all_products: list[dict] = []
    brands = _load_brands()
    for brand in brands:
        if brand_id and brand["id"] != brand_id:
            continue
        products = _load_cached_products(brand["id"])
        for p in products:
            p["brand"] = brand["name"]
        all_products.extend(products)

    # Filter by style_context
    all_products = _filter_by_style(all_products, style_context)

    if not all_products:
        # No brand products synced — return empty (discover_feed.py falls back to placeholder)
        return []

    # Build category index
    by_category: dict[str, list[dict]] = {}
    for p in all_products:
        cat = p.get("category")
        if cat:
            by_category.setdefault(cat, []).append(p)

    ghosts: list[dict] = []
    seen_ids: set[int] = set()

    for gap in gaps:
        gap_type = gap.get("type", "")

        if gap_type == "category":
            # Missing entire category — suggest products from that category
            desc = gap.get("description", "").lower()
            target_cat = None
            if "overdel" in desc or "upper" in desc:
                target_cat = "upper"
            elif "underdel" in desc or "lower" in desc:
                target_cat = "lower"
            elif "sko" in desc or "shoes" in desc:
                target_cat = "shoes"

            if target_cat and target_cat in by_category:
                for p in by_category[target_cat][:3]:
                    if p["shopify_id"] not in seen_ids:
                        seen_ids.add(p["shopify_id"])
                        ghosts.append(_product_to_ghost(p, gap_type))

        elif gap_type == "proportion":
            # Imbalance — suggest from underrepresented category
            desc = gap.get("suggestion", "").lower()
            if "underdel" in desc or "lower" in desc:
                for p in by_category.get("lower", [])[:2]:
                    if p["shopify_id"] not in seen_ids:
                        seen_ids.add(p["shopify_id"])
                        ghosts.append(_product_to_ghost(p, gap_type))
            elif "overdel" in desc or "upper" in desc:
                for p in by_category.get("upper", [])[:2]:
                    if p["shopify_id"] not in seen_ids:
                        seen_ids.add(p["shopify_id"])
                        ghosts.append(_product_to_ghost(p, gap_type))

        elif gap_type == "layer":
            # Missing color temperature diversity — suggest neutral items
            for cat_products in by_category.values():
                for p in cat_products:
                    if p["shopify_id"] not in seen_ids and p.get("color_temperature") == "neutral":
                        seen_ids.add(p["shopify_id"])
                        ghosts.append(_product_to_ghost(p, gap_type))
                        break

        if len(ghosts) >= max_ghosts:
            break

    return ghosts[:max_ghosts]


def _filter_by_style(products: list[dict], style_context: str) -> list[dict]:
    """Filter products by user's style_context.
    menswear → menswear + unisex
    womenswear → womenswear + unisex
    unisex/fluid → everything"""
    if style_context in ("unisex", "fluid"):
        return products
    allowed = {style_context, "unisex"}
    return [p for p in products if p.get("style_context", "unisex") in allowed]


def _product_to_ghost(product: dict, fills_gap: str) -> dict:
    """Convert a cached Shopify product to a ghost garment dict
    compatible with discover_feed._build_card()."""
    return {
        "id": f"ghost-{product['shopify_id']}",
        "name": product["title"],
        "category": product.get("category", ""),
        "base_group": product.get("base_group", ""),
        "color_temperature": product.get("color_temperature"),
        "dominant_color": None,
        "image_url": product.get("image_url"),
        "brand": product.get("brand", product.get("vendor", "")),
        "price": product.get("price"),
        "shop_url": product.get("shop_url"),
        "available": product.get("available", True),
        "fills_gap": fills_gap,
    }
