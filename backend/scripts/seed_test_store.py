"""
CORET — Seed Test Store

Creates 18 test garments in a Shopify store for end-to-end testing.
Reads SHOPIFY_STORE_DOMAIN + SHOPIFY_ACCESS_TOKEN from environment or .env file.

Usage:
    cd backend
    source .venv/bin/activate
    python scripts/seed_test_store.py
"""

import asyncio
import os
import sys
import time

import httpx
from dotenv import load_dotenv

# Load .env from backend directory
load_dotenv(os.path.join(os.path.dirname(__file__), "..", ".env"))

STORE_DOMAIN = os.getenv("SHOPIFY_STORE_DOMAIN", "")
CLIENT_ID = os.getenv("SHOPIFY_API_KEY", "")
CLIENT_SECRET = os.getenv("SHOPIFY_API_SECRET", "")
ACCESS_TOKEN = os.getenv("SHOPIFY_ACCESS_TOKEN", "")
API_VERSION = "2024-01"

if not STORE_DOMAIN:
    print("ERROR: Set SHOPIFY_STORE_DOMAIN in .env")
    sys.exit(1)

if not ACCESS_TOKEN and not (CLIENT_ID and CLIENT_SECRET):
    print("ERROR: Set either SHOPIFY_ACCESS_TOKEN or SHOPIFY_API_KEY + SHOPIFY_API_SECRET in .env")
    sys.exit(1)


async def get_access_token() -> str:
    """Get access token — use existing or exchange via Client Credentials Grant."""
    if ACCESS_TOKEN:
        return ACCESS_TOKEN

    print("Authenticating via Client Credentials Grant...")
    url = f"https://{STORE_DOMAIN}/admin/oauth/access_token"
    async with httpx.AsyncClient() as client:
        resp = await client.post(url, json={
            "client_id": CLIENT_ID,
            "client_secret": CLIENT_SECRET,
            "grant_type": "client_credentials",
        }, timeout=15.0)

    if resp.status_code >= 400:
        print(f"ERROR: Auth failed ({resp.status_code}): {resp.text}")
        sys.exit(1)

    token = resp.json().get("access_token")
    if not token:
        print(f"ERROR: No access_token in response: {resp.json()}")
        sys.exit(1)

    print("Authenticated successfully.")
    return token

# ═══ PRODUCT DATA ═══
# 18 garments with correct product_type tags for CORET mapping

