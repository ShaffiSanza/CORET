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

    # --- Shopify ---
    shopify_store_domain: str = ""        # f.eks. "brand-name.myshopify.com"
    shopify_access_token: str = ""        # Admin API access token (legacy manual)
    shopify_webhook_secret: str = ""      # Webhook HMAC validation secret
    shopify_api_key: str = ""             # OAuth app client ID
    shopify_api_secret: str = ""          # OAuth app client secret
    shopify_scopes: str = "read_products,read_product_listings"
    shopify_redirect_uri: str = ""        # OAuth callback URL

    # --- App-innstillinger ---
    allowed_origins: str = "https://coret-production.up.railway.app"  # CORS: kun egne domener
    public_url: str = "https://coret-production.up.railway.app"       # For å bygge fulle bilde-URLer
    environment: str = "development"  # "development" eller "production"

    # model_config forteller pydantic-settings HVOR den skal lete etter verdier
    model_config = {
        "env_file": ".env",           # Les fra .env-filen
        "env_file_encoding": "utf-8",
        "extra": "ignore",            # Ignorer ukjente variabler i .env (f.eks. RAILWAY_TOKEN)
    }


# Opprett en global instans som brukes overalt i appen.
# Denne leses én gang ved oppstart — ikke for hver request.
settings = Settings()
