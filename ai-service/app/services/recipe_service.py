import json
import anthropic
from app.config import settings
from app.models.schemas import RecipeResponse, RecipeIngredient

RECIPE_PROMPT_TEMPLATE = """Sen profesyonel bir şef ve beslenme uzmanısın. Kullanıcının ihtiyaçlarına göre sağlıklı ve lezzetli tarifler oluştur.

Gereksinimler:
- Hedef kalori: {target_calories} kcal
{macro_targets}
- Öğün tipi: {meal_type}
{ingredients_section}
{restrictions_section}
- {num_recipes} adet tarif oluştur

Her tarif için şunları sağla:
1. Başlık ve kısa açıklama
2. Detaylı malzeme listesi (miktar ve birim ile)
3. Adım adım yapılış tarifi
4. Hazırlama ve pişirme süreleri
5. Porsiyon sayısı
6. Detaylı besin değerleri (kalori, protein, karbonhidrat, yağ)
7. Etiketler (high-protein, low-carb, vegan, vb.)

SADECE geçerli JSON döndür, başka açıklama ekleme:
[
  {{
    "title": "Tarif Adı",
    "description": "Kısa açıklama",
    "ingredients": [{{"name": "Malzeme", "amount": 100, "unit": "g"}}],
    "instructions": ["Adım 1...", "Adım 2..."],
    "prep_time_min": 10,
    "cook_time_min": 20,
    "servings": 2,
    "calories": 500,
    "protein_g": 40,
    "carbs_g": 50,
    "fat_g": 15,
    "tags": ["high-protein", "quick"]
  }}
]"""


class RecipeService:
    def __init__(self):
        self.client = anthropic.AsyncAnthropic(api_key=settings.ANTHROPIC_API_KEY)

    async def generate_recipes(
        self,
        target_calories: float,
        target_protein_g: float | None = None,
        target_carbs_g: float | None = None,
        target_fat_g: float | None = None,
        preferred_ingredients: list[str] | None = None,
        dietary_restrictions: list[str] | None = None,
        meal_type: str | None = None,
        num_recipes: int = 3,
        language: str = "tr",
    ) -> list[RecipeResponse]:
        # Build macro targets section
        macro_lines = []
        if target_protein_g:
            macro_lines.append(f"- Hedef protein: {target_protein_g}g")
        if target_carbs_g:
            macro_lines.append(f"- Hedef karbonhidrat: {target_carbs_g}g")
        if target_fat_g:
            macro_lines.append(f"- Hedef yağ: {target_fat_g}g")
        macro_targets = "\n".join(macro_lines) if macro_lines else "- Makro hedefi belirtilmedi"

        # Build ingredients section
        ingredients_section = ""
        if preferred_ingredients:
            ingredients_section = f"- Tercih edilen malzemeler: {', '.join(preferred_ingredients)}"

        # Build restrictions section
        restrictions_section = ""
        if dietary_restrictions:
            restrictions_section = f"- Diyet kısıtlamaları: {', '.join(dietary_restrictions)}"

        meal_type_display = {
            "breakfast": "Kahvaltı",
            "lunch": "Öğle Yemeği",
            "dinner": "Akşam Yemeği",
            "snack": "Ara Öğün",
        }.get(meal_type or "", "Belirtilmedi")

        prompt = RECIPE_PROMPT_TEMPLATE.format(
            target_calories=target_calories,
            macro_targets=macro_targets,
            meal_type=meal_type_display,
            ingredients_section=ingredients_section,
            restrictions_section=restrictions_section,
            num_recipes=num_recipes,
        )

        response = await self.client.messages.create(
            model=settings.RECIPE_MODEL,
            max_tokens=4000,
            messages=[{"role": "user", "content": prompt}],
        )

        content = response.content[0].text if response.content else "[]"

        # Extract JSON
        if "```json" in content:
            content = content.split("```json")[1].split("```")[0]
        elif "```" in content:
            content = content.split("```")[1].split("```")[0]

        recipes_data = json.loads(content.strip())

        recipes = []
        for recipe_data in recipes_data:
            ingredients = [
                RecipeIngredient(**ing) for ing in recipe_data.get("ingredients", [])
            ]
            recipes.append(
                RecipeResponse(
                    title=recipe_data["title"],
                    description=recipe_data.get("description", ""),
                    ingredients=ingredients,
                    instructions=recipe_data.get("instructions", []),
                    prep_time_min=recipe_data.get("prep_time_min", 0),
                    cook_time_min=recipe_data.get("cook_time_min", 0),
                    servings=recipe_data.get("servings", 1),
                    calories=recipe_data.get("calories", 0),
                    protein_g=recipe_data.get("protein_g", 0),
                    carbs_g=recipe_data.get("carbs_g", 0),
                    fat_g=recipe_data.get("fat_g", 0),
                    tags=recipe_data.get("tags", []),
                )
            )

        return recipes
