"""
CORET Backend — Discover Feed Models

Response models for the Discover outfit feed.
Maps to Discover tab in iOS app (swipe feed with 70/30 and Full modes).
"""

from pydantic import BaseModel


class DiscoverGarment(BaseModel):
    """A garment within a Discover card."""
    id: str
    name: str
    category: str  # upper, lower, shoes, accessory
    base_group: str
    color_temperature: str | None = None
    dominant_color: str | None = None
    image_url: str | None = None
    is_ghost: bool = False  # True = user doesn't own this
    # Ghost-specific fields (populated when Shopify is connected)
    price: float | None = None
    shop_url: str | None = None
    available: bool = True


class MissingPiece(BaseModel):
    """The single ghost garment that completes the outfit.
    Core pitch: 'Your product is the last piece that completes the outfit.'"""
    name: str
    brand: str
    price: float | None = None
    shop_url: str | None = None
    image_url: str | None = None
    base_group: str  # "shoes", "upper", "outer", "lower"
    gap_type: str  # "missing_layer" | "balance" | "upgrade"


class DiscoverCard(BaseModel):
    """A single outfit card in the Discover feed."""
    card_id: str  # unique per card
    garments: list[DiscoverGarment]
    outfit_name: str  # e.g. "Jakke + Tee + Jeans + Boots"
    brands: list[str]  # unique brands in this outfit
    strength: float  # 0-1 outfit score
    color_harmony: float
    archetype_coherence: float
    feed_type: str  # "owned", "rotation", "ghost"
    owned_count: int = 0  # how many garments user owns
    ghost_count: int = 0  # how many garments user doesn't own
    gap_type: str | None = None  # if ghost: what gap does it fill
    filter_tags: list[str] = []  # e.g. ["street", "winter", "under-1500"]
    reason: str = ""  # e.g. "Sterk fargeharmoni" — why this outfit scores well
    missing_piece: MissingPiece | None = None  # the ONE ghost garment completing the outfit


class DiscoverFeedResponse(BaseModel):
    """Full Discover feed response."""
    cards: list[DiscoverCard]
    total_cards: int
    mode: str  # "7030" or "full"
    clarity_estimate: int  # 0-100
    gaps_detected: int
    needs_onboarding: bool = False  # True if user profile not yet set


class DiscoverBookmark(BaseModel):
    """A bookmarked/liked outfit from Discover."""
    card_id: str
    garment_ids: list[str]
    strength: float
    bookmarked_at: str  # ISO 8601


class DiscoverBookmarkList(BaseModel):
    """All bookmarked outfits."""
    bookmarks: list[DiscoverBookmark]
    count: int


class BrandCard(BaseModel):
    """A brand in the Full Discover brand grid."""
    id: str
    name: str
    archetype: str
    product_count: int
    cover_image: str | None = None  # cover_image_url or first product image
    style_tags: list[str] = []  # top tags from products


class BrandGridResponse(BaseModel):
    """Brand grid for Full Discover landing."""
    brands: list[BrandCard]
    count: int
