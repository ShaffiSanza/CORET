"""
CORET Backend — Image Storage Service

Saves processed garment images to disk in 3 sizes:
- 1024px (full/storage)
- 512px (app display)
- 256px (preview/thumbnail)

In production, this would write to cloud storage (S3/GCS).
For V1, writes to local data/images/ directory.
"""

from pathlib import Path

IMAGES_DIR = Path(__file__).parent.parent / "data" / "images"


def _ensure_dir() -> None:
    IMAGES_DIR.mkdir(parents=True, exist_ok=True)


def save_garment_images(garment_id: str, norm_result: dict) -> dict:
    """
    Save all image variants to disk.

    Parameter:
        garment_id: UUID of the garment
        norm_result: Output from normalize_image() with image_bytes and variants

    Returns:
        {
            "full": "/api/images/{id}/full.png",
            "display": "/api/images/{id}/display.png",
            "preview": "/api/images/{id}/preview.png",
            "success": True
        }
    """
    _ensure_dir()
    garment_dir = IMAGES_DIR / garment_id
    garment_dir.mkdir(parents=True, exist_ok=True)

    try:
        # Save 1024px full
        (garment_dir / "full.png").write_bytes(norm_result["image_bytes"])

        # Save 512px display
        if 512 in norm_result.get("variants", {}):
            (garment_dir / "display.png").write_bytes(norm_result["variants"][512])

        # Save 256px preview
        if 256 in norm_result.get("variants", {}):
            (garment_dir / "preview.png").write_bytes(norm_result["variants"][256])

        return {
            "full": f"/api/images/{garment_id}/full.png",
            "display": f"/api/images/{garment_id}/display.png",
            "preview": f"/api/images/{garment_id}/preview.png",
            "success": True,
        }
    except Exception as e:
        return {
            "full": None,
            "display": None,
            "preview": None,
            "success": False,
            "error": str(e),
        }


def get_image_path(garment_id: str, variant: str) -> Path | None:
    """
    Get the file path for a stored image variant.

    Parameter:
        garment_id: UUID of the garment
        variant: "full", "display", or "preview"

    Returns:
        Path to file, or None if not found
    """
    path = IMAGES_DIR / garment_id / f"{variant}.png"
    return path if path.exists() else None


def delete_garment_images(garment_id: str) -> bool:
    """Delete all stored images for a garment."""
    garment_dir = IMAGES_DIR / garment_id
    if not garment_dir.exists():
        return False
    for f in garment_dir.iterdir():
        f.unlink()
    garment_dir.rmdir()
    return True
