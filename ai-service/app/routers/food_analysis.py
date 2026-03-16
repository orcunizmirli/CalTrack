import logging
import time
from pydantic import BaseModel
from fastapi import APIRouter, UploadFile, File, HTTPException, Query
from app.services.vision_service import VisionService
from app.services.rag_service import RAGService
from app.models.schemas import (
    FoodAnalysisResponse,
    FoodItem,
    PortionOption,
    PortionUpdateRequest,
)
from app.services.portion_standards import get_standard_portions, get_portion_options
from app.services.portion_calibrator import calibrate_portions
from app.services.feedback_service import FeedbackService

logger = logging.getLogger(__name__)

router = APIRouter()
vision_service = VisionService()
rag_service = RAGService()
feedback_service = FeedbackService()


@router.post("/analyze-food", response_model=FoodAnalysisResponse)
async def analyze_food(
    image: UploadFile = File(...),
    meal_type: str | None = None,
    additional_context: str | None = None,
    user_id: str | None = None,
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
        # Step 1: AI Vision Analysis (includes reference object detection in single call)
        raw_result = await vision_service.analyze_food_image(
            image_data=image_data,
            meal_type=meal_type,
            additional_context=additional_context,
        )

        # Step 1.5: Calibrate portions using reference objects from the same response
        calibrated_items = calibrate_portions(
            raw_result.items, raw_result.reference_objects
        )

        # Step 2: RAG Enhancement - match with food database
        enhanced_items: list[FoodItem] = []
        for item in calibrated_items:
            enhanced = await rag_service.enhance_food_item(item)

            # Step 2.5: Enrich with standard portion info for UI
            std = get_standard_portions(enhanced.name, enhanced.name_en)
            if std:
                enhanced.standard_portion_g = std["standard_g"]
                enhanced.standard_portion_label = std["label"]

            # Build portion options for user slider
            cal_per_100g = (enhanced.calories / enhanced.portion_g * 100) if enhanced.portion_g > 0 else 0
            enhanced.calories_per_100g = round(cal_per_100g, 1)
            enhanced.portion_options = get_portion_options(
                enhanced.name, enhanced.name_en, cal_per_100g
            )

            enhanced_items.append(enhanced)

        # Step 2.7: Apply learned corrections from user feedback
        if user_id:
            enhanced_items = await feedback_service.apply_learned_corrections(
                user_id, enhanced_items
            )

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
            needs_portion_review=True,
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


@router.post("/recalculate-portions")
async def recalculate_portions(request: PortionUpdateRequest):
    """
    Recalculate nutrition after user adjusts portions.
    Uses DB values (per 100g) when matched_food_id exists,
    otherwise scales linearly from AI estimates.
    """
    try:
        recalculated_items: list[dict] = []

        for adj in request.items:
            if adj.matched_food_id:
                # Use DB nutrition per 100g
                food = await rag_service.get_food_by_id(adj.matched_food_id)
                if food:
                    ratio = adj.adjusted_portion_g / 100.0
                    recalculated_items.append({
                        "name": adj.name,
                        "portion_g": adj.adjusted_portion_g,
                        "calories": round(float(food["calories"]) * ratio, 1),
                        "protein_g": round(float(food.get("protein_g") or 0) * ratio, 1),
                        "carbs_g": round(float(food.get("carbs_g") or 0) * ratio, 1),
                        "fat_g": round(float(food.get("fat_g") or 0) * ratio, 1),
                        "fiber_g": round(float(food.get("fiber_g") or 0) * ratio, 1),
                        "source": "database",
                    })
                    continue

            # Fallback: no DB match, just return adjusted portion
            recalculated_items.append({
                "name": adj.name,
                "portion_g": adj.adjusted_portion_g,
                "source": "needs_manual",
            })

        total_calories = sum(i.get("calories", 0) for i in recalculated_items)

        return {
            "items": recalculated_items,
            "total_calories": round(total_calories, 1),
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Hesaplama hatası: {str(e)}")


class FeedbackSubmission(BaseModel):
    user_id: str
    scan_id: str | None = None
    corrections: list[dict]  # [{original: {...}, corrected: {...}}]


@router.post("/submit-feedback")
async def submit_feedback(submission: FeedbackSubmission):
    """
    Submit user corrections to improve future predictions.
    Called when user adjusts portions/foods and confirms the meal.
    """
    try:
        for correction in submission.corrections:
            original = correction.get("original", {})
            corrected = correction.get("corrected", {})

            if original and corrected:
                await feedback_service.save_correction(
                    user_id=submission.user_id,
                    scan_id=submission.scan_id,
                    original_item=original,
                    corrected_item=corrected,
                )

        return {"status": "ok", "corrections_saved": len(submission.corrections)}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Feedback kayıt hatası: {str(e)}")
