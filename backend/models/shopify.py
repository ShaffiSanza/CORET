"""
CORET Backend — Shopify Models

Pydantic models for Shopify product data and brand registration.
Maps Shopify products to CORET's DiscoverGarment ghost format.
"""

from pydantic import BaseModel, Field, field_validator


class ShopifyProduct(BaseModel):
    """A product from Shopify Admin API, mapped to CORET fields."""
    shopify_id: int
    title: str
    vendor: str  # brand name
    product_type: str  # e.g. "T-Shirt", "Jeans"
    image_url: str | None = None
    price: float | None = None  # lowest variant price
    shop_url: str | None = None  # online store URL
    available: bool = True
    tags: list[str] = []
    # CORET mappings (derived)
    category: str | None = None  # upper, lower, shoes
    base_group: str | None = None  # tee, jeans, sneakers, etc.
    color_temperature: str | None = None
    style_context: str = "unisex"  # menswear, womenswear, unisex, fluid


class BrandRegister(BaseModel):
    """Request to register a brand partner."""
    name: str = Field(..., min_length=1, max_length=100)
    shopify_domain: str = Field(..., min_length=1, max_length=253)
    access_token: str = Field(..., min_length=1, max_length=200)
    archetype: str = Field("smartCasual", max_length=50)
    cover_image_url: str | None = Field(None, max_length=2048)

    @field_validator("name", "shopify_domain", "archetype")
    @classmethod
    def strip_strings(cls, v: str) -> str:
        return v.strip()


class BrandResponse(BaseModel):
    """A registered brand."""
    id: str
    name: str
    shopify_domain: str
    archetype: str
    product_count: int = 0
    synced_at: str | None = None
    cover_image_url: str | None = None


class BrandListResponse(BaseModel):
    """All registered brands."""
    brands: list[BrandResponse]
    count: int


class ShopifyProductList(BaseModel):
    """Products from a brand's Shopify store."""
    products: list[ShopifyProduct]
    count: int
    brand_id: str
    brand_name: str
