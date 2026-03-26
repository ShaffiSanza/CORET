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

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from starlette.responses import JSONResponse

import sentry_sdk

from config import settings
from routers import pipeline, garments, wardrobe, outfits, wear, discover, brands, profile, auth
from services.security_logger import log_invalid_api_key

# Initialize Sentry BEFORE app creation
if settings.sentry_dsn:
    sentry_sdk.init(
        dsn=settings.sentry_dsn,
        send_default_pii=False,  # Don't send user data
        traces_sample_rate=0.1,  # 10% of requests for performance monitoring
        environment=settings.environment,
    )

logger = logging.getLogger(__name__)

# Startup warning if API key is not configured
if not settings.coret_api_key:
    logger.warning("coret_api_key is EMPTY — API key auth is disabled. Set CORET_API_KEY in production.")


# ============================================================
# Rate Limiter Middleware (pure ASGI)
# Begrenser antall requests per IP per minutt.
# Beskytter mot spam og misbruk av API-kvotene våre.
# ============================================================
class RateLimitMiddleware:
    def __init__(self, app, max_requests: int = 30):
        self.app = app
        self.max_requests = max_requests
        self.requests: dict[str, list[float]] = defaultdict(list)
        self.window = 60

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        path = scope.get("path", "")
        if path == "/api/health":
            await self.app(scope, receive, send)
            return

        client = scope.get("client") or ("unknown", 0)
        client_ip = client[0]
        now = time.time()

        # Evict old IPs if dict gets too large
        if len(self.requests) > 10000:
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
            response = JSONResponse(
                status_code=429,
                content={"detail": "For mange requests. Vent litt og prøv igjen."}
            )
            await response(scope, receive, send)
            return

        # Registrer denne requesten
        self.requests[client_ip].append(now)
        await self.app(scope, receive, send)


# ============================================================
# API Key Auth Middleware (pure ASGI)
# Sjekker at requests har riktig API-nøkkel i headeren.
# iOS-appen sender: X-API-Key: <nøkkel>
# ============================================================
class APIKeyMiddleware:
    PUBLIC_PATHS = {"/api/health", "/docs", "/openapi.json", "/redoc",
                    "/api/auth/shopify", "/api/auth/shopify/callback"}

    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        # Hopp over auth hvis ingen API-nøkkel er konfigurert (development)
        if not settings.coret_api_key:
            await self.app(scope, receive, send)
            return

        path = scope.get("path", "")

        # Offentlige endpoints trenger ikke auth
        if path in self.PUBLIC_PATHS:
            await self.app(scope, receive, send)
            return

        # Bilder er offentlige (AsyncImage kan ikke sende auth-headers)
        if path.startswith("/api/images/"):
            await self.app(scope, receive, send)
            return

        # Sjekk API-nøkkelen i headeren
        headers = dict(scope.get("headers", []))
        api_key = headers.get(b"x-api-key", b"").decode()

        if not api_key or not hmac.compare_digest(api_key, settings.coret_api_key):
            client = scope.get("client") or ("unknown", 0)
            log_invalid_api_key(client[0], path)
            response = JSONResponse(
                status_code=401,
                content={"detail": "Ugyldig eller manglende API-nøkkel."}
            )
            await response(scope, receive, send)
            return

        await self.app(scope, receive, send)


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
# 1. Rate limiting — stopp spam FØR vi sjekker auth
app.add_middleware(RateLimitMiddleware, max_requests=settings.rate_limit_per_minute)

# 2. API-nøkkel — sjekk at klienten er autorisert
app.add_middleware(APIKeyMiddleware)

# 3. CORS — kontroller hvilke domener som kan kalle oss
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins.split(","),
    allow_credentials=False,  # API key auth via header, not cookies
    allow_methods=["POST", "GET", "PUT", "DELETE"],
    allow_headers=["Content-Type", "X-API-Key"],
)

# Security headers — @app.middleware shorthand (also pure ASGI under the hood)
@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains; preload"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Content-Security-Policy"] = "default-src 'self'; img-src 'self' https: data:; script-src 'self'; style-src 'self' 'unsafe-inline'"
    return response

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
