"""
CORET Backend — Hovedapplikasjon

Dette er INNGANGSPUNKTET til backend-en.
Når du kjorer: uvicorn backend.main:app --reload
...så er det DENNE filen som starter opp.

Hva den gjor:
  1. Oppretter en FastAPI-app
  2. Legger til CORS-middleware (lar iOS-appen snakke med backend-en)
  3. Monterer routeren (alle /api/... endepunktene)
  4. Har et helsesjekk-endpoint (/api/health)
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from config import settings
from routers import pipeline

# Opprett FastAPI-appen
# title/description vises på den automatiske API-dokumentasjonen (/docs)
app = FastAPI(
    title="CORET Backend",
    description="Bilde-pipeline og metadata-tjenester for CORET wardrobe OS",
    version="0.1.0",
)

# CORS-middleware:
# CORS (Cross-Origin Resource Sharing) er en sikkerhetsmekanisme i nettlesere.
# Uten dette ville nettlesere blokkere requests fra andre domener.
# iOS-apper har ikke dette problemet, men det er god praksis å konfigurere det.
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins.split(","),  # Hvilke domener kan kalle oss
    allow_credentials=True,
    allow_methods=["*"],     # Tillat alle HTTP-metoder (GET, POST, osv.)
    allow_headers=["*"],     # Tillat alle headere
)

# Monter pipeline-routeren med /api-prefix.
# Alle endpoints i pipeline.py får automatisk /api foran seg:
#   @router.post("/product-search") → POST /api/product-search
app.include_router(pipeline.router, prefix="/api")


# Helsesjekk — Railway bruker denne for å sjekke om appen lever.
# Også nyttig for iOS-appen å sjekke om backend-en er tilgjengelig.
@app.get("/api/health")
async def health():
    """Returner status og versjon. Hvis denne svarer, lever backend-en."""
    return {"status": "ok", "version": "0.1.0"}
