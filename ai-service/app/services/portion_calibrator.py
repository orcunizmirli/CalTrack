"""
Portion Calibrator: Adjusts AI-estimated portions using reference objects
detected in the food photo.

The Vision model is asked to detect reference objects (plate, fork, spoon,
glass, hand) and report their apparent sizes. We use known real-world sizes
of these objects to compute a scale factor, then apply it to portion estimates.

Reference Object Dimensions (real-world):
- Standard dinner plate: 26cm diameter
- Small/dessert plate: 20cm diameter
- Turkish tea glass (ince belli): 6.5cm height, ~100ml
- Water glass: 8cm diameter
- Standard fork: 19cm length
- Standard spoon: 18cm length
- Adult hand width (palm): ~8.5cm
"""

import json
import logging

import openai
from app.config import settings
from app.models.schemas import FoodItem

logger = logging.getLogger(__name__)

REFERENCE_DETECTION_PROMPT = """Analyze this food photo for reference objects that can help estimate portion sizes.

Look for these objects and estimate their APPARENT size in the image:
1. Plate - type (dinner/dessert/bowl) and approximate diameter visible
2. Fork/Knife/Spoon - if visible
3. Glass/Cup - type and approximate size
4. Hand - if visible
5. Any standard packaging with known size

For each food item on the plate, estimate what FRACTION of the plate surface it covers.

Return ONLY valid JSON:
{
  "reference_objects": [
    {
      "type": "dinner_plate",
      "estimated_diameter_cm": 26,
      "confidence": 0.9
    }
  ],
  "food_coverage": [
    {
      "food_name": "pilav",
      "plate_fraction": 0.3,
      "estimated_depth_cm": 2.0
    }
  ],
  "scale_factor": 1.0,
  "notes": "Standard dinner plate detected, portions appear normal sized"
}"""

# Known dimensions for scale calculation
REFERENCE_DIMENSIONS = {
    "dinner_plate": {"diameter_cm": 26, "area_cm2": 530},
    "dessert_plate": {"diameter_cm": 20, "area_cm2": 314},
    "bowl": {"diameter_cm": 16, "area_cm2": 201},
    "fork": {"length_cm": 19},
    "knife": {"length_cm": 22},
    "spoon": {"length_cm": 18},
    "tea_glass": {"height_cm": 6.5, "volume_ml": 100},
    "water_glass": {"diameter_cm": 8, "volume_ml": 250},
    "hand": {"width_cm": 8.5},
}

# Approximate density of common food categories (g/cm3)
FOOD_DENSITY = {
    "rice": 1.1,
    "pilav": 1.1,
    "pasta": 0.9,
    "makarna": 0.9,
    "meat": 1.05,
    "et": 1.05,
    "kebap": 1.0,
    "köfte": 1.0,
    "salad": 0.4,
    "salata": 0.4,
    "soup": 1.0,
    "çorba": 1.0,
    "bread": 0.35,
    "ekmek": 0.35,
    "vegetables": 0.6,
    "sebze": 0.6,
    "default": 0.8,
}


def _get_density(food_name: str) -> float:
    """Get approximate density for a food item."""
    name_lower = food_name.lower()
    for key, density in FOOD_DENSITY.items():
        if key in name_lower:
            return density
    return FOOD_DENSITY["default"]


