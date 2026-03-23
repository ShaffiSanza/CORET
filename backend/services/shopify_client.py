"""
CORET Backend — Shopify Admin API Client

Async httpx client for Shopify Admin REST API (2024-01).
Handles pagination (Link header), rate limiting (retry on 429),
and product type → CORET category mapping.

Usage:
    products = await fetch_products("brand.myshopify.com", "token123")
    product = await fetch_product("brand.myshopify.com", "token123", 123456)
"""

import asyncio
import httpx


class AuthError(Exception):
    """Shopify authentication failed. Never fall back silently."""
    pass


class ConfigError(Exception):
    """Missing required configuration for auth."""
    pass

API_VERSION = "2024-01"
MAX_RETRIES = 3
RETRY_DELAY = 2.0  # seconds
PAGE_LIMIT = 50  # products per page


# ═══ PRODUCT TYPE → CORET MAPPING ═══
# Maps Shopify product_type strings to CORET category + base_group.
# Case-insensitive matching. Extend as brands onboard.
PRODUCT_TYPE_MAP = {
    # Upper
    "t-shirt": ("upper", "tee"),
    "tee": ("upper", "tee"),
    "t-skjorte": ("upper", "tee"),
    "shirt": ("upper", "shirt"),
    "skjorte": ("upper", "shirt"),
    "oxford": ("upper", "shirt"),
    "knit": ("upper", "knit"),
    "sweater": ("upper", "knit"),
    "genser": ("upper", "knit"),
    "strikk": ("upper", "knit"),
    "cardigan": ("upper", "knit"),
    "hoodie": ("upper", "hoodie"),
    "sweatshirt": ("upper", "hoodie"),
    "blazer": ("upper", "blazer"),
    "coat": ("upper", "coat"),
    "jacket": ("upper", "coat"),
    "jakke": ("upper", "coat"),
    "parka": ("upper", "coat"),
    "frakk": ("upper", "coat"),
    # Lower
    "jeans": ("lower", "jeans"),
    "denim": ("lower", "jeans"),
    "chinos": ("lower", "chinos"),
    "trousers": ("lower", "trousers"),
    "bukser": ("lower", "trousers"),
    "pants": ("lower", "trousers"),
    "shorts": ("lower", "shorts"),
    "skirt": ("lower", "skirt"),
    "skjort": ("lower", "skirt"),
    # Shoes
    "sneakers": ("shoes", "sneakers"),
    "trainers": ("shoes", "sneakers"),
    "boots": ("shoes", "boots"),
    "støvler": ("shoes", "boots"),
    "loafers": ("shoes", "loafers"),
    "sandals": ("shoes", "sandals"),
    "sandaler": ("shoes", "sandals"),
    # Accessories
    "belt": ("accessory", "belt"),
    "belte": ("accessory", "belt"),
    "scarf": ("accessory", "scarf"),
    "skjerf": ("accessory", "scarf"),
    "cap": ("accessory", "cap"),
    "hat": ("accessory", "cap"),
    "bag": ("accessory", "bag"),
    "veske": ("accessory", "bag"),
}


def map_product_type(product_type: str) -> tuple[str | None, str | None]:
    """Map a Shopify product_type to CORET (category, base_group).
    Returns (None, None) if no mapping found."""
    key = product_type.strip().lower()
    if key in PRODUCT_TYPE_MAP:
        return PRODUCT_TYPE_MAP[key]
    # Try partial matching
    for term, mapping in PRODUCT_TYPE_MAP.items():
        if term in key or key in term:
            return mapping
    return None, None


def _parse_product(product: dict, domain: str) -> dict:
    """Parse a Shopify product JSON into our format."""
    images = product.get("images", [])
    image_url = images[0]["src"] if images else None

    variants = product.get("variants", [])
    prices = [float(v["price"]) for v in variants if v.get("price")]
    price = min(prices) if prices else None
    available = any(v.get("available", True) for v in variants)

    product_type = product.get("product_type", "")
    category, base_group = map_product_type(product_type)

    tags_raw = product.get("tags", "")
    tags = [t.strip() for t in tags_raw.split(",") if t.strip()] if isinstance(tags_raw, str) else tags_raw

    handle = product.get("handle", "")
    shop_url = f"https://{domain}/products/{handle}" if handle else None

    style_context = _infer_style_context(tags, product.get("title", ""))

    return {
        "shopify_id": product["id"],
        "title": product.get("title", ""),
        "vendor": product.get("vendor", ""),
        "product_type": product_type,
        "image_url": image_url,
        "price": price,
        "shop_url": shop_url,
        "available": available,
        "tags": tags,
        "category": category,
        "base_group": base_group,
        "color_temperature": None,  # derived later from image/color extraction
        "style_context": style_context,
    }


# ═══ STYLE CONTEXT INFERENCE ═══
# Keywords that indicate menswear or womenswear in tags/title.
_MENSWEAR_KEYWORDS = {"men", "mens", "men's", "herre", "herr", "male", "man"}
_WOMENSWEAR_KEYWORDS = {"women", "womens", "women's", "dame", "damer", "female", "woman", "kvinner"}
_UNISEX_KEYWORDS = {"unisex", "gender-neutral", "genderless"}


