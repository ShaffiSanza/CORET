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


VALID_UUID = "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
VALID_UUID_2 = "b2c3d4e5-f6a7-8901-bcde-f12345678901"
VALID_UUID_3 = "c3d4e5f6-a7b8-9012-cdef-123456789012"
VALID_UUID_4 = "d4e5f6a7-b8c9-0123-defa-234567890123"


def test_save_and_retrieve():
    """Save images and verify all 3 variants exist on disk."""
    norm = normalize_image(_make_test_image())
    assert norm["success"]

    result = storage.save_garment_images(VALID_UUID, norm)
    assert result["success"]
    assert result["full"] == f"/api/images/{VALID_UUID}/full.png"
    assert result["display"] == f"/api/images/{VALID_UUID}/display.png"
    assert result["preview"] == f"/api/images/{VALID_UUID}/preview.png"

    # Verify files exist
    assert storage.get_image_path(VALID_UUID, "full") is not None
    assert storage.get_image_path(VALID_UUID, "display") is not None
    assert storage.get_image_path(VALID_UUID, "preview") is not None


def test_get_nonexistent():
    """Getting a nonexistent image returns None."""
    assert storage.get_image_path(VALID_UUID_2, "full") is None


def test_delete_images():
    """Delete removes all variants."""
    norm = normalize_image(_make_test_image())
    storage.save_garment_images(VALID_UUID_3, norm)

    assert storage.delete_garment_images(VALID_UUID_3) is True
    assert storage.get_image_path(VALID_UUID_3, "full") is None
    assert storage.get_image_path(VALID_UUID_3, "display") is None


def test_delete_nonexistent():
    assert storage.delete_garment_images(VALID_UUID_4) is False


def test_saved_image_sizes():
    """Verify saved files have correct dimensions."""
    norm = normalize_image(_make_test_image())
    storage.save_garment_images(VALID_UUID, norm)

    full_path = storage.get_image_path(VALID_UUID, "full")
    img = Image.open(full_path)
    assert img.size == (1024, 1024)

    display_path = storage.get_image_path(VALID_UUID, "display")
    img = Image.open(display_path)
    assert img.size == (512, 512)

    preview_path = storage.get_image_path(VALID_UUID, "preview")
    img = Image.open(preview_path)
    assert img.size == (256, 256)


def test_invalid_garment_id_rejected():
    """Non-UUID garment IDs should be rejected."""
    with pytest.raises(ValueError, match="Invalid garment ID format"):
        storage.save_garment_images("../evil", {})
    with pytest.raises(ValueError, match="Invalid garment ID format"):
        storage.get_image_path("not-a-uuid", "full")
    with pytest.raises(ValueError, match="Invalid garment ID format"):
        storage.delete_garment_images("../../etc/passwd")
