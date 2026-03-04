# Services-pakken: all forretningslogikk bor her
# Hver fil = en tjeneste (product search, color extraction, osv.)
# Services kjenner IKKE til HTTP/FastAPI — de tar inn data og returnerer data
# Routeren (routers/pipeline.py) kobler HTTP-endepunkter til services
