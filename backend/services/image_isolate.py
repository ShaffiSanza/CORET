"""
CORET Backend — Garment Isolation Service

Fjerner mennesker/modeller fra klaebilder og beholder KUN plagget.
Bruker rembg (U2-Net, lokal) som primaer metode.
Faller tilbake til Photoroom hvis rembg feiler.

Forskjell fra image_polish.py:
- image_polish: fjerner bakgrunn, beholder personen (Photoroom /v1/segment)
- image_isolate: fjerner BADE bakgrunn OG person, beholder KUN plagget (rembg)
"""

import logging
from io import BytesIO

logger = logging.getLogger(__name__)


def isolate_garment(image_bytes: bytes) -> dict:
    """
    Fjern bakgrunn og modell fra et produktbilde.
    Beholder kun plagget paa transparent bakgrunn.

    Bruker rembg med U2-Net modell (lokal, ingen API-nokkel).

    Returns:
        {
            "image_bytes": b"...",
            "success": True,
            "method": "rembg"
        }
    """
    try:
        from rembg import remove

        # rembg.remove() tar inn bytes og returnerer bytes med transparent bg
        output_bytes = remove(
            image_bytes,
            alpha_matting=True,           # Bedre kanter
            alpha_matting_foreground_threshold=240,
            alpha_matting_background_threshold=10,
        )

        if not output_bytes:
            return {
                "image_bytes": None,
                "success": False,
                "error": "rembg returned empty result",
                "method": "rembg",
            }

        return {
            "image_bytes": output_bytes,
            "success": True,
            "error": None,
            "method": "rembg",
        }

    except Exception as e:
        logger.warning(f"rembg isolation failed: {e}")
        return {
            "image_bytes": None,
            "success": False,
            "error": str(e),
            "method": "rembg",
        }


async def isolate_garment_with_fallback(image_bytes: bytes) -> dict:
    """
    Proev Photoroom foerst (lettvekt API-kall, fungerer paa Railway).
    Hvis Photoroom feiler, proev rembg (lokal, tyngre).
    """
    import os

    # Primaer: Photoroom (fungerer paa Railway, lett API-kall)
    from services.image_polish import polish_image
    photoroom_result = await polish_image(image_bytes)
    if photoroom_result["success"]:
        return {
            "image_bytes": photoroom_result["image_bytes"],
            "success": True,
            "error": None,
            "method": "photoroom",
        }

    # Fallback: rembg (lokal, krever mer minne/CPU)
    # Kun hvis ENABLE_REMBG er satt eller vi er i development
    env = os.environ.get("ENVIRONMENT", "development")
    if env == "development" or os.environ.get("ENABLE_REMBG"):
        logger.info("Photoroom failed, trying rembg locally")
        result = isolate_garment(image_bytes)
        if result["success"]:
            return result

    return {
        "image_bytes": None,
        "success": False,
        "error": "Garment isolation failed",
        "method": "none",
    }
