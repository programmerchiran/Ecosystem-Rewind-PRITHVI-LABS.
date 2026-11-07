from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from backend.app.config import settings
from backend.app.api.areas_router import router as areas_router
from backend.app.api.health_router import router as health_router
from backend.app.api.network_router import router as network_router
from backend.app.api.domino_router import router as domino_router
from backend.app.api.recommendation_router import router as recommendation_router
from backend.app.api.scenario_router import router as scenario_router
from backend.app.api.habitat_router import router as habitat_router
from backend.app.api.ai_chat_router import router as ai_chat_router

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="Ecosystem Rewind - AI-powered ecosystem recovery intelligence platform developed by PRITHVI LABS.",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json"
)

# CORS configuration for Flutter Web development & production
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Health endpoint
@app.get("/api/health", tags=["System"])
@app.get("/health", tags=["System"])
def health_check():
    return {
        "status": "healthy",
        "service": settings.APP_NAME,
        "organization": settings.ORGANIZATION,
        "version": settings.APP_VERSION
    }

# Root endpoint
@app.get("/", tags=["System"])
def root():
    return {
        "message": "Welcome to Ecosystem Rewind API",
        "organization": settings.ORGANIZATION,
        "version": settings.APP_VERSION,
        "documentation": "/docs"
    }

# Register all API routers
app.include_router(areas_router, prefix=settings.API_PREFIX)
app.include_router(health_router, prefix=settings.API_PREFIX)
app.include_router(network_router, prefix=settings.API_PREFIX)
app.include_router(domino_router, prefix=settings.API_PREFIX)
app.include_router(recommendation_router, prefix=settings.API_PREFIX)
app.include_router(scenario_router, prefix=settings.API_PREFIX)
app.include_router(habitat_router, prefix=settings.API_PREFIX)
app.include_router(ai_chat_router, prefix=settings.API_PREFIX)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("backend.app.main:app", host="127.0.0.1", port=8000, reload=True)