PRODUCTS = [
    # Outerwear (4)
    {
        "title": "Navy Wool Coat",
        "product_type": "Coat",
        "vendor": "CORET Test",
        "tags": "men, outerwear, winter, navy",
        "variants": [{"price": "2499.00", "sku": "CT-COAT-NAVY"}],
        "body_html": "Classic navy wool coat for cold weather.",
    },
    {
        "title": "Burgundy Leather Jacket",
        "product_type": "Jacket",
        "vendor": "CORET Test",
        "tags": "men, outerwear, autumn, burgundy",
        "variants": [{"price": "3999.00", "sku": "CT-JACKET-BURG"}],
        "body_html": "Premium leather jacket in rich burgundy.",
    },
    {
        "title": "Olive Bomber Jacket",
        "product_type": "Jacket",
        "vendor": "CORET Test",
        "tags": "men, outerwear, spring, olive, unisex",
        "variants": [{"price": "1299.00", "sku": "CT-BOMBER-OLIVE"}],
        "body_html": "Lightweight bomber in olive green.",
    },
    {
        "title": "Black Wool Blazer",
        "product_type": "Blazer",
        "vendor": "CORET Test",
        "tags": "men, outerwear, all-season, black",
        "variants": [{"price": "2799.00", "sku": "CT-BLAZER-BLK"}],
        "body_html": "Tailored black blazer in Italian wool.",
    },

    # Tops (5)
    {
        "title": "White Oxford Shirt",
        "product_type": "Shirt",
        "vendor": "CORET Test",
        "tags": "men, tops, all-season, white",
        "variants": [{"price": "699.00", "sku": "CT-SHIRT-WHT"}],
        "body_html": "Classic white Oxford button-down.",
    },
    {
        "title": "Black Basic Tee",
        "product_type": "T-Shirt",
        "vendor": "CORET Test",
        "tags": "men, tops, all-season, black, basics",
        "variants": [{"price": "299.00", "sku": "CT-TEE-BLK"}],
        "body_html": "Essential black tee in organic cotton.",
    },
    {
        "title": "Grey Merino Knit",
        "product_type": "Knit",
        "vendor": "CORET Test",
        "tags": "men, tops, autumn, winter, grey",
        "variants": [{"price": "999.00", "sku": "CT-KNIT-GRY"}],
        "body_html": "Soft merino wool crew neck in light grey.",
    },
    {
        "title": "Navy Cotton Polo",
        "product_type": "Shirt",
        "vendor": "CORET Test",
        "tags": "men, tops, summer, navy",
        "variants": [{"price": "499.00", "sku": "CT-POLO-NVY"}],
        "body_html": "Pique cotton polo in navy.",
    },
    {
        "title": "Cream Heavy Hoodie",
        "product_type": "Hoodie",
        "vendor": "CORET Test",
        "tags": "men, tops, autumn, cream, unisex",
        "variants": [{"price": "799.00", "sku": "CT-HOOD-CRM"}],
        "body_html": "Heavyweight French terry hoodie.",
    },

    # Bottoms (5)
    {
        "title": "Dark Wash Slim Jeans",
        "product_type": "Jeans",
        "vendor": "CORET Test",
        "tags": "men, bottoms, all-season, indigo",
        "variants": [{"price": "899.00", "sku": "CT-JEANS-DRK"}],
        "body_html": "Slim fit dark wash denim.",
    },
    {
        "title": "Beige Cotton Chinos",
        "product_type": "Chinos",
        "vendor": "CORET Test",
        "tags": "men, bottoms, spring, summer, beige",
        "variants": [{"price": "699.00", "sku": "CT-CHINO-BGE"}],
        "body_html": "Classic tapered chinos in sand beige.",
    },
    {
        "title": "Black Wool Trousers",
        "product_type": "Trousers",
        "vendor": "CORET Test",
        "tags": "men, bottoms, all-season, black",
        "variants": [{"price": "1099.00", "sku": "CT-TROUSER-BLK"}],
        "body_html": "Tailored black wool trousers.",
    },
    {
        "title": "Charcoal Flannel Pants",
        "product_type": "Trousers",
        "vendor": "CORET Test",
        "tags": "men, bottoms, autumn, winter, charcoal",
        "variants": [{"price": "999.00", "sku": "CT-TROUSER-CHR"}],
        "body_html": "Relaxed flannel trousers in charcoal.",
    },
    {
        "title": "Navy Cotton Shorts",
        "product_type": "Shorts",
        "vendor": "CORET Test",
        "tags": "men, bottoms, summer, navy",
        "variants": [{"price": "499.00", "sku": "CT-SHORT-NVY"}],
        "body_html": "Tailored cotton shorts for summer.",
    },

    # Shoes (4)
    {
        "title": "Black Leather Loafers",
        "product_type": "Loafers",
        "vendor": "CORET Test",
        "tags": "men, shoes, all-season, black",
        "variants": [{"price": "1899.00", "sku": "CT-LOAFER-BLK"}],
        "body_html": "Classic penny loafers in black leather.",
    },
    {
        "title": "White Minimalist Sneakers",
        "product_type": "Sneakers",
        "vendor": "CORET Test",
        "tags": "men, shoes, all-season, white, unisex",
        "variants": [{"price": "1299.00", "sku": "CT-SNKR-WHT"}],
        "body_html": "Clean white leather sneakers.",
    },
    {
        "title": "Brown Chelsea Boots",
        "product_type": "Boots",
        "vendor": "CORET Test",
        "tags": "men, shoes, autumn, winter, brown",
        "variants": [{"price": "2299.00", "sku": "CT-BOOT-BRN"}],
        "body_html": "Suede Chelsea boots in warm brown.",
    },
    {
        "title": "Black Derby Shoes",
        "product_type": "Loafers",
        "vendor": "CORET Test",
        "tags": "men, shoes, all-season, black",
        "variants": [{"price": "1699.00", "sku": "CT-DERBY-BLK"}],
        "body_html": "Polished black derby shoes.",
    },
]


async def create_product(client: httpx.AsyncClient, product: dict, index: int, token: str) -> bool:
    """Create a single product in Shopify."""
    url = f"https://{STORE_DOMAIN}/admin/api/{API_VERSION}/products.json"
    headers = {"X-Shopify-Access-Token": token}

    payload = {"product": {**product, "status": "active"}}

    try:
        response = await client.post(url, json=payload, headers=headers, timeout=15.0)

        if response.status_code == 201:
            data = response.json()
            pid = data["product"]["id"]
            print(f"  [{index+1:2d}/18] {product['title']} (ID: {pid})")
            return True
        elif response.status_code == 429:
            # Rate limited — wait and retry
            retry_after = float(response.headers.get("Retry-After", "2"))
            print(f"  [{index+1:2d}/18] Rate limited, waiting {retry_after}s...")
            await asyncio.sleep(retry_after)
            return await create_product(client, product, index, token)
        else:
            print(f"  [{index+1:2d}/18] FAILED: {response.status_code} — {response.text[:200]}")
            return False
    except httpx.RequestError as e:
        print(f"  [{index+1:2d}/18] ERROR: {type(e).__name__}")
        return False


async def main():
    print(f"CORET Test Store Seeder")
    print(f"Store: {STORE_DOMAIN}")
    print(f"Products: {len(PRODUCTS)}")
    print(f"{'='*50}")
    print()

    token = await get_access_token()

    success = 0
    failed = 0

    async with httpx.AsyncClient() as client:
        for i, product in enumerate(PRODUCTS):
            ok = await create_product(client, product, i, token)
            if ok:
                success += 1
            else:
                failed += 1
            # Small delay to respect rate limits
            await asyncio.sleep(0.5)

    print()
    print(f"{'='*50}")
    print(f"Done: {success} created, {failed} failed")
    print()
    if success > 0:
        print("Next steps:")
        print(f"  1. Register brand:  POST /api/brands/register")
        print(f"     {'{'}\"name\": \"CORET Test\", \"shopify_domain\": \"{STORE_DOMAIN}\", \"access_token\": \"...\"{'}'}")
        print(f"  2. Sync products:   POST /api/brands/{{brand_id}}/sync")
        print(f"  3. View feed:       GET /api/discover/feed?mode=full&brand_id={{brand_id}}")


if __name__ == "__main__":
    asyncio.run(main())