def _infer_style_context(tags: list[str], title: str) -> str:
    """Infer style_context from product tags and title.
    Returns 'menswear', 'womenswear', or 'unisex' (default)."""
    text = " ".join(t.lower() for t in tags) + " " + title.lower()
    tokens = set(text.replace("'", "").replace("-", " ").split())

    if tokens & _UNISEX_KEYWORDS:
        return "unisex"
    has_men = bool(tokens & _MENSWEAR_KEYWORDS)
    has_women = bool(tokens & _WOMENSWEAR_KEYWORDS)
    if has_men and has_women:
        return "unisex"
    if has_men:
        return "menswear"
    if has_women:
        return "womenswear"
    return "unisex"


async def authenticate_client_credentials(domain: str, client_id: str, client_secret: str) -> str:
    """Authenticate via Client Credentials Grant. Returns access token (24h TTL).
    Raises AuthError on failure."""
    url = f"https://{domain}/admin/oauth/access_token"
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.post(url, json={
                "client_id": client_id,
                "client_secret": client_secret,
                "grant_type": "client_credentials",
            }, timeout=15.0)
        if resp.status_code >= 400:
            raise AuthError(f"Client Credentials auth failed: HTTP {resp.status_code}")
        token = resp.json().get("access_token")
        if not token:
            raise AuthError("Client Credentials auth returned no token")
        return token
    except httpx.RequestError as e:
        raise AuthError(f"Client Credentials auth request failed: {type(e).__name__}")


async def fetch_products(
    domain: str,
    access_token: str | None = None,
    client_id: str | None = None,
    client_secret: str | None = None,
    collection_id: int | None = None,
    product_type: str | None = None,
    limit: int = 250,
) -> list[dict]:
    """Fetch products from Shopify Admin API with pagination.

    Auth: pass access_token directly, OR client_id + client_secret
    for automatic Client Credentials Grant.

    Args:
        domain: Shopify store domain (e.g. "brand.myshopify.com")
        access_token: Admin API access token (optional if client_id/secret given)
        client_id: App client ID for Client Credentials Grant
        client_secret: App client secret for Client Credentials Grant
        collection_id: Optional filter by collection
        product_type: Optional filter by product type
        limit: Max total products to fetch (default 250)

    Returns list of parsed product dicts.
    """
    # Strict auth: use exactly one method, never both, never fallback
    if access_token:
        # OAuth path — use provided token as-is
        pass
    elif client_id and client_secret:
        # Client Credentials path — exchange for token (raises AuthError on failure)
        access_token = await authenticate_client_credentials(domain, client_id, client_secret)
    else:
        raise AuthError("No auth method provided: need access_token or client_id+client_secret")

    url = f"https://{domain}/admin/api/{API_VERSION}/products.json"
    headers = {"X-Shopify-Access-Token": access_token}
    params: dict = {"limit": min(PAGE_LIMIT, limit)}

    if collection_id:
        params["collection_id"] = collection_id
    if product_type:
        params["product_type"] = product_type

    all_products: list[dict] = []

    async with httpx.AsyncClient() as client:
        for _ in range(20):  # max 20 pages safety limit
            response = await _request_with_retry(client, url, headers, params)
            if response is None:
                break

            data = response.json()
            products = data.get("products", [])
            if not products:
                break

            for p in products:
                all_products.append(_parse_product(p, domain))
                if len(all_products) >= limit:
                    return all_products

            # Pagination via Link header
            next_url = _parse_next_link(response.headers.get("link", ""), domain)
            if not next_url:
                break
            url = next_url
            params = {}  # params are in the URL now

    return all_products


async def fetch_product(domain: str, access_token: str, product_id: int) -> dict | None:
    """Fetch a single product by ID."""
    url = f"https://{domain}/admin/api/{API_VERSION}/products/{product_id}.json"
    headers = {"X-Shopify-Access-Token": access_token}

    async with httpx.AsyncClient() as client:
        response = await _request_with_retry(client, url, headers)
        if response is None:
            return None
        data = response.json()
        product = data.get("product")
        if not product:
            return None
        return _parse_product(product, domain)


async def _request_with_retry(
    client: httpx.AsyncClient,
    url: str,
    headers: dict,
    params: dict | None = None,
) -> httpx.Response | None:
    """Make request with retry on 429 (rate limit)."""
    for attempt in range(MAX_RETRIES):
        try:
            response = await client.get(url, headers=headers, params=params, timeout=15.0)
        except httpx.RequestError:
            return None

        if response.status_code == 200:
            return response
        if response.status_code == 429:
            retry_after = float(response.headers.get("Retry-After", RETRY_DELAY))
            await asyncio.sleep(retry_after)
            continue
        # Other error — don't retry
        return None

    return None


def _parse_next_link(link_header: str, domain: str = "") -> str | None:
    """Parse Link header for next page URL.
    Format: <https://...?page_info=X>; rel="next"
    Validates URL belongs to expected Shopify domain to prevent SSRF.
    """
    if not link_header:
        return None
    for part in link_header.split(","):
        part = part.strip()
        if 'rel="next"' in part:
            next_url = part.split(";")[0].strip().strip("<>")
            # SSRF protection: verify URL belongs to expected domain
            if domain and not next_url.startswith(f"https://{domain}/"):
                return None
            return next_url
    return None


class ShopifyClient:
    """Wrapper that validates pagination URLs against expected domain."""

    def __init__(self, domain: str):
        self.domain = domain

    def parse_next_link(self, link_header: str) -> str | None:
        next_url = _parse_next_link(link_header)
        if next_url and not next_url.startswith(f"https://{self.domain}/"):
            return None
        return next_url
