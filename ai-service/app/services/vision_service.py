import base64
import json
import openai
import anthropic
from app.config import settings
from app.models.schemas import RawVisionResult, FoodItem

FOOD_ANALYSIS_PROMPT = """You are a nutrition expert AI. Analyze the food in this photo carefully.

For each distinct food item visible:
1. Identify the food item (use Turkish name primarily, with English name)
2. Estimate the portion size in grams
3. Calculate calories and macronutrients

Be as accurate as possible with portion estimation. Consider plate size, utensils, and other visual cues.

Return ONLY valid JSON in this exact format:
{
  "items": [
    {
      "name": "Izgara Tavuk Göğsü",
      "name_en": "Grilled Chicken Breast",
      "portion_g": 150,
      "calories": 248,
      "protein_g": 46.5,
      "carbs_g": 0,
      "fat_g": 5.4,
      "fiber_g": 0,
      "confidence": 0.92
    }
  ],
  "meal_description": "Izgara tavuk göğsü yanında pilav ve salata"
}"""


class VisionService:
    def __init__(self):
        self.openai_client = openai.AsyncOpenAI(api_key=settings.OPENAI_API_KEY)
        self.anthropic_client = anthropic.AsyncAnthropic(api_key=settings.ANTHROPIC_API_KEY)

    async def analyze_food_image(
        self,
        image_data: bytes,
        meal_type: str | None = None,
        additional_context: str | None = None,
    ) -> RawVisionResult:
        """Analyze food image using primary model, fall back to secondary."""
        prompt = FOOD_ANALYSIS_PROMPT
        if meal_type:
            prompt += f"\n\nMeal type: {meal_type}"
        if additional_context:
            prompt += f"\n\nAdditional context: {additional_context}"

        try:
            return await self._analyze_with_openai(image_data, prompt)
        except Exception:
            return await self._analyze_with_anthropic(image_data, prompt)

    async def _analyze_with_openai(
        self, image_data: bytes, prompt: str
    ) -> RawVisionResult:
        base64_image = base64.b64encode(image_data).decode("utf-8")

        response = await self.openai_client.chat.completions.create(
            model=settings.PRIMARY_VISION_MODEL,
            messages=[
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": prompt},
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{base64_image}",
                                "detail": "high",
                            },
                        },
                    ],
                }
            ],
            max_tokens=2000,
            temperature=0.1,
        )

        content = response.choices[0].message.content or ""
        return self._parse_response(content, settings.PRIMARY_VISION_MODEL)

    async def _analyze_with_anthropic(
        self, image_data: bytes, prompt: str
    ) -> RawVisionResult:
        base64_image = base64.b64encode(image_data).decode("utf-8")

        response = await self.anthropic_client.messages.create(
            model=settings.FALLBACK_VISION_MODEL,
            max_tokens=2000,
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": base64_image,
                            },
                        },
                        {"type": "text", "text": prompt},
                    ],
                }
            ],
        )

        content = response.content[0].text if response.content else ""
        return self._parse_response(content, settings.FALLBACK_VISION_MODEL)

    def _parse_response(self, content: str, model: str) -> RawVisionResult:
        # Extract JSON from potential markdown code blocks
        if "```json" in content:
            content = content.split("```json")[1].split("```")[0]
        elif "```" in content:
            content = content.split("```")[1].split("```")[0]

        data = json.loads(content.strip())
        items = [FoodItem(**item) for item in data.get("items", [])]

        return RawVisionResult(
            items=items,
            meal_description=data.get("meal_description", ""),
            model_used=model,
        )
