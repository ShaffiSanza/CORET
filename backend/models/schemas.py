"""
CORET Backend — Pydantic Schemas

Pydantic-modeller definerer FORMEN på data som går inn og ut av API-et.
FastAPI bruker disse til:
  1. Automatisk validering av innkommende data
  2. Automatisk generering av API-dokumentasjon (OpenAPI/Swagger)
  3. Type-hints som editoren din forstår

Navnekonvensjon:
  - *Request  = data som KOMMER INN til et endpoint
  - *Response = data som GÅR UT fra et endpoint
"""

from pydantic import BaseModel, Field
from typing import Optional

from .enums import Category, BaseGroup, ColorTemp


# ============================================================
# Product Search — Sok etter plagg med tekst (merke + modell)
# ============================================================

class ProductSearchRequest(BaseModel):
    """Innkommende sokerequest.
    Brukeren skriver f.eks. 'Nike Air Force 1 white'."""
    query: str = Field(
        ...,                     # ... betyr "pakrevd felt" (kan ikke vaere tomt)
        min_length=1,            # Minimum 1 tegn
        max_length=500,          # Maks 500 tegn
        description="Soketekst, f.eks. 'Nike Air Force 1 white'"
    )


class ProductSearchResponse(BaseModel):
    """Resultat fra produktsok.
    success=True betyr at vi fant noe. False = ingen treff."""
    image_url: Optional[str] = None       # URL til studiobilde (eller None)
    product_title: Optional[str] = None   # Produktnavn fra sokeresultat
    brand: Optional[str] = None           # Merke (Nike, Diesel, osv.)
    source_url: Optional[str] = None      # Lenke til produktsiden
    success: bool                         # Fant vi noe?


# ============================================================
# Barcode Lookup — Slå opp plagg via strekkode
# ============================================================

class BarcodeLookupRequest(BaseModel):
    """Innkommende strekkode-request.
    Strekkoden er en streng med 8-14 siffer (UPC eller EAN-format)."""
    barcode: str = Field(
        ...,
        min_length=8,
        max_length=14,
        description="UPC/EAN strekkode (8-14 siffer)"
    )


class BarcodeLookupResponse(BaseModel):
    """Resultat fra strekkode-oppslag.
    Inkluderer bilde + produktinfo hvis funnet."""
    image_url: Optional[str] = None
    product_title: Optional[str] = None
    brand: Optional[str] = None
    category: Optional[str] = None        # Rå kategori fra databasen
    description: Optional[str] = None
    success: bool


# ============================================================
# Color Extraction — Hent ut dominerende farge fra bilde
# ============================================================

class ColorExtractionResponse(BaseModel):
    """Resultat fra fargeanalyse.
    dominant_color er hex-kode (#RRGGBB) som mates rett inn i Garment.dominantColor.
    color_temperature er warm/cool/neutral som mates inn i Garment.colorTemperature."""
    dominant_color: str = Field(
        ...,
        description="Hex fargekode, f.eks. '#1A1A2E'"
    )
    color_temperature: ColorTemp           # warm, cool, eller neutral
    palette: list[str] = Field(
        default_factory=list,              # default_factory=list betyr "tom liste som default"
        description="Topp 5 farger som hex-strenger"
    )


# ============================================================
# Product Metadata — Auto-utfylling av plagg-info
# ============================================================

class ProductMetadataRequest(BaseModel):
    """Innkommende metadata-request.
    Tar produkttittel (og valgfritt merke/beskrivelse) og
    forsoker å gjette CORET-kategori og plaggtype."""
    product_title: str
    brand: Optional[str] = None
    description: Optional[str] = None


class ProductMetadataResponse(BaseModel):
    """Foreslåtte verdier for et plagg.
    confidence (0.0-1.0) sier hvor sikker vi er.
    iOS-appen bestemmer om den auto-fyller eller spor brukeren."""
    suggested_name: Optional[str] = None
    suggested_category: Optional[Category] = None
    suggested_base_group: Optional[BaseGroup] = None
    suggested_color_temperature: Optional[ColorTemp] = None
    confidence: float = Field(
        0.0,
        ge=0.0,    # ge = "greater than or equal" (>=)
        le=1.0,    # le = "less than or equal" (<=)
        description="0.0 = ingen anelse, 1.0 = helt sikker"
    )
    success: bool


# ============================================================
# Image Polish — Bildeforbedring via Photoroom (Pro)
# ============================================================

class ImagePolishResponse(BaseModel):
    """Resultat fra bildeforbedring.
    Ved suksess returneres det polerte bildet som rå bytes (ikke via denne modellen).
    Denne modellen brukes kun ved FEIL."""
    success: bool
    error: Optional[str] = None


# ============================================================
# Health — Helsesjekk for å bekrefte at backend kjorer
# ============================================================

class HealthResponse(BaseModel):
    """Enkel helsesjekk. Railway bruker denne for å vite at appen lever."""
    status: str = "ok"
    version: str = "0.1.0"
