"""
CORET Backend — Hovedapplikasjon

Dette er INNGANGSPUNKTET til backend-en.
Når du kjorer: uvicorn main:app --reload
...så er det DENNE filen som starter opp.

Hva den gjor:
  1. Oppretter en FastAPI-app
  2. Legger til CORS-middleware (lar iOS-appen snakke med backend-en)
  3. Legger til rate limiting (begrenser antall requests per IP)
  4. Legger til API-nøkkel-autentisering (kun appen kan bruke API-et)
  5. Monterer routeren (alle /api/... endepunktene)
  6. Har et helsesjekk-endpoint (/api/health)
"""

import hmac
import time
from collections import defaultdict

from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware

from config import settings
from routers import pipeline


# ============================================================
# Rate Limiter Middleware
# Begrenser antall requests per IP per minutt.
# Beskytter mot spam og misbruk av API-kvotene våre.
# ============================================================
class RateLimitMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, max_requests: int = 30):
        super().__init__(app)
        self.max_requests = max_requests
        # Dict som lagrer {ip: [timestamp, timestamp, ...]}
        self.requests: dict[str, list[float]] = defaultdict(list)

    async def dispatch(self, request: Request, call_next):
        # Health-endpoint er unntatt fra rate limiting
        if request.url.path == "/api/health":
            return await call_next(request)

        client_ip = request.client.host if request.client else "unknown"
        now = time.time()

        # Fjern requests eldre enn 60 sekunder
        self.requests[client_ip] = [
            t for t in self.requests[client_ip] if now - t < 60
        ]

        # Sjekk om IP-en har brukt opp kvoten
        if len(self.requests[client_ip]) >= self.max_requests:
            raise HTTPException(
                status_code=429,
                detail="For mange requests. Vent litt og prøv igjen."
            )

        # Registrer denne requesten
        self.requests[client_ip].append(now)
        return await call_next(request)


# ============================================================
# API Key Auth Middleware
# Sjekker at requests har riktig API-nøkkel i headeren.
# iOS-appen sender: X-API-Key: <nøkkel>
# ============================================================
class APIKeyMiddleware(BaseHTTPMiddleware):
    # Endpoints som IKKE krever API-nøkkel
    PUBLIC_PATHS = {"/api/health", "/docs", "/openapi.json", "/redoc"}

    async def dispatch(self, request: Request, call_next):
        # Hopp over auth hvis ingen API-nøkkel er konfigurert (development)
        if not settings.coret_api_key:
            return await call_next(request)

        # Offentlige endpoints trenger ikke auth
        if request.url.path in self.PUBLIC_PATHS:
            return await call_next(request)

        # Sjekk API-nøkkelen i headeren
        api_key = request.headers.get("X-API-Key")
        if not api_key or not hmac.compare_digest(api_key, settings.coret_api_key):
            raise HTTPException(
                status_code=401,
                detail="Ugyldig eller manglende API-nøkkel."
            )

        return await call_next(request)


# Opprett FastAPI-appen
app = FastAPI(
    title="CORET Backend",
    description="Bilde-pipeline og metadata-tjenester for CORET wardrobe OS",
    version="0.1.0",
)

# Legg til sikkerhetslag (rekkefølge betyr noe — ytterste først)
# 1. Rate limiting — stopp spam FØR vi sjekker auth
app.add_middleware(RateLimitMiddleware, max_requests=settings.rate_limit_per_minute)

# 2. API-nøkkel — sjekk at klienten er autorisert
app.add_middleware(APIKeyMiddleware)

# 3. CORS — kontroller hvilke domener som kan kalle oss
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins.split(","),
    allow_credentials=True,
    allow_methods=["POST", "GET"],  # Kun metodene vi bruker
    allow_headers=["Content-Type", "X-API-Key"],
)

# Monter routere med /api-prefix
app.include_router(pipeline.router, prefix="/api")


# Helsesjekk — Railway bruker denne for å sjekke om appen lever.
@app.get("/api/health")
async def health():
    """Returner status og versjon. Hvis denne svarer, lever backend-en."""
    return {"status": "ok", "version": "0.1.0"}
