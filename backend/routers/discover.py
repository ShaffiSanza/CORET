"""
CORET Backend — Discover Feed Router

Endpoints for the Discover outfit feed (swipe feed).

GET  /api/discover/feed          — Get feed (mode=7030|full, season+tag+brand filter)
GET  /api/discover/brands        — Brand grid for Full mode landing
POST /api/discover/bookmark      — Bookmark a card
DELETE /api/discover/bookmark/{card_id} — Remove bookmark
GET  /api/discover/bookmarks     — List all bookmarks
POST /api/discover/action        — Log swipe action (like/pass/hook)
GET  /api/discover/stats         — Get action stats
"""

from typing import Literal

from fastapi import APIRouter, Query, HTTPException
from pydantic import BaseModel, Field

from models.discover import (
    DiscoverFeedResponse,
    DiscoverBookmarkList,
    BrandGridResponse,
)
from services.discover_feed import (
    generate_feed,
    bookmark_card,
    remove_bookmark,
    list_bookmarks,
    log_action,
    get_action_stats,
)
from services.ghost_catalog import get_brand_grid
from services.user_profile import get_profile

router = APIRouter(tags=["discover"])


@router.get("/discover/brands", response_model=BrandGridResponse)
async def get_discover_brands():
    """Brand grid for Full Discover landing page.
    Returns all registered brands with cover images and style tags."""
    brands = get_brand_grid()
    return {"brands": brands, "count": len(brands)}


@router.get("/discover/feed", response_model=DiscoverFeedResponse)
async def get_discover_feed(
    mode: str = Query("7030", pattern="^(7030|full)$", description="Feed mode: 7030 or full"),
    season: str | None = Query(None, description="Filter by season"),
    tags: str | None = Query(None, description="Comma-separated tags to filter by (e.g. 'winter,cool')"),
    style_context: str | None = Query(None, description="Override style context (menswear/womenswear/unisex/fluid). Defaults to profile setting."),
    brand_id: str | None = Query(None, description="Full mode only: filter to specific brand's products"),
):
    """Generate Discover outfit feed.

    - **7030 mode**: 70% owned outfits, 20% rotation tips, 10% ghost.
      Rhythm: owned-owned-owned-rotation. Ghost at positions 4, 9, 14, 19.
    - **full mode**: 100% curated ghost looks from partner catalog.
      With brand_id: only that brand's products (brand room).
    - **tags**: Filter cards where any tag matches (e.g. ?tags=winter,cool).
    - **style_context**: Filter ghost products. Defaults to user profile setting.

    Max 20 cards per request.
    """
    tag_list = [t.strip() for t in tags.split(",") if t.strip()] if tags else None
    profile = get_profile()
    sc = style_context or profile.get("style_context", "unisex")
    result = generate_feed(mode=mode, season=season, tags=tag_list, style_context=sc, brand_id=brand_id)
    # Signal if user hasn't set up profile yet (still on defaults)
    from services.user_profile import PROFILE_FILE
    result["needs_onboarding"] = not PROFILE_FILE.exists()
    return result


class BookmarkRequest(BaseModel):
    card_id: str = Field(..., max_length=100)
    garment_ids: list[str]
    strength: float = Field(0.0, ge=0.0, le=1.0)


@router.post("/discover/bookmark")
async def post_bookmark(req: BookmarkRequest):
    """Bookmark a Discover card (swipe right or tap Hook)."""
    result = bookmark_card(req.card_id, req.garment_ids, req.strength)
    if result.get("already_bookmarked"):
        return {"status": "already_bookmarked", "card_id": req.card_id}
    return {"status": "bookmarked", **result}


@router.delete("/discover/bookmark/{card_id}")
async def delete_bookmark(card_id: str):
    """Remove a bookmark."""
    removed = remove_bookmark(card_id)
    if not removed:
        raise HTTPException(status_code=404, detail="Bokmerke ikke funnet")
    return {"status": "removed", "card_id": card_id}


@router.get("/discover/bookmarks", response_model=DiscoverBookmarkList)
async def get_bookmarks():
    """List all bookmarked Discover cards."""
    return list_bookmarks()


class ActionRequest(BaseModel):
    card_id: str = Field(..., max_length=100)
    action: Literal["like", "pass", "hook"]
    garment_ids: list[str] = []  # required for hook (auto-bookmark)
    strength: float = Field(0.0, ge=0.0, le=1.0)
    timestamp: str | None = None  # ISO 8601, defaults to now


@router.post("/discover/action")
async def post_action(req: ActionRequest):
    """Log a swipe action for data collection.
    Valid actions: like, pass, hook. Hook auto-creates bookmark."""
    result = log_action(req.card_id, req.action, req.timestamp, req.garment_ids, req.strength)
    if not result.get("success"):
        raise HTTPException(status_code=422, detail=result.get("error"))
    return result


@router.get("/discover/stats")
async def get_stats():
    """Get action stats (like/pass/hook counts)."""
    return get_action_stats()
