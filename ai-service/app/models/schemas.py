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
    plate_fraction: float | None = None  # fraction of plate covered
    depth_cm: float | None = None  # estimated depth on plate
    confidence: float = 0.8
    # Portion calibration fields
    standard_portion_g: float | None = None  # known standard portion
    standard_portion_label: str | None = None  # e.g. "1 adet", "1 porsiyon"
    portion_options: list["PortionOption"] | None = None  # suggested portions for UI slider
    calories_per_100g: float | None = None  # for user recalculation


class PortionOption(BaseModel):
    """Preset portion option for the UI portion selector."""
    label: str  # e.g. "Küçük", "Orta", "Büyük", "1 adet"
    grams: float
    calories: float


class ReferenceObject(BaseModel):
    type: str  # dinner_plate, dessert_plate, bowl, fork, etc.
    estimated_diameter_cm: float | None = None
    confidence: float = 0.5


class RawVisionResult(BaseModel):
    items: list[FoodItem]
    meal_description: str
    model_used: str
    reference_objects: list[ReferenceObject] = []


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
    # Indicates items need user portion confirmation
    needs_portion_review: bool = True


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
