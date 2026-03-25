"""
Tests for image normalize service.
"""

from io import BytesIO
from PIL import Image
from services.image_normalize import normalize_image, TARGET_SIZE


def _make_test_image(w: int, h: int, color=(255, 0, 0, 255)) -> bytes:
    """Create a simple RGBA test image as PNG bytes."""
    img = Image.new("RGBA", (w, h), color)
    buf = BytesIO()
    img.save(buf, format="PNG")
    return buf.getvalue()


def _make_transparent_with_content(canvas_w, canvas_h, content_w, content_h):
    """Create a transparent image with a colored rectangle in the center."""
    img = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    # Draw content in center
    x = (canvas_w - content_w) // 2
    y = (canvas_h - content_h) // 2
    for px in range(x, x + content_w):
        for py in range(y, y + content_h):
            img.putpixel((px, py), (200, 100, 50, 255))
    buf = BytesIO()
    img.save(buf, format="PNG")
    return buf.getvalue()


def test_normalize_square_image():
    """Square image should be centered on 1024x1024 canvas."""
    result = normalize_image(_make_test_image(500, 500))
    assert result["success"] is True
    img = Image.open(BytesIO(result["image_bytes"]))
    assert img.size == (TARGET_SIZE, TARGET_SIZE)
    assert img.mode == "RGBA"


def test_normalize_tall_image():
    """Tall image should fit height, centered horizontally."""
    result = normalize_image(_make_test_image(300, 800))
    assert result["success"] is True
    img = Image.open(BytesIO(result["image_bytes"]))
    assert img.size == (TARGET_SIZE, TARGET_SIZE)


def test_normalize_wide_image():
    """Wide image should fit width, centered vertically."""
    result = normalize_image(_make_test_image(1200, 400))
    assert result["success"] is True
    img = Image.open(BytesIO(result["image_bytes"]))
    assert img.size == (TARGET_SIZE, TARGET_SIZE)


def test_normalize_large_image():
    """Image larger than target should be scaled down."""
    result = normalize_image(_make_test_image(3000, 2000))
    assert result["success"] is True
    img = Image.open(BytesIO(result["image_bytes"]))
    assert img.size == (TARGET_SIZE, TARGET_SIZE)


def test_normalize_small_image():
    """Small image should be scaled up to fill usable area."""
    result = normalize_image(_make_test_image(100, 100))
    assert result["success"] is True
    img = Image.open(BytesIO(result["image_bytes"]))
    assert img.size == (TARGET_SIZE, TARGET_SIZE)


def test_normalize_has_studio_background():
    """Corners should have studio background color (off-white)."""
    result = normalize_image(_make_test_image(400, 600))
    assert result["success"] is True
    img = Image.open(BytesIO(result["image_bytes"]))
    pixel = img.getpixel((0, 0))
    assert pixel[3] == 255  # Opaque studio bg
    assert pixel[0] > 240   # Near-white


def test_normalize_crops_excess_transparency():
    """Image with large transparent border should be cropped first."""
    result = normalize_image(_make_transparent_with_content(2000, 2000, 200, 300))
    assert result["success"] is True
    img = Image.open(BytesIO(result["image_bytes"]))
    assert img.size == (TARGET_SIZE, TARGET_SIZE)


def test_normalize_returns_original_size():
    result = normalize_image(_make_test_image(640, 480))
    assert result["original_size"] == (640, 480)


def test_normalize_generates_variants():
    """Should produce 512px and 256px variants."""
    result = normalize_image(_make_test_image(800, 600))
    assert result["success"] is True
    assert 512 in result["variants"]
    assert 256 in result["variants"]

    img_512 = Image.open(BytesIO(result["variants"][512]))
    assert img_512.size == (512, 512)

    img_256 = Image.open(BytesIO(result["variants"][256]))
    assert img_256.size == (256, 256)


def test_normalize_invalid_bytes():
    """Invalid image bytes should return error."""
    result = normalize_image(b"not an image")
    assert result["success"] is False
    assert result["error"] is not None
    assert result["variants"] == {}
