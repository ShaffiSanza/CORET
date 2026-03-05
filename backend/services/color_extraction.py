"""
CORET Backend — Color Extraction Service

Denne servicen tar inn et bilde og returnerer:
  1. Dominerende farge som hex-kode (#RRGGBB)
  2. Fargetemperatur (warm/cool/neutral) — matches Garment.colorTemperature
  3. Fargepalett (topp 5 farger)

Bruker:
  - colorthief: Henter dominerende farge fra bilder
  - colorsys (innebygd Python): Konverterer mellom fargesystemer (RGB → HSL)

Flyten:
  Bilde → colorthief → RGB-verdier → hex-streng + HSL-analyse → ColorTemp
"""

import colorsys
from io import BytesIO

from colorthief import ColorThief

from models.enums import ColorTemp


def rgb_to_hex(r: int, g: int, b: int) -> str:
    """Konverter RGB-verdier (0-255) til hex-streng (#RRGGBB).

    Eksempel:
        rgb_to_hex(26, 26, 46) → "#1A1A2E"

    f-string formatering:
        :02X betyr: 2 siffer, stor bokstav hex, fyll med 0 foran
        Så 10 → "0A", 255 → "FF", 0 → "00"
    """
    return f"#{r:02X}{g:02X}{b:02X}"


def rgb_to_hsl(r: int, g: int, b: int) -> tuple[float, float, float]:
    """Konverter RGB (0-255) til HSL (Hue, Saturation, Lightness).

    Returnerer:
        (h, s, l) der:
        - h = 0-360 (fargetone: 0=rod, 120=gronn, 240=blå)
        - s = 0-100 (metning: 0=grå, 100=full farge)
        - l = 0-100 (lyshet: 0=svart, 50=normal, 100=hvit)

    Python sin colorsys modul returnerer HLS (ikke HSL), og
    alle verdier er 0.0-1.0, så vi må skalere opp.
    """
    # colorsys vil ha verdier fra 0.0 til 1.0
    r_norm = r / 255.0
    g_norm = g / 255.0
    b_norm = b / 255.0

    # NB: Python kaller det HLS, ikke HSL — rekkfolgen er H, L, S
    h, l, s = colorsys.rgb_to_hls(r_norm, g_norm, b_norm)

    # Skaler opp til vanlige verdier
    return (h * 360.0, s * 100.0, l * 100.0)


def classify_color_temp(r: int, g: int, b: int) -> ColorTemp:
    """Klassifiser en RGB-farge som warm, cool, eller neutral.

    Logikken matcher CORET engine sin CohesionEngine:
      - neutral = grå/svart/hvit (lav metning eller ekstrem lyshet)
      - warm = rode/oransje/gule toner (hue 0-60 eller 300-360)
      - cool = blå/gronne/lilla toner (alt annet)

    Hue-hjulet (0-360 grader):
        0   = Rod
        30  = Oransje
        60  = Gul
        120 = Gronn
        180 = Cyan
        240 = Blå
        300 = Magenta/lilla
        360 = Rod (tilbake til start)
    """
    h, s, l = rgb_to_hsl(r, g, b)

    # 1. Sjekk for noytrale farger FORST (tar prioritet)
    #    Lav metning = grå-aktig (nesten ingen farge)
    #    Veldig lys = naer hvit
    #    Veldig mork = naer svart
    if s < 15 or l > 85 or l < 15:
        return ColorTemp.neutral

    # 2. Varme farger: rod, oransje, gul, rosa-rod
    #    Hue 0-60 (rod → gul) eller 330-360 (rosa/rod)
    #    NB: 300-330 (lilla/magenta) regnes som COOL i motekontekst
    if h <= 60 or h >= 330:
        return ColorTemp.warm

    # 3. Alt annet er kalde farger: gronn, cyan, blå, lilla
    return ColorTemp.cool


def extract_colors_from_image(image_bytes: bytes) -> dict:
    """Hovedfunksjonen — ta inn et bilde, returner fargedata.

    Parametere:
        image_bytes: Råe bytes fra en bildefil (JPG, PNG, osv.)

    Returnerer:
        {
            "dominant_color": "#1A1A2E",        # Hex-kode
            "color_temperature": ColorTemp.cool, # warm/cool/neutral
            "palette": ["#1A1A2E", "#2D2D44", ...],  # Topp 5 farger
        }

    Feilhåndtering:
        Hvis noe feiler, returnerer vi svart (#000000) som neutral.
        Appen skal ALDRI krasje pga et dårlig bilde.
    """
    try:
        # BytesIO lar oss behandle bytes som en "fil" i minnet
        # (colorthief forventer et fil-lignende objekt, ikke rå bytes)
        image_file = BytesIO(image_bytes)

        # ColorThief analyserer bildet
        ct = ColorThief(image_file)

        # Hent dominerende farge som (R, G, B) tuple
        # quality=1 = beste kvalitet (langsomst), quality=10 = raskest
        dominant_rgb = ct.get_color(quality=1)

        # Hent fargepalett (topp 6, men forste er ofte lik dominant)
        # color_count=6 gir oss 5-6 farger (colorthief kan returnere faerre)
        palette_rgb = ct.get_palette(color_count=6, quality=1)

        # --- White-background guard ---
        # Mange produktbilder har hvit bakgrunn. Hvis den dominerende fargen
        # er naer-hvit (lyshet > 90%), bruker vi den NEST dominerende fargen.
        r, g, b = dominant_rgb
        _, _, lightness = rgb_to_hsl(r, g, b)

        if lightness > 90 and len(palette_rgb) > 1:
            # Forste farge er for lys — bruk neste farge i paletten
            dominant_rgb = palette_rgb[1]

        # Konverter dominant farge til hex og klassifiser temperatur
        r, g, b = dominant_rgb
        dominant_hex = rgb_to_hex(r, g, b)
        color_temp = classify_color_temp(r, g, b)

        # Konverter hele paletten til hex-strenger (maks 5)
        palette_hex = [
            rgb_to_hex(pr, pg, pb)
            for pr, pg, pb in palette_rgb[:5]
        ]

        return {
            "dominant_color": dominant_hex,
            "color_temperature": color_temp,
            "palette": palette_hex,
        }

    except Exception:
        # Hvis NOE feiler (korrupt bilde, tomt bilde, osv.):
        # Returner trygge default-verdier i stedet for å krasje
        return {
            "dominant_color": "#000000",
            "color_temperature": ColorTemp.neutral,
            "palette": [],
        }
