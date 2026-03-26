"""
Re-process existing garment images through the v2 pipeline.

Takes the old 1024x1024 opaque images, strips the baked off-white background,
and re-normalizes as category-aware transparent PNGs.

Usage: cd backend && source .venv/bin/activate && python scripts/reprocess_images.py
"""

import sys
from pathlib import Path

# Add parent to path so we can import services
sys.path.insert(0, str(Path(__file__).parent.parent))

from io import BytesIO
from PIL import Image, ImageFilter
import numpy as np

from services.image_normalize import normalize_image
from services.image_storage import save_garment_images, IMAGES_DIR

# Known garments with their categories and whether they're light-colored
GARMENTS = {
    "f07b9c07-a855-5a59-a7bf-dcbf535c5930": ("accessory", False),  # brown belt
    "dc37eb71-484b-5c14-aa55-429947a46b76": ("upper", False),       # black tees
    "e24a84b2-9b45-579e-b649-3da952b94efd": ("shoes", True),        # white AF1
    "43016443-720b-58b9-bda4-fba6a2c644db": ("upper", False),       # grey hoodie
    "37ee0da1-44e9-530b-b456-c560fceefb61": ("lower", False),       # levi's jeans
    "b8468afb-0046-5f77-8c54-57d7377a243b": ("upper", True),        # white shirt
}

# Old studio background color that was baked in
OLD_BG = (248, 246, 242)  # #F8F6F2
TOLERANCE = 30  # color distance tolerance for background detection
TOLERANCE_LIGHT = 8  # much tighter for white/light garments


def strip_opaque_background(img: Image.Image, is_light_garment: bool = False) -> Image.Image:
    """Remove the old baked off-white background by color-keying.

    For light/white garments, uses much tighter tolerance to preserve the garment.
    For dark garments, uses wider tolerance for cleaner edges.
    """
    tol = TOLERANCE_LIGHT if is_light_garment else TOLERANCE
    img = img.convert("RGBA")
    data = np.array(img)

    r, g, b = data[:, :, 0], data[:, :, 1], data[:, :, 2]
    dist = np.sqrt(
        (r.astype(float) - OLD_BG[0]) ** 2
        + (g.astype(float) - OLD_BG[1]) ** 2
        + (b.astype(float) - OLD_BG[2]) ** 2
    )

    # For light garments: only remove pixels that EXACTLY match the old bg
    bg_mask = dist < tol

    if not is_light_garment:
        # Soft edge for dark garments
        edge_mask = (dist >= tol) & (dist < tol * 2)
        edge_alpha = ((dist[edge_mask] - tol) / tol * 255).astype(np.uint8)
        alpha = data[:, :, 3].copy()
        alpha[bg_mask] = 0
        alpha[edge_mask] = np.minimum(alpha[edge_mask], edge_alpha)
    else:
        # For light garments: only flood-fill from edges (corners)
        # to avoid removing the garment body
        alpha = data[:, :, 3].copy()
        # Only make bg pixels transparent if they're connected to the edge
        # Simple approach: only remove bg in the outer 5% margin
        h, w = alpha.shape
        margin_x = int(w * 0.05)
        margin_y = int(h * 0.05)
        # Top/bottom margins
        alpha[:margin_y, :][bg_mask[:margin_y, :]] = 0
        alpha[-margin_y:, :][bg_mask[-margin_y:, :]] = 0
        # Left/right margins
        alpha[:, :margin_x][bg_mask[:, :margin_x]] = 0
        alpha[:, -margin_x:][bg_mask[:, -margin_x:]] = 0

    data[:, :, 3] = alpha
    return Image.fromarray(data)


def process_garment(garment_id: str, category: str, is_light: bool = False) -> bool:
    """Re-process a single garment through the v2 pipeline."""
    full_path = IMAGES_DIR / garment_id / "full.png"
    if not full_path.exists():
        print(f"  SKIP: {full_path} not found")
        return False

    # Load old image
    img = Image.open(full_path)
    print(f"  Original: {img.size}, mode={img.mode}")

    # Strip old baked background
    transparent = strip_opaque_background(img, is_light_garment=is_light)

    # Check if we got reasonable content
    bbox = transparent.getbbox()
    if not bbox:
        print(f"  WARN: image became fully transparent after bg strip")
        return False

    content_area = (bbox[2] - bbox[0]) * (bbox[3] - bbox[1])
    total_area = img.size[0] * img.size[1]
    print(f"  Content: {bbox[2]-bbox[0]}x{bbox[3]-bbox[1]} ({content_area/total_area*100:.0f}% of canvas)")

    # Export transparent image as bytes
    buf = BytesIO()
    transparent.save(buf, format="PNG")
    transparent_bytes = buf.getvalue()

    # Run through v2 normalizer
    result = normalize_image(transparent_bytes, category=category)
    if not result["success"]:
        print(f"  ERROR: {result['error']}")
        return False

    meta = result["metadata"]
    print(f"  Normalized: {meta['canvas_width']}x{meta['canvas_height']}, "
          f"fill={meta['fill_ratio']:.0%}, anchor_y={meta['anchor_y']}")

    # Save back to disk (overwrites old variants)
    save_result = save_garment_images(garment_id, result)
    if save_result["success"]:
        print(f"  Saved: full + display + preview")
        return True
    else:
        print(f"  ERROR saving: {save_result.get('error')}")
        return False


def main():
    print("CORET Image Re-processor v2")
    print(f"Images dir: {IMAGES_DIR}")
    print(f"Processing {len(GARMENTS)} garments...\n")

    success = 0
    for gid, (category, is_light) in GARMENTS.items():
        print(f"[{category.upper():>10}] {gid} {'(light)' if is_light else ''}")
        if process_garment(gid, category, is_light):
            success += 1
        print()

    print(f"Done: {success}/{len(GARMENTS)} re-processed successfully.")


if __name__ == "__main__":
    main()
