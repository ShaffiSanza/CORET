"""
CORET Backend — Brand Partner Router

Endpoints for managing brand partners and their Shopify product catalogs.

POST   /api/brands/register         — Register a new brand
GET    /api/brands                   — List all brands
GET    /api/brands/{id}              — Get brand details
DELETE /api/brands/{id}              — Remove brand
POST   /api/brands/{id}/sync        — Sync products from Shopify
GET    /api/brands/{id}/products     — Get cached products
POST   /api/brands/webhook           — Shopify product webhook
"""

import hashlib
import hmac

from fastapi import APIRouter, HTTPException, Query, Request

from config import settings
from models.shopify import (
    BrandRegister,
    BrandResponse,
    BrandListResponse,
    ShopifyProductList,
)
from services.ghost_catalog import (
    register_brand,
    get_brand,
    list_brands,
    delete_brand,
    sync_brand_products,
    get_brand_products,
)

router = APIRouter(tags=["brands"])


@router.post("/brands/register", response_model=BrandResponse, status_code=201)
async def post_register_brand(req: BrandRegister):
    """Register a new brand partner with Shopify credentials."""
    brand = register_brand(
        name=req.name,
        shopify_domain=req.shopify_domain,
        access_token=req.access_token,
        archetype=req.archetype,
        cover_image_url=req.cover_image_url,
    )
    return _brand_response(brand)


@router.get("/brands", response_model=BrandListResponse)
async def get_brands():
    """List all registered brands."""
    brands = list_brands()
    return {"brands": brands, "count": len(brands)}


@router.get("/brands/{brand_id}", response_model=BrandResponse)
async def get_brand_detail(brand_id: str):
    """Get a brand by ID."""
    brand = get_brand(brand_id)
    if not brand:
        raise HTTPException(status_code=404, detail="Brand ikke funnet")
    return _brand_response(brand)


@router.delete("/brands/{brand_id}")
async def delete_brand_endpoint(brand_id: str):
    """Remove a brand and its cached products."""
    removed = delete_brand(brand_id)
    if not removed:
        raise HTTPException(status_code=404, detail="Brand ikke funnet")
    return {"status": "removed", "brand_id": brand_id}


@router.post("/brands/{brand_id}/sync")
async def post_sync_brand(brand_id: str):
    """Sync products from brand's Shopify store.
    Fetches up to 500 products and caches them locally."""
    result = await sync_brand_products(brand_id)
    if not result.get("success"):
        error = result.get("error", "sync_failed")
        if error == "auth_failed":
            raise HTTPException(status_code=401, detail="Tilkoblingen til Shopify er ikke gyldig lenger")
        if error == "config_error":
            raise HTTPException(status_code=500, detail="Manglende Shopify-konfigurasjon")
        raise HTTPException(status_code=404, detail=result.get("message", "Sync feilet"))
    return result


@router.get("/brands/{brand_id}/products", response_model=ShopifyProductList)
async def get_products(brand_id: str):
    """Get cached products for a brand."""
    brand = get_brand(brand_id)
    if not brand:
        raise HTTPException(status_code=404, detail="Brand ikke funnet")
    products = get_brand_products(brand_id)
    return {
        "products": products,
        "count": len(products),
        "brand_id": brand_id,
        "brand_name": brand["name"],
    }


@router.get("/brands/{brand_id}/preview")
async def get_brand_preview(brand_id: str, preview_token: str = Query(...)):
    """Preview first 5 ghost outfits after OAuth connect.
    Requires a valid preview_token (scoped to brand_id, 24h TTL)."""
    from services.shopify_oauth import validate_preview_token

    if not validate_preview_token(preview_token, brand_id):
        raise HTTPException(status_code=403, detail="Ugyldig eller utlopt preview-token")

    brand = get_brand(brand_id)
    if not brand:
        raise HTTPException(status_code=404, detail="Brand ikke funnet")

    # Check auth status
    if brand.get("status") == "auth_failed":
        return {"status": "auth_failed", "brand_id": brand_id,
                "message": "Tilkoblingen til Shopify er ikke gyldig lenger", "outfits": []}

    products = get_brand_products(brand_id)
    if not products:
        synced = brand.get("synced_at")
        if not synced:
            return {"status": "syncing", "brand_id": brand_id, "outfits": []}
        return {"status": "sync_failed", "brand_id": brand_id,
                "message": "Synkronisering feilet — prov igjen", "outfits": []}

    # Return first 5 products as preview
    preview = products[:5]
    return {
        "status": "ready",
        "brand_id": brand_id,
        "brand_name": brand["name"],
        "product_count": len(products),
        "preview": preview,
    }


@router.post("/brands/webhook")
async def shopify_webhook(request: Request):
    """Handle Shopify product webhooks (products/create, products/update).
    Validates HMAC if webhook secret is configured.
    V1: acknowledge only — actual processing happens on next sync."""
    from services.security_logger import log_failed_webhook_hmac, log_missing_webhook_topic

    client_ip = request.client.host if request.client else "unknown"

    # Check X-Shopify-Topic header exists
    topic = request.headers.get("X-Shopify-Topic")
    if not topic:
        log_missing_webhook_topic(client_ip)
        # Still accept in V1 for testing, but log it

    # HMAC validation if secret is configured
    if settings.shopify_webhook_secret:
        raw_body = await request.body()
        hmac_header = request.headers.get("X-Shopify-Hmac-SHA256", "")
        computed = hmac.new(
            settings.shopify_webhook_secret.encode("utf-8"),
            raw_body,
            hashlib.sha256
        ).hexdigest()

        if not hmac.compare_digest(computed, hmac_header):
            log_failed_webhook_hmac(client_ip)
            raise HTTPException(status_code=401, detail="Invalid webhook signature")

    return {"status": "received", "topic": topic}


def _brand_response(brand: dict) -> dict:
    """Strip access_token from brand dict for response."""
    return {k: v for k, v in brand.items() if k != "access_token"}
