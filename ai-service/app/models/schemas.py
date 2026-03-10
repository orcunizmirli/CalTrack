from pydantic import BaseModel


class FoodItem(BaseModel):
    name: str
    name_en: str | None = None
    portion_g: float
    calories: float
    protein_g: float
    carbs_g: float
    fat_g: float
    fiber_g: float | None = None
    confidence: float = 0.8
    matched_food_id: str | None = None  # DB match from RAG


class RawVisionResult(BaseModel):
    items: list[FoodItem]
    meal_description: str
    model_used: str


class FoodAnalysisResponse(BaseModel):
    items: list[FoodItem]
    total_calories: float
    total_protein_g: float
    total_carbs_g: float
    total_fat_g: float
    meal_description: str
    confidence: float
    model_used: str
    processing_ms: int


class RecipeRequest(BaseModel):
    target_calories: float
    target_protein_g: float | None = None
    target_carbs_g: float | None = None
    target_fat_g: float | None = None
    preferred_ingredients: list[str] = []
    dietary_restrictions: list[str] = []
    meal_type: str | None = None  # breakfast, lunch, dinner, snack
    num_recipes: int | None = 3
    language: str | None = "tr"


class RecipeIngredient(BaseModel):
    name: str
    amount: float
    unit: str


class RecipeResponse(BaseModel):
    title: str
    description: str
    ingredients: list[RecipeIngredient]
    instructions: list[str]
    prep_time_min: int
    cook_time_min: int
    servings: int
    calories: float
    protein_g: float
    carbs_g: float
    fat_g: float
    tags: list[str] = []
