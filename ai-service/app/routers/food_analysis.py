import logging
import time
from fastapi import APIRouter, UploadFile, File, HTTPException, Query
from app.services.vision_service import VisionService
from app.services import nutrition_service
from app.models.schemas import FoodAnalysisResponse, FoodItem
from app.services.portion_standards import get_standard_portions, get_portion_options
from app.services.portion_calibrator import calibrate_portions

logger = logging.getLogger(__name__)

router = APIRouter()
vision_service = VisionService()


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
    1. AI Vision analysis (GPT-5.2 primary, Claude fallback)
    2. Portion calibration using detected reference objects
    3. Nutrition enhancement via USDA/OpenFoodFacts APIs
    4. Standard portion enrichment for UI
    """
    start_time = time.time()

    if not image.content_type or not image.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Geçersiz dosya formatı. Lütfen bir resim yükleyin.")

    image_data = await image.read()
    max_size = 10 * 1024 * 1024
    if len(image_data) > max_size:
        raise HTTPException(status_code=400, detail="Resim boyutu 10MB'dan büyük olamaz.")

    try:
        raw_result = await vision_service.analyze_food_image(
            image_data=image_data,
            meal_type=meal_type,
            additional_context=additional_context,
        )

        calibrated_items = calibrate_portions(
            raw_result.items, raw_result.reference_objects
        )

        enhanced_items: list[FoodItem] = []
        for item in calibrated_items:
            enhanced = await nutrition_service.enhance_food_item(item)

            std = get_standard_portions(enhanced.name, enhanced.name_en)
            if std:
                enhanced.standard_portion_g = std["standard_g"]
                enhanced.standard_portion_label = std["label"]

            cal_per_100g = (enhanced.calories / enhanced.portion_g * 100) if enhanced.portion_g > 0 else 0
            if not enhanced.calories_per_100g:
                enhanced.calories_per_100g = round(cal_per_100g, 1)
            enhanced.portion_options = get_portion_options(
                enhanced.name, enhanced.name_en, enhanced.calories_per_100g or cal_per_100g
            )

            enhanced_items.append(enhanced)

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
    limit: int = Query(10, ge=1, le=50),
):
    """
    Search foods by name using USDA + OpenFoodFacts APIs.
    """
    try:
        results = await nutrition_service.search_foods(q, limit=limit)
        return {"query": q, "results": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Arama hatası: {str(e)}")


@router.get("/barcode/{barcode}")
async def lookup_barcode(barcode: str):
    """Look up a food product by barcode using OpenFoodFacts."""
    from app.services.openfoodfacts_service import OpenFoodFactsService
    off = OpenFoodFactsService()
    try:
        result = await off.get_by_barcode(barcode)
        if not result:
            raise HTTPException(status_code=404, detail="Ürün bulunamadı.")
        return result
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Barkod arama hatası: {str(e)}")
