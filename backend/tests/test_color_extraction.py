"""
CORET Backend — Color Extraction Tester

Tester for fargeekstraksjon og fargetemperatur-klassifisering.

Disse testene bruker:
  1. Enhetstester for hjelpefunksjoner (rgb_to_hex, classify_color_temp)
  2. Integrasjonstester via API-endepunktet (POST /api/extract-colors)

For API-testene lager vi små testbilder med Pillow (PIL).
Vi trenger ikke ekte bilder — en 10x10px ensfarget firkant er nok.
"""

import io
import pytest
from PIL import Image

from services.color_extraction import (
    rgb_to_hex,
    rgb_to_hsl,
    classify_color_temp,
    extract_colors_from_image,
)
from models.enums import ColorTemp


# ============================================================
# Hjelpefunksjon: Lag et testbilde med en bestemt farge
# ============================================================

def make_test_image(r: int, g: int, b: int) -> bytes:
    """Lag et lite testbilde (10x10 px) med én farge og returner som bytes.

    Bruker Pillow til å lage bildet i minnet.
    'RGB' betyr at bildet har 3 kanaler (rod, gronn, blå).
    """
    img = Image.new("RGB", (10, 10), color=(r, g, b))
    buffer = io.BytesIO()
    img.save(buffer, format="PNG")
    return buffer.getvalue()  # Returner rå PNG-bytes


# ============================================================
# Test: rgb_to_hex
# ============================================================

def test_rgb_to_hex_black():
    """Svart (0,0,0) skal bli #000000."""
    assert rgb_to_hex(0, 0, 0) == "#000000"


def test_rgb_to_hex_white():
    """Hvit (255,255,255) skal bli #FFFFFF."""
    assert rgb_to_hex(255, 255, 255) == "#FFFFFF"


def test_rgb_to_hex_red():
    """Ren rod (255,0,0) skal bli #FF0000."""
    assert rgb_to_hex(255, 0, 0) == "#FF0000"


def test_rgb_to_hex_custom():
    """Tilfeldig farge skal formateres riktig."""
    assert rgb_to_hex(26, 26, 46) == "#1A1A2E"


# ============================================================
# Test: classify_color_temp
# ============================================================

def test_warm_red():
    """Rod (255, 0, 0) skal klassifiseres som warm."""
    assert classify_color_temp(255, 0, 0) == ColorTemp.warm


def test_warm_orange():
    """Oransje (255, 165, 0) skal klassifiseres som warm."""
    assert classify_color_temp(255, 165, 0) == ColorTemp.warm


def test_warm_yellow():
    """Gul (255, 255, 0) skal klassifiseres som warm."""
    assert classify_color_temp(255, 255, 0) == ColorTemp.warm


def test_cool_blue():
    """Blå (0, 0, 255) skal klassifiseres som cool."""
    assert classify_color_temp(0, 0, 255) == ColorTemp.cool


def test_cool_green():
    """Gronn (0, 128, 0) skal klassifiseres som cool."""
    assert classify_color_temp(0, 128, 0) == ColorTemp.cool


def test_cool_purple():
    """Lilla (128, 0, 128) skal klassifiseres som cool."""
    assert classify_color_temp(128, 0, 128) == ColorTemp.cool


def test_neutral_gray():
    """Grå (128, 128, 128) har lav metning → neutral."""
    assert classify_color_temp(128, 128, 128) == ColorTemp.neutral


def test_neutral_black():
    """Svart (10, 10, 10) har veldig lav lyshet → neutral."""
    assert classify_color_temp(10, 10, 10) == ColorTemp.neutral


def test_neutral_white():
    """Hvit (245, 245, 245) har veldig hoy lyshet → neutral."""
    assert classify_color_temp(245, 245, 245) == ColorTemp.neutral


def test_neutral_beige():
    """Beige/off-white (220, 215, 210) har lav metning → neutral."""
    assert classify_color_temp(220, 215, 210) == ColorTemp.neutral


# ============================================================
# Test: extract_colors_from_image (integrert)
# ============================================================

def test_extract_red_image():
    """Et helrodt bilde skal gi warm temperatur."""
    image_bytes = make_test_image(200, 30, 30)
    result = extract_colors_from_image(image_bytes)

    assert result["color_temperature"] == ColorTemp.warm
    assert result["dominant_color"].startswith("#")
    assert len(result["dominant_color"]) == 7  # #RRGGBB format


def test_extract_blue_image():
    """Et helblått bilde skal gi cool temperatur."""
    image_bytes = make_test_image(30, 30, 200)
    result = extract_colors_from_image(image_bytes)

    assert result["color_temperature"] == ColorTemp.cool


def test_extract_gray_image():
    """Et helgrått bilde skal gi neutral temperatur."""
    image_bytes = make_test_image(128, 128, 128)
    result = extract_colors_from_image(image_bytes)

    assert result["color_temperature"] == ColorTemp.neutral


def test_extract_invalid_image():
    """Ugyldige bytes skal returnere fallback-verdier (aldri krasje)."""
    result = extract_colors_from_image(b"dette er ikke et bilde")

    assert result["dominant_color"] == "#000000"
    assert result["color_temperature"] == ColorTemp.neutral
    assert result["palette"] == []


def test_extract_empty_bytes():
    """Tomme bytes skal returnere fallback-verdier."""
    result = extract_colors_from_image(b"")

    assert result["dominant_color"] == "#000000"
    assert result["color_temperature"] == ColorTemp.neutral


# ============================================================
# Test: API endpoint (POST /api/extract-colors)
# ============================================================

@pytest.mark.asyncio
async def test_api_extract_colors(client):
    """Endepunktet skal akseptere en bildeopplasting og returnere fargedata."""
    # Lag et rodt testbilde
    image_bytes = make_test_image(200, 30, 30)

    # Send som multipart/form-data (fileopplasting)
    response = await client.post(
        "/api/extract-colors",
        files={"image": ("test.png", image_bytes, "image/png")},
    )

    assert response.status_code == 200
    data = response.json()
    assert data["color_temperature"] == "warm"
    assert data["dominant_color"].startswith("#")


@pytest.mark.asyncio
async def test_api_extract_colors_hex_format(client):
    """Hex-formatet skal vaere #RRGGBB (7 tegn)."""
    image_bytes = make_test_image(0, 100, 200)

    response = await client.post(
        "/api/extract-colors",
        files={"image": ("test.png", image_bytes, "image/png")},
    )

    data = response.json()
    hex_color = data["dominant_color"]

    # Sjekk format: starter med # og har 6 hex-tegn etter
    assert hex_color[0] == "#"
    assert len(hex_color) == 7
    # Sjekk at det er gyldige hex-tegn (0-9, A-F)
    int(hex_color[1:], 16)  # Ville kastet ValueError hvis ugyldig
