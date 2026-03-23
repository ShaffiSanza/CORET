"""
CORET Backend — Image Normalize Service

Resizes and centers garment images to a standard format:
- 1024x1024px canvas (storage)
- 512x512px variant (app display)
- 256x256px variant (preview/thumbnail)
- Transparent background
- Garment centered with 10% padding

Input: PNG bytes (ideally after background removal)
Output: Normalized PNG bytes + size variants
"""

from io import BytesIO
from PIL import Image

Image.MAX_IMAGE_PIXELS = 25_000_000  # ~5000x5000 max


TARGET_SIZE = 1024
UI_SIZES = [512, 256]  # App display + preview/thumbnail
PADDING_RATIO = 0.10  # 10% padding on each side


def _resize_canvas(canvas: Image.Image, size: int) -> bytes:
    """Resize a normalized canvas to a smaller size, return PNG bytes."""
    resized = canvas.resize((size, size), Image.LANCZOS)
    out = BytesIO()
    resized.save(out, format="PNG", optimize=True)
    return out.getvalue()


def normalize_image(image_bytes: bytes) -> dict:
    """
    Resize and center a garment image on a transparent canvas.

    Parameter:
        image_bytes: PNG image bytes (transparent background expected)

    Returns:
        {
            "image_bytes": b"...",       # 1024px normalized PNG
            "variants": {512: b"...", 256: b"..."},  # UI sizes
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
    usable = int(TARGET_SIZE * (1 - 2 * PADDING_RATIO))  # 819px

    # Scale garment to fit within usable area, preserving aspect ratio
    w, h = img.size
    scale = min(usable / w, usable / h)
    new_w = int(w * scale)
    new_h = int(h * scale)
    img = img.resize((new_w, new_h), Image.LANCZOS)

    # Center on transparent canvas
    canvas = Image.new("RGBA", (TARGET_SIZE, TARGET_SIZE), (0, 0, 0, 0))
    offset_x = (TARGET_SIZE - new_w) // 2
    offset_y = (TARGET_SIZE - new_h) // 2
    canvas.paste(img, (offset_x, offset_y), img)

    # Export full-size
    out = BytesIO()
    canvas.save(out, format="PNG", optimize=True)
    full_bytes = out.getvalue()

    # Generate UI variants (512px app, 256px preview)
    variants = {size: _resize_canvas(canvas, size) for size in UI_SIZES}

    return {
        "image_bytes": full_bytes,
        "variants": variants,
        "success": True,
        "original_size": original_size,
        "error": None,
    }
