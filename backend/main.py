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
import logging
import time
from collections import defaultdict

from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware

from config import settings
from routers import pipeline, garments, wardrobe, outfits, wear, discover, brands, profile, auth

logger = logging.getLogger(__name__)

# Startup warning if API key is not configured
if not settings.coret_api_key:
    logger.warning("coret_api_key is EMPTY — API key auth is disabled. Set CORET_API_KEY in production.")


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

    # Window size in seconds for rate limiting
    window = 60

    async def dispatch(self, request: Request, call_next):
        # Health-endpoint er unntatt fra rate limiting
        if request.url.path == "/api/health":
            return await call_next(request)

        # Get real client IP (behind reverse proxy)
        client_ip = request.headers.get("x-forwarded-for", "").split(",")[0].strip() or (
            request.client.host if request.client else "unknown"
        )
        now = time.time()

        # Evict old IPs if dict gets too large
        if len(self.requests) > 10000:
            # Keep only IPs with recent activity
            cutoff = now - self.window
            self.requests = defaultdict(list, {
                ip: times for ip, times in self.requests.items()
                if times and times[-1] > cutoff
            })

        # Fjern requests eldre enn 60 sekunder
        self.requests[client_ip] = [
            t for t in self.requests[client_ip] if now - t < self.window
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
    PUBLIC_PATHS = {"/api/health", "/docs", "/openapi.json", "/redoc",
                    "/api/auth/shopify", "/api/auth/shopify/callback"}

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
            from services.security_logger import log_invalid_api_key
            client_ip = request.client.host if request.client else "unknown"
            log_invalid_api_key(client_ip, request.url.path)
            raise HTTPException(
                status_code=401,
                detail="Ugyldig eller manglende API-nøkkel."
            )

        return await call_next(request)


# ============================================================
# Security Headers Middleware
# Legger til standard sikkerhetshoder på alle responses.
# ============================================================
class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        try:
            response = await call_next(request)
        except Exception:
            # Let exceptions (401, 422, etc.) propagate without crashing
            raise
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains; preload"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers["Content-Security-Policy"] = "default-src 'self'; img-src 'self' https: data:; script-src 'self'; style-src 'self' 'unsafe-inline'"
        return response


# Opprett FastAPI-appen (docs disabled in production)
docs_url = None if settings.environment == "production" else "/docs"
redoc_url = None if settings.environment == "production" else "/redoc"
app = FastAPI(
    title="CORET Backend",
    description="Bilde-pipeline og metadata-tjenester for CORET wardrobe OS",
    version="0.1.0",
    docs_url=docs_url,
    redoc_url=redoc_url,
)

# Legg til sikkerhetslag (rekkefølge betyr noe — ytterste først)
# 0. Security headers — alltid på
app.add_middleware(SecurityHeadersMiddleware)

# 1. Rate limiting — stopp spam FØR vi sjekker auth
app.add_middleware(RateLimitMiddleware, max_requests=settings.rate_limit_per_minute)

# 2. API-nøkkel — sjekk at klienten er autorisert
app.add_middleware(APIKeyMiddleware)

# 3. CORS — kontroller hvilke domener som kan kalle oss
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins.split(","),
    allow_credentials=True,
    allow_methods=["POST", "GET", "PUT", "DELETE"],
    allow_headers=["Content-Type", "X-API-Key"],
)

# Monter routere med /api-prefix
app.include_router(pipeline.router, prefix="/api")
app.include_router(garments.router, prefix="/api")
app.include_router(wardrobe.router, prefix="/api")
app.include_router(outfits.router, prefix="/api")
app.include_router(wear.router, prefix="/api")
app.include_router(discover.router, prefix="/api")
app.include_router(brands.router, prefix="/api")
app.include_router(profile.router, prefix="/api")
app.include_router(auth.router, prefix="/api")


# Helsesjekk — Railway bruker denne for å sjekke om appen lever.
@app.get("/api/health")
async def health():
    """Returner status og versjon. Hvis denne svarer, lever backend-en."""
    return {"status": "ok", "version": "0.1.0"}
