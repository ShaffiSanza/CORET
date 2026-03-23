"""
CORET Backend — Shopify OAuth Router

GET  /auth/shopify            — Start OAuth flow (redirect to Shopify)
GET  /auth/shopify/callback   — Handle OAuth callback (exchange code for token)
"""

from fastapi import APIRouter, Query, HTTPException
from fastapi.responses import RedirectResponse

from services.shopify_oauth import (
    validate_shop,
    check_shop_rate,
    create_state,
    build_authorize_url,
    validate_state,
    exchange_code_for_token,
    verify_scopes,
    verify_shop_binding,
    generate_preview_token,
    OAuthError,
)
from services.ghost_catalog import register_brand, get_brand, _store_token, _load_brands
from services.security_logger import logger

router = APIRouter(tags=["auth"])

# Standard OAuth error — never expose internals
OAUTH_ERROR = {"error": "oauth_failed", "message": "Kunne ikke koble til Shopify — prøv igjen"}
RATE_LIMIT_ERROR = {"error": "rate_limited", "message": "For mange forsøk — prøv igjen senere"}


@router.get("/auth/shopify")
async def start_oauth(shop: str = Query(..., description="Shopify store domain")):
    """Start Shopify OAuth flow. Redirects to Shopify authorize page."""
    # Validate shop domain
    cleaned = validate_shop(shop)
    if not cleaned:
        raise HTTPException(status_code=422, detail="Ugyldig Shopify-domene")

    # Rate limit per shop
    if not check_shop_rate(cleaned):
        raise HTTPException(status_code=429, detail=RATE_LIMIT_ERROR["message"])

    # Generate state + redirect
    state = create_state(cleaned)
    try:
        url = build_authorize_url(cleaned, state)
    except ValueError:
        raise HTTPException(status_code=500, detail=OAUTH_ERROR["message"])

    return RedirectResponse(url=url)


@router.get("/auth/shopify/callback")
async def oauth_callback(
    code: str = Query(...),
    shop: str = Query(...),
    state: str = Query(...),
):
    """Handle Shopify OAuth callback. Exchanges code for token and registers brand."""
    # Validate shop
    cleaned = validate_shop(shop)
    if not cleaned:
        raise HTTPException(status_code=422, detail="Ugyldig Shopify-domene")

    # Validate state (one-time use, CSRF protection)
    state_data = validate_state(state, cleaned)
    if not state_data:
        # Could be expired (server restart) or invalid
        raise HTTPException(
            status_code=400,
            detail="Tilkoblingen ble avbrutt — vennligst prøv igjen"
        )

    # Idempotency: check if brand already exists for this shop
    existing_brands = _load_brands()
    for b in existing_brands:
        if b.get("shopify_domain") == cleaned:
            return {
                "brand_id": b["id"],
                "status": "already_connected",
                "preview_token": generate_preview_token(b["id"]),
            }

    # Exchange code for token
    try:
        token = await exchange_code_for_token(cleaned, code)
    except OAuthError:
        raise HTTPException(status_code=400, detail=OAUTH_ERROR["message"])

    # Scope verification
    scopes_ok = await verify_scopes(cleaned, token)
    if not scopes_ok:
        logger.warning("Scope verification failed for shop %s", cleaned)
        raise HTTPException(status_code=403, detail="Manglende tilganger — sjekk app-innstillinger i Shopify")

    # Token binding — verify token belongs to correct shop
    binding_ok = await verify_shop_binding(cleaned, token)
    if not binding_ok:
        logger.warning("Token binding failed for shop %s", cleaned)
        raise HTTPException(status_code=400, detail=OAUTH_ERROR["message"])

    # Register brand + store token
    brand_name = cleaned.replace(".myshopify.com", "").replace("-", " ").title()
    brand = register_brand(
        name=brand_name,
        shopify_domain=cleaned,
        access_token=token,  # register_brand calls _store_token internally
    )

    brand_id = brand["id"]
    preview_token = generate_preview_token(brand_id)

    # Trigger async sync (fire and forget — preview shows "syncing")
    # In production: use background task. Here: sync is triggered on first preview call.

    return {
        "brand_id": brand_id,
        "status": "syncing",
        "preview_token": preview_token,
        "next": f"/api/brands/{brand_id}/preview",
    }
