import json
import openai
from app.config import settings
from app.models.schemas import RecipeResponse, RecipeIngredient

SYSTEM_PROMPT = "Sen bir şef ve beslenme uzmanısın. SADECE JSON döndür."

RECIPE_PROMPT_TEMPLATE = """Hedef: {target_calories} kcal, {macro_targets}
Öğün: {meal_type}
{extras}
{num_recipes} tarif oluştur. Her tarif: başlık, açıklama, malzemeler, adımlar, süre, besin değerleri.

JSON formatı:
[{{"title":"...","description":"...","ingredients":[{{"name":"...","amount":100,"unit":"g"}}],"instructions":["..."],"prep_time_min":10,"cook_time_min":20,"servings":2,"calories":500,"protein_g":40,"carbs_g":50,"fat_g":15,"tags":["high-protein"]}}]"""


class RecipeService:
    def __init__(self):
        self.client = openai.AsyncOpenAI(api_key=settings.OPENAI_API_KEY)

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
        macro_parts = []
        if target_protein_g:
            macro_parts.append(f"P:{target_protein_g}g")
        if target_carbs_g:
            macro_parts.append(f"K:{target_carbs_g}g")
        if target_fat_g:
            macro_parts.append(f"Y:{target_fat_g}g")
        macro_targets = ", ".join(macro_parts) if macro_parts else "serbest"

        extras_parts = []
        if preferred_ingredients:
            extras_parts.append(f"Malzemeler: {', '.join(preferred_ingredients)}")
        if dietary_restrictions:
            extras_parts.append(f"Kısıtlamalar: {', '.join(dietary_restrictions)}")
        extras = "\n".join(extras_parts)

        meal_type_display = {
            "breakfast": "Kahvaltı",
            "lunch": "Öğle",
            "dinner": "Akşam",
            "snack": "Ara Öğün",
        }.get(meal_type or "", "Belirtilmedi")

        prompt = RECIPE_PROMPT_TEMPLATE.format(
            target_calories=target_calories,
            macro_targets=macro_targets,
            meal_type=meal_type_display,
            extras=extras,
            num_recipes=num_recipes,
        )

        response = await self.client.chat.completions.create(
            model=settings.RECIPE_MODEL,
            response_format={"type": "json_object"},
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": prompt},
            ],
            max_tokens=2048,
            temperature=0.7,
        )

        content = response.choices[0].message.content or "[]"

        if "```json" in content:
            content = content.split("```json")[1].split("```")[0]
        elif "```" in content:
            content = content.split("```")[1].split("```")[0]

        parsed = json.loads(content.strip())
        recipes_data = parsed if isinstance(parsed, list) else parsed.get("recipes", [])

        recipes = []
        for rd in recipes_data:
            ingredients = [RecipeIngredient(**ing) for ing in rd.get("ingredients", [])]
            recipes.append(
                RecipeResponse(
                    title=rd["title"],
                    description=rd.get("description", ""),
                    ingredients=ingredients,
                    instructions=rd.get("instructions", []),
                    prep_time_min=rd.get("prep_time_min", 0),
                    cook_time_min=rd.get("cook_time_min", 0),
                    servings=rd.get("servings", 1),
                    calories=rd.get("calories", 0),
                    protein_g=rd.get("protein_g", 0),
                    carbs_g=rd.get("carbs_g", 0),
                    fat_g=rd.get("fat_g", 0),
                    tags=rd.get("tags", []),
                )
            )

        return recipes
