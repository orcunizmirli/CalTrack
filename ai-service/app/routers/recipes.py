from fastapi import APIRouter, HTTPException
from app.services.recipe_service import RecipeService
from app.models.schemas import RecipeRequest, RecipeResponse

router = APIRouter()
recipe_service = RecipeService()


@router.post("/generate-recipes", response_model=list[RecipeResponse])
async def generate_recipes(request: RecipeRequest):
    """
    Generate AI-powered recipe suggestions based on:
    - Target calories and macros
    - Preferred ingredients
    - Dietary restrictions
    - Meal type
    """
    try:
        recipes = await recipe_service.generate_recipes(
            target_calories=request.target_calories,
            target_protein_g=request.target_protein_g,
            target_carbs_g=request.target_carbs_g,
            target_fat_g=request.target_fat_g,
            preferred_ingredients=request.preferred_ingredients,
            dietary_restrictions=request.dietary_restrictions,
            meal_type=request.meal_type,
            num_recipes=request.num_recipes or 3,
            language=request.language or "tr",
        )
        return recipes
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Tarif oluşturma hatası: {str(e)}")
