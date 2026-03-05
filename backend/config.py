"""
CORET Backend — Konfigurasjon

Bruker pydantic-settings for å laste inn konfigurasjon fra .env-filen.
Alle API-nokler og innstillinger bor her — ALDRI hardkodet i koden.

Slik funker det:
  1. pydantic-settings leser automatisk fra .env-filen
  2. Miljovariable (f.eks. på Railway) overstyrer .env
  3. Default-verdier brukes hvis ingenting er satt

Bruk:
  from backend.config import settings
  api_key = settings.serpapi_key
"""

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """App-konfigurasjon. Alle felt kan settes via .env eller miljovariable."""

    # --- API-nokler ---
    serpapi_key: str = ""             # For produktsok (SerpAPI)
    upcitemdb_key: str = ""           # For strekkode-oppslag (ikke nodvendig for trial)
    photoroom_api_key: str = ""       # For bildeforbedring (Photoroom, Pro-funksjon)

    # --- Sikkerhet ---
    coret_api_key: str = ""           # API-nøkkel som iOS-appen sender med hver request
    rate_limit_per_minute: int = 30   # Maks antall requests per minutt per IP

    # --- App-innstillinger ---
    allowed_origins: str = "https://coret-production.up.railway.app"  # CORS: kun egne domener
    environment: str = "development"  # "development" eller "production"

    # model_config forteller pydantic-settings HVOR den skal lete etter verdier
    model_config = {
        "env_file": ".env",           # Les fra .env-filen
        "env_file_encoding": "utf-8",
    }


# Opprett en global instans som brukes overalt i appen.
# Denne leses én gang ved oppstart — ikke for hver request.
settings = Settings()
