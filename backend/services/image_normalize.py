"""
CORET Backend — Image Normalize Service (Prettifier)

Resizes, centers, and prettifies garment images:
- Studio-quality white/off-white background
- Soft drop shadow under product
- Garment centered with padding
- 3 size variants: 1024px (storage), 512px (app), 256px (preview)

Input: PNG bytes (ideally after background removal)
Output: Prettified PNG bytes + size variants
"""

from io import BytesIO
from PIL import Image, ImageFilter

Image.MAX_IMAGE_PIXELS = 25_000_000

TARGET_SIZE = 1024
UI_SIZES = [512, 256]
PADDING_RATIO = 0.12  # 12% padding on each side

# Studio background color (warm off-white, matches CORET aesthetic)
STUDIO_BG = (248, 246, 242, 255)  # #F8F6F2


def _resize_canvas(canvas: Image.Image, size: int) -> bytes:
    """Resize a normalized canvas to a smaller size, return PNG bytes."""
    resized = canvas.resize((size, size), Image.LANCZOS)
    out = BytesIO()
    resized.save(out, format="PNG", optimize=True)
    return out.getvalue()


def _create_shadow(garment: Image.Image, canvas_size: int, offset_x: int, offset_y: int) -> Image.Image:
    """Create a soft drop shadow for the garment."""
    shadow_layer = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))

    # Use garment alpha as shadow shape, shift down slightly
    if garment.mode == "RGBA":
        alpha = garment.getchannel("A")
        # Create dark shadow from alpha
        shadow = Image.new("RGBA", garment.size, (0, 0, 0, 30))  # Very subtle
        shadow.putalpha(alpha)
        # Paste shadow shifted down by 8px
        shadow_offset_y = offset_y + 8
        shadow_layer.paste(shadow, (offset_x, shadow_offset_y), shadow)
        # Blur the shadow
        shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(radius=12))

    return shadow_layer


def normalize_image(image_bytes: bytes) -> dict:
    """
    Prettify a garment image: center on studio background with soft shadow.

    Parameter:
        image_bytes: PNG image bytes (transparent background expected)

    Returns:
        {
            "image_bytes": b"...",
            "variants": {512: b"...", 256: b"..."},
            "success": True,
            "original_size": (w, h),
            "error": None
        }
    """
    try:
        img = Image.open(BytesIO(image_bytes)).convert("RGBA")
    except Exception as e:
        return {
            "image_bytes": None,
            "variants": {},
            "success": False,
            "original_size": (0, 0),
            "error": f"Could not open image: {e}",
        }

    original_size = img.size

    # Crop to content bounding box (remove excess transparency)
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)

    # Calculate target area (canvas minus padding)
    usable = int(TARGET_SIZE * (1 - 2 * PADDING_RATIO))

    # Scale garment to fit within usable area, preserving aspect ratio
    w, h = img.size
    scale = min(usable / w, usable / h)
    new_w = int(w * scale)
    new_h = int(h * scale)
    img = img.resize((new_w, new_h), Image.LANCZOS)

    # Center position
    offset_x = (TARGET_SIZE - new_w) // 2
    offset_y = (TARGET_SIZE - new_h) // 2

    # Create studio background
    canvas = Image.new("RGBA", (TARGET_SIZE, TARGET_SIZE), STUDIO_BG)

    # Add soft drop shadow
    shadow = _create_shadow(img, TARGET_SIZE, offset_x, offset_y)
    canvas = Image.alpha_composite(canvas, shadow)

    # Paste garment on top
    canvas.paste(img, (offset_x, offset_y), img)

    # Export full-size
    out = BytesIO()
    canvas.save(out, format="PNG", optimize=True)
    full_bytes = out.getvalue()

    # Generate UI variants
    variants = {size: _resize_canvas(canvas, size) for size in UI_SIZES}

    return {
        "image_bytes": full_bytes,
        "variants": variants,
        "success": True,
        "original_size": original_size,
        "error": None,
    }
