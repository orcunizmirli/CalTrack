import base64
import json
import openai
import anthropic
from app.config import settings
from app.models.schemas import RawVisionResult, ReferenceObject, FoodItem

SYSTEM_PROMPT = "You are a nutrition expert. Analyze food photos. Return ONLY JSON."

FOOD_ANALYSIS_PROMPT = """Analyze this food photo. For each food item provide Turkish name, English name, portion (g), calories, macros.
Detect reference objects (plate, fork, glass) to calibrate portions.
For Turkish dishes with oil/sauce, include those calories. Estimate each item separately.

Return JSON:
{"reference_objects":[{"type":"dinner_plate","estimated_diameter_cm":26,"confidence":0.9}],"items":[{"name":"Adana Kebap","name_en":"Adana Kebab","portion_g":200,"plate_fraction":0.35,"depth_cm":2.5,"calories":460,"protein_g":34,"carbs_g":4,"fat_g":35,"fiber_g":1,"confidence":0.9}],"meal_description":"kısa açıklama"}"""


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
        prompt = FOOD_ANALYSIS_PROMPT
        if meal_type:
            prompt += f"\nMeal: {meal_type}"
        if additional_context:
            prompt += f"\nContext: {additional_context}"

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
            response_format={"type": "json_object"},
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": prompt},
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{base64_image}",
                                "detail": "auto",
                            },
                        },
                    ],
                },
            ],
            max_tokens=1024,
            temperature=0.1,
        )

        content = response.choices[0].message.content or "{}"
        return self._parse_response(content, settings.PRIMARY_VISION_MODEL)

    async def _analyze_with_anthropic(
        self, image_data: bytes, prompt: str
    ) -> RawVisionResult:
        base64_image = base64.b64encode(image_data).decode("utf-8")

        response = await self.anthropic_client.messages.create(
            model=settings.FALLBACK_VISION_MODEL,
            max_tokens=1024,
            system=SYSTEM_PROMPT,
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
                },
            ],
        )

        content = response.content[0].text if response.content else "{}"
        return self._parse_response(content, settings.FALLBACK_VISION_MODEL)

    def _parse_response(self, content: str, model: str) -> RawVisionResult:
        if "```json" in content:
            content = content.split("```json")[1].split("```")[0]
        elif "```" in content:
            content = content.split("```")[1].split("```")[0]

        data = json.loads(content.strip())
        items = [FoodItem(**item) for item in data.get("items", [])]
        ref_objects = [
            ReferenceObject(**ref)
            for ref in data.get("reference_objects", [])
        ]

        return RawVisionResult(
            items=items,
            meal_description=data.get("meal_description", ""),
            model_used=model,
            reference_objects=ref_objects,
        )
