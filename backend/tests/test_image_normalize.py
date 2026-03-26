"""
Tests for image normalize service v2 (category-aware, transparent output).
"""

from io import BytesIO
from PIL import Image
from services.image_normalize import (
    normalize_image, CATEGORY_CANVAS, CATEGORY_FILL, CATEGORY_ANCHOR,
)


def _make_test_image(w: int, h: int, color=(255, 0, 0, 255)) -> bytes:
    """Create a simple RGBA test image as PNG bytes."""
    img = Image.new("RGBA", (w, h), color)
    buf = BytesIO()
    img.save(buf, format="PNG")
    return buf.getvalue()


def _make_transparent_with_content(canvas_w, canvas_h, content_w, content_h):
    """Create a transparent image with a colored rectangle in the center."""
    img = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    x = (canvas_w - content_w) // 2
    y = (canvas_h - content_h) // 2
    for px in range(x, x + content_w):
        for py in range(y, y + content_h):
            img.putpixel((px, py), (200, 100, 50, 255))
    buf = BytesIO()
    img.save(buf, format="PNG")
    return buf.getvalue()


def test_normalize_upper():
    """Upper garment should produce 1000x1200 transparent canvas."""
    result = normalize_image(_make_test_image(500, 700), category="upper")
    assert result["success"] is True
    img = Image.open(BytesIO(result["image_bytes"]))
    assert img.size == CATEGORY_CANVAS["upper"]
    assert img.mode == "RGBA"


def test_normalize_lower():
    """Lower garment should produce 900x1300 canvas."""
    result = normalize_image(_make_test_image(400, 800), category="lower")
    assert result["success"] is True
    img = Image.open(BytesIO(result["image_bytes"]))
    assert img.size == CATEGORY_CANVAS["lower"]


def test_normalize_shoes():
    """Shoes should produce 1000x700 landscape canvas."""
    result = normalize_image(_make_test_image(600, 300), category="shoes")
    assert result["success"] is True
    img = Image.open(BytesIO(result["image_bytes"]))
    assert img.size == CATEGORY_CANVAS["shoes"]


def test_normalize_outerwear():
    """Outerwear should produce 1100x1400 canvas."""
    result = normalize_image(_make_test_image(500, 900), category="outerwear")
    assert result["success"] is True
    img = Image.open(BytesIO(result["image_bytes"]))
    assert img.size == CATEGORY_CANVAS["outerwear"]


def test_normalize_accessory():
    """Accessory should produce 800x800 square canvas."""
    result = normalize_image(_make_test_image(300, 300), category="accessory")
    assert result["success"] is True
    img = Image.open(BytesIO(result["image_bytes"]))
    assert img.size == CATEGORY_CANVAS["accessory"]


def test_normalize_transparent_background():
    """Corners should be fully transparent (no baked background)."""
    result = normalize_image(_make_test_image(400, 600), category="upper")
    assert result["success"] is True
    img = Image.open(BytesIO(result["image_bytes"]))
    pixel = img.getpixel((0, 0))
    assert pixel[3] == 0  # Fully transparent corner


def test_normalize_crops_excess_transparency():
    """Image with large transparent border should be cropped first."""
    result = normalize_image(
        _make_transparent_with_content(2000, 2000, 200, 300),
        category="upper",
    )
    assert result["success"] is True
    img = Image.open(BytesIO(result["image_bytes"]))
    assert img.size == CATEGORY_CANVAS["upper"]


def test_normalize_returns_original_size():
    result = normalize_image(_make_test_image(640, 480))
    assert result["original_size"] == (640, 480)


def test_normalize_generates_variants():
    """Should produce 512px and 256px variants (proportional, not square)."""
    result = normalize_image(_make_test_image(800, 600), category="upper")
    assert result["success"] is True
    assert 512 in result["variants"]
    assert 256 in result["variants"]

    img_512 = Image.open(BytesIO(result["variants"][512]))
    # Largest dimension should be 512
    assert max(img_512.size) == 512

    img_256 = Image.open(BytesIO(result["variants"][256]))
    assert max(img_256.size) == 256


def test_normalize_returns_metadata():
    """Should include canvas size, bbox, anchors, fill ratio, and visual weight."""
    result = normalize_image(_make_test_image(500, 700), category="upper")
    assert result["success"] is True
    meta = result["metadata"]
    assert meta is not None
    assert meta["canvas_width"] == CATEGORY_CANVAS["upper"][0]
    assert meta["canvas_height"] == CATEGORY_CANVAS["upper"][1]
    assert meta["anchor_x"] == 0.5
    assert meta["anchor_y"] == CATEGORY_ANCHOR["upper"]
    assert 0 < meta["fill_ratio"] <= 1.0
    assert 0 < meta["visual_weight"] <= 1.0
    assert len(meta["garment_bbox"]) == 4


def test_normalize_default_category():
    """Unknown category should fall back to 'upper'."""
    result = normalize_image(_make_test_image(400, 400), category="unknown")
    assert result["success"] is True
    img = Image.open(BytesIO(result["image_bytes"]))
    assert img.size == CATEGORY_CANVAS["upper"]


def test_normalize_invalid_bytes():
    """Invalid image bytes should return error."""
    result = normalize_image(b"not an image")
    assert result["success"] is False
    assert result["error"] is not None
    assert result["variants"] == {}
    assert result["metadata"] is None
