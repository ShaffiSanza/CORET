"""
CORET Backend — Image Normalize Service v2

Category-aware garment normalization for Studio display:
- Transparent PNG output (no baked background or shadow)
- Category-specific canvas sizes and fill ratios
- Alpha fringe cleanup (erode + dilate)
- Vertical anchor points (neckline / waistband / sole)
- 3 size variants: full canvas, 512px, 256px

Input: PNG bytes (transparent background expected) + category string
Output: Transparent PNG bytes + metadata (anchor, bbox, fill ratio)
"""

from io import BytesIO
from PIL import Image, ImageFilter

Image.MAX_IMAGE_PIXELS = 25_000_000

# Category-specific canvas sizes (width × height).
# Matches the CORET Studio Implementation Checklist spec.
CATEGORY_CANVAS = {
    "upper":     (1200, 1400),
    "lower":     (1000, 1400),
    "shoes":     (900,  700),
    "outerwear": (1300, 1500),
    "accessory": (800,  800),
}

# Target fill ranges (garment fills this % of canvas height).
# We target the midpoint of the spec range.
# upper: 78–84% → 0.81, lower: 82–88% → 0.85, shoes: 72–78% → 0.75
CATEGORY_FILL = {
    "upper":     0.81,
    "lower":     0.85,
    "shoes":     0.75,
    "outerwear": 0.83,
    "accessory": 0.70,
}

# Vertical anchor position (0 = top, 1 = bottom).
# tops: neckline center, pants: waistband center, shoes: sole center.
CATEGORY_ANCHOR = {
    "upper":     0.15,
    "lower":     0.10,
    "shoes":     0.85,
    "outerwear": 0.12,
    "accessory": 0.50,
}

UI_SIZES = [512, 256]


def _compute_visual_weight(canvas: Image.Image) -> float:
    """Ratio of opaque pixels to total canvas area (0-1).

    Higher = garment takes up more visual space. Used by Studio
    to balance layout when composing outfits.
    """
    if canvas.mode != "RGBA":
        return 1.0
    alpha = canvas.getchannel("A")
    total = alpha.size[0] * alpha.size[1]
    if total == 0:
        return 0.0
    opaque = sum(1 for p in alpha.tobytes() if p > 128)
    return opaque / total


def _clean_alpha(img: Image.Image) -> Image.Image:
    """Remove white fringing halos from alpha edges.

    Erodes alpha by 1px (removes thin bright fringe), then dilates back
    to restore the original garment boundary.
    """
    if img.mode != "RGBA":
        return img
    alpha = img.getchannel("A")
    alpha = alpha.filter(ImageFilter.MinFilter(3))
    alpha = alpha.filter(ImageFilter.MaxFilter(3))
    img.putalpha(alpha)
    return img


def _resize_variant(img: Image.Image, max_dim: int) -> bytes:
    """Scale image so its largest dimension equals max_dim, return PNG bytes."""
    w, h = img.size
    scale = max_dim / max(w, h)
    new_w = max(1, int(w * scale))
    new_h = max(1, int(h * scale))
    resized = img.resize((new_w, new_h), Image.LANCZOS)
    out = BytesIO()
    resized.save(out, format="PNG", optimize=True)
    return out.getvalue()


def normalize_image(image_bytes: bytes, category: str = "upper") -> dict:
    """
    Normalize a garment image for Studio display.

    Parameters:
        image_bytes: PNG bytes with transparent background
        category: one of upper, lower, shoes, outerwear, accessory

    Returns:
        {
            "image_bytes": b"...",          # full-size transparent PNG
            "variants": {512: b"...", 256: b"..."},
            "metadata": {
                "canvas_width": int,
                "canvas_height": int,
                "garment_bbox": [x, y, w, h],
                "anchor_y": float,          # 0-1 normalized
                "fill_ratio": float,        # actual fill achieved
            },
            "success": True,
            "original_size": (w, h),
            "error": None,
        }
    """
    try:
        img = Image.open(BytesIO(image_bytes)).convert("RGBA")
    except Exception as e:
        return {
            "image_bytes": None,
            "variants": {},
            "metadata": None,
            "success": False,
            "original_size": (0, 0),
            "error": f"Could not open image: {e}",
        }

    original_size = img.size

    # 1. Crop to content bounding box
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)

    # 2. Alpha fringe cleanup
    img = _clean_alpha(img)

    # 3. Determine canvas + fill for category
    cat_key = category if category in CATEGORY_CANVAS else "upper"
    canvas_w, canvas_h = CATEGORY_CANVAS[cat_key]
    fill_target = CATEGORY_FILL[cat_key]
    anchor_y = CATEGORY_ANCHOR[cat_key]

    # 4. Scale garment to fill target height, preserving aspect ratio
    target_h = int(canvas_h * fill_target)
    target_w = int(canvas_w * 0.85)  # garment should not exceed 85% width
    w, h = img.size
    scale = min(target_w / w, target_h / h)
    new_w = max(1, int(w * scale))
    new_h = max(1, int(h * scale))
    img = img.resize((new_w, new_h), Image.LANCZOS)

    # 5. Place on transparent canvas with anchor-based vertical positioning
    canvas = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))

    # Horizontal: always centered
    offset_x = (canvas_w - new_w) // 2

    # Vertical: position based on anchor type
    # anchor_y < 0.5 → garment top aligned near top of canvas (tops/outerwear)
    # anchor_y > 0.5 → garment bottom aligned near bottom of canvas (shoes)
    if anchor_y <= 0.5:
        # Top-anchored: place garment so top is at anchor_y * canvas_h
        top_margin = int(canvas_h * anchor_y)
        offset_y = top_margin
    else:
        # Bottom-anchored: place garment so bottom is at anchor_y * canvas_h
        bottom_target = int(canvas_h * anchor_y)
        offset_y = bottom_target - new_h

    # Clamp to canvas bounds
    offset_y = max(0, min(offset_y, canvas_h - new_h))

    canvas.paste(img, (offset_x, offset_y), img)

    # 6. Calculate actual fill ratio and visual weight
    actual_fill = new_h / canvas_h
    # Visual weight: how much of the canvas is opaque (0-1)
    visual_weight = _compute_visual_weight(canvas)

    # 7. Export full-size transparent PNG
    out = BytesIO()
    canvas.save(out, format="PNG", optimize=True)
    full_bytes = out.getvalue()

    # 8. Generate UI variants (proportional, not square)
    variants = {size: _resize_variant(canvas, size) for size in UI_SIZES}

    return {
        "image_bytes": full_bytes,
        "variants": variants,
        "metadata": {
            "canvas_width": canvas_w,
            "canvas_height": canvas_h,
            "garment_bbox": [offset_x, offset_y, new_w, new_h],
            "anchor_x": 0.5,  # always horizontally centered
            "anchor_y": round(anchor_y, 2),
            "fill_ratio": round(actual_fill, 3),
            "visual_weight": round(visual_weight, 3),
        },
        "success": True,
        "original_size": original_size,
        "error": None,
    }