class PortionCalibrator:
    def __init__(self):
        self._client = openai.AsyncOpenAI(api_key=settings.OPENAI_API_KEY)

    async def detect_references(self, image_data: bytes) -> dict | None:
        """Detect reference objects in the food photo."""
        try:
            import base64
            b64 = base64.b64encode(image_data).decode("utf-8")

            response = await self._client.chat.completions.create(
                model=settings.PRIMARY_VISION_MODEL,
                messages=[
                    {
                        "role": "user",
                        "content": [
                            {"type": "text", "text": REFERENCE_DETECTION_PROMPT},
                            {
                                "type": "image_url",
                                "image_url": {
                                    "url": f"data:image/jpeg;base64,{b64}",
                                    "detail": "high",
                                },
                            },
                        ],
                    }
                ],
                max_tokens=1000,
                temperature=0.1,
            )

            content = response.choices[0].message.content or ""
            if "```json" in content:
                content = content.split("```json")[1].split("```")[0]
            elif "```" in content:
                content = content.split("```")[1].split("```")[0]

            return json.loads(content.strip())

        except Exception as e:
            logger.warning(f"Reference object detection failed: {e}")
            return None

    def calibrate_portions(
        self, items: list[FoodItem], ref_data: dict
    ) -> list[FoodItem]:
        """
        Adjust portion estimates using detected reference objects.

        Strategy:
        1. Compute scale factor from reference objects
        2. Use food_coverage fractions to estimate volume
        3. Apply density to convert volume -> weight
        4. Blend calibrated weight with AI estimate
        """
        if not ref_data:
            return items

        ref_objects = ref_data.get("reference_objects", [])
        food_coverage = ref_data.get("food_coverage", [])

        if not ref_objects:
            return items

        # Find best reference object (highest confidence)
        best_ref = max(ref_objects, key=lambda r: r.get("confidence", 0))
        ref_type = best_ref.get("type", "")
        ref_known = REFERENCE_DIMENSIONS.get(ref_type)

        if not ref_known or "area_cm2" not in ref_known:
            # Only plate references give us area-based calibration
            return items

        plate_area = ref_known["area_cm2"]

        # Build coverage lookup
        coverage_map: dict[str, dict] = {}
        for fc in food_coverage:
            name = fc.get("food_name", "").lower()
            coverage_map[name] = fc

        calibrated: list[FoodItem] = []
        for item in items:
            name_lower = item.name.lower()

            # Find matching coverage data
            matched_coverage = None
            for cov_name, cov_data in coverage_map.items():
                if cov_name in name_lower or name_lower in cov_name:
                    matched_coverage = cov_data
                    break

            if matched_coverage:
                fraction = matched_coverage.get("plate_fraction", 0)
                depth_cm = matched_coverage.get("estimated_depth_cm", 1.5)
                density = _get_density(item.name)

                # Volume = plate_area * fraction * depth
                volume_cm3 = plate_area * fraction * depth_cm
                calibrated_g = volume_cm3 * density

                # Blend: 60% calibrated, 40% AI estimate
                blended_g = calibrated_g * 0.6 + item.portion_g * 0.4

                # Sanity check: don't deviate more than 2x from AI estimate
                if blended_g > item.portion_g * 2:
                    blended_g = item.portion_g * 1.5
                elif blended_g < item.portion_g * 0.3:
                    blended_g = item.portion_g * 0.5

                portion_ratio = blended_g / item.portion_g if item.portion_g > 0 else 1.0

                calibrated.append(FoodItem(
                    name=item.name,
                    name_en=item.name_en,
                    portion_g=round(blended_g, 1),
                    calories=round(item.calories * portion_ratio, 1),
                    protein_g=round(item.protein_g * portion_ratio, 1),
                    carbs_g=round(item.carbs_g * portion_ratio, 1),
                    fat_g=round(item.fat_g * portion_ratio, 1),
                    fiber_g=round((item.fiber_g or 0) * portion_ratio, 1),
                    confidence=item.confidence,
                    matched_food_id=item.matched_food_id,
                    standard_portion_g=item.standard_portion_g,
                    standard_portion_label=item.standard_portion_label,
                    portion_options=item.portion_options,
                    calories_per_100g=item.calories_per_100g,
                ))

                logger.info(
                    f"Calibrated '{item.name}': {item.portion_g}g -> {round(blended_g, 1)}g "
                    f"(plate fraction={fraction}, depth={depth_cm}cm)"
                )
            else:
                calibrated.append(item)

        return calibrated
