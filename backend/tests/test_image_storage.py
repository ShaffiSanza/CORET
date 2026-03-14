"""
Tests for image storage service.
"""

import pytest
from io import BytesIO
from PIL import Image

from services.image_normalize import normalize_image
import services.image_storage as storage


def _make_test_image(w=400, h=600) -> bytes:
    img = Image.new("RGBA", (w, h), (200, 100, 50, 255))
    buf = BytesIO()
    img.save(buf, format="PNG")
    return buf.getvalue()


@pytest.fixture(autouse=True)
def use_tmp_storage(tmp_path):
    """Use temp directory for image storage."""
    storage.IMAGES_DIR = tmp_path / "images"
    yield


def test_save_and_retrieve():
    """Save images and verify all 3 variants exist on disk."""
    norm = normalize_image(_make_test_image())
    assert norm["success"]

    result = storage.save_garment_images("test-123", norm)
    assert result["success"]
    assert result["full"] == "/api/images/test-123/full.png"
    assert result["display"] == "/api/images/test-123/display.png"
    assert result["preview"] == "/api/images/test-123/preview.png"

    # Verify files exist
    assert storage.get_image_path("test-123", "full") is not None
    assert storage.get_image_path("test-123", "display") is not None
    assert storage.get_image_path("test-123", "preview") is not None


def test_get_nonexistent():
    """Getting a nonexistent image returns None."""
    assert storage.get_image_path("no-such-id", "full") is None


def test_delete_images():
    """Delete removes all variants."""
    norm = normalize_image(_make_test_image())
    storage.save_garment_images("del-test", norm)

    assert storage.delete_garment_images("del-test") is True
    assert storage.get_image_path("del-test", "full") is None
    assert storage.get_image_path("del-test", "display") is None


def test_delete_nonexistent():
    assert storage.delete_garment_images("nope") is False


def test_saved_image_sizes():
    """Verify saved files have correct dimensions."""
    norm = normalize_image(_make_test_image())
    storage.save_garment_images("size-test", norm)

    full_path = storage.get_image_path("size-test", "full")
    img = Image.open(full_path)
    assert img.size == (1024, 1024)

    display_path = storage.get_image_path("size-test", "display")
    img = Image.open(display_path)
    assert img.size == (512, 512)

    preview_path = storage.get_image_path("size-test", "preview")
    img = Image.open(preview_path)
    assert img.size == (256, 256)
