from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import food_analysis, recipes
from app.config import settings

app = FastAPI(
    title="CalTrack AI Service",
    description="AI-powered food analysis and recipe generation service",
    version="1.0.0",
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
