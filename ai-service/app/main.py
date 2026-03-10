import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import food_analysis, recipes
from app.config import settings
from app.db import init_db, close_pool

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    if settings.DATABASE_URL:
        try:
            await init_db()
            logger.info("Database initialized with pgvector support")
        except Exception as e:
            logger.warning(f"Database init failed (non-fatal): {e}")
    yield
    # Shutdown
    await close_pool()


app = FastAPI(
    title="CalTrack AI Service",
    description="AI-powered food analysis and recipe generation service",
    version="1.0.0",
    lifespan=lifespan,
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
    return {"status": "healthy", "service": "caltrack-ai"}
