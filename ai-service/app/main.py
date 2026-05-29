import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import food_analysis, recipes
from app.config import settings

logger = logging.getLogger(__name__)

app = FastAPI(
    title="Forkcast AI Service",
    description="Lightweight AI-powered food analysis and recipe generation (API-only, no self-hosted models)",
    version="2.0.0",
    docs_url="/docs",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(food_analysis.router, prefix="/ai", tags=["Food Analysis"])
app.include_router(recipes.router, prefix="/ai", tags=["Recipes"])


@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "forkcast-ai", "version": "2.0.0"}
