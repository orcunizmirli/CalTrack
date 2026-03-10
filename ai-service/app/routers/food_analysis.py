import logging
import time
from fastapi import APIRouter, UploadFile, File, HTTPException, Query
from app.services.vision_service import VisionService
from app.services.rag_service import RAGService
from app.models.schemas import FoodAnalysisResponse, FoodItem

logger = logging.getLogger(__name__)

router = APIRouter()
vision_service = VisionService()
rag_service = RAGService()


@router.post("/analyze-food", response_model=FoodAnalysisResponse)
async def analyze_food(
    image: UploadFile = File(...),
    meal_type: str | None = None,
    additional_context: str | None = None,
):
    """
    Analyze a food photo using AI vision models.

    Pipeline:
    1. Image preprocessing (resize, optimize)
    2. Primary model analysis (GPT-4o Vision)
    3. RAG enhancement with food database
    4. Nutrition calculation with confidence scoring
    """
    start_time = time.time()

    # Validate image
    if not image.content_type or not image.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Geçersiz dosya formatı. Lütfen bir resim yükleyin.")

    image_data = await image.read()
    max_size = 10 * 1024 * 1024  # 10MB
    if len(image_data) > max_size:
        raise HTTPException(status_code=400, detail="Resim boyutu 10MB'dan büyük olamaz.")

    try:
        # Step 1: AI Vision Analysis
        raw_result = await vision_service.analyze_food_image(
            image_data=image_data,
            meal_type=meal_type,
            additional_context=additional_context,
        )

        # Step 2: RAG Enhancement - match with food database
        enhanced_items: list[FoodItem] = []
        for item in raw_result.items:
            enhanced = await rag_service.enhance_food_item(item)
            enhanced_items.append(enhanced)

        # Step 3: Calculate totals
        total_calories = sum(item.calories for item in enhanced_items)
        total_protein = sum(item.protein_g for item in enhanced_items)
        total_carbs = sum(item.carbs_g for item in enhanced_items)
        total_fat = sum(item.fat_g for item in enhanced_items)
        avg_confidence = (
            sum(item.confidence for item in enhanced_items) / len(enhanced_items)
            if enhanced_items
            else 0
        )

        processing_ms = int((time.time() - start_time) * 1000)

        return FoodAnalysisResponse(
            items=enhanced_items,
            total_calories=total_calories,
            total_protein_g=total_protein,
            total_carbs_g=total_carbs,
            total_fat_g=total_fat,
            meal_description=raw_result.meal_description,
            confidence=avg_confidence,
            model_used=raw_result.model_used,
            processing_ms=processing_ms,
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Analiz hatası: {str(e)}")


@router.get("/search-foods")
async def search_foods(
    q: str = Query(..., min_length=2, description="Food search query"),
    limit: int = Query(5, ge=1, le=20),
):
    """
    Semantic food search using RAG embeddings.
    Searches the food database by name similarity using pgvector.
    """
    try:
        results = await rag_service.search_foods_by_name(q, top_k=limit)
        return {
            "query": q,
            "results": [
                {
                    "food_id": r["food_id"],
                    "name": r["food_name"],
                    "name_tr": r.get("food_name_tr"),
                    "calories_per_100g": float(r["calories"]),
                    "protein_g_per_100g": float(r.get("protein_g") or 0),
                    "carbs_g_per_100g": float(r.get("carbs_g") or 0),
                    "fat_g_per_100g": float(r.get("fat_g") or 0),
                    "similarity": round(1 - r["distance"], 3),
                }
                for r in results
            ],
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Arama hatası: {str(e)}")
