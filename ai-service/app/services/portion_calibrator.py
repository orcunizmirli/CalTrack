"""
Portion Calibrator: Adjusts AI-estimated portions using reference objects
detected in the same Vision API call.

The unified prompt asks the model to:
1. Detect reference objects (plate, fork, glass, etc.)
2. Estimate plate_fraction and depth_cm for each food item
3. Provide portion estimates informed by these references

This calibrator provides a secondary validation layer:
- Uses plate area × food coverage × depth × density to compute an independent
  weight estimate, then blends it with the model's gram estimate.

No extra API calls required — all data comes from the single Vision response.
"""

import logging
from app.models.schemas import FoodItem, ReferenceObject

logger = logging.getLogger(__name__)

# Known plate areas
PLATE_AREAS: dict[str, float] = {
    "dinner_plate": 530.0,   # π × 13² cm²
    "dessert_plate": 314.0,  # π × 10² cm²
    "bowl": 201.0,           # π × 8² cm²
}

# Approximate food density (g/cm³)
FOOD_DENSITY: dict[str, float] = {
    "rice": 1.1, "pilav": 1.1, "pirinç": 1.1,
    "pasta": 0.9, "makarna": 0.9,
    "meat": 1.05, "et": 1.05, "kebap": 1.0, "kebab": 1.0,
    "köfte": 1.0, "tavuk": 1.0, "chicken": 1.0,
    "salad": 0.4, "salata": 0.4,
    "soup": 1.0, "çorba": 1.0,
    "bread": 0.35, "ekmek": 0.35, "lavaş": 0.3, "simit": 0.35,
    "vegetables": 0.6, "sebze": 0.6,
    "börek": 0.55, "pide": 0.5, "lahmacun": 0.45,
    "dessert": 0.7, "tatlı": 0.7, "baklava": 0.8,
}


def _get_density(food_name: str) -> float:
    name_lower = food_name.lower()
    for key, density in FOOD_DENSITY.items():
        if key in name_lower:
            return density
    return 0.8  # default


def calibrate_portions(
    items: list[FoodItem],
    reference_objects: list[ReferenceObject],
) -> list[FoodItem]:
    """
    Validate and optionally adjust portion estimates using reference object data.

    Only adjusts if:
    - A plate-type reference was detected with decent confidence
    - The item has plate_fraction and depth_cm data
    - The calculated weight differs significantly from the AI estimate
    """
    if not reference_objects:
        return items

    # Find best plate reference
    plate_ref = None
    for ref in reference_objects:
        if ref.type in PLATE_AREAS and ref.confidence >= 0.6:
            if plate_ref is None or ref.confidence > plate_ref.confidence:
                plate_ref = ref

    if not plate_ref:
        return items

    plate_area = PLATE_AREAS[plate_ref.type]

    calibrated: list[FoodItem] = []
    for item in items:
        if item.plate_fraction and item.depth_cm:
            density = _get_density(item.name)
            volume_cm3 = plate_area * item.plate_fraction * item.depth_cm
            calculated_g = volume_cm3 * density

            # Only adjust if there's a significant discrepancy (>30%)
            ratio = calculated_g / item.portion_g if item.portion_g > 0 else 1.0

            if abs(ratio - 1.0) > 0.3:
                # Blend: 50% AI estimate, 50% calculated — trust both equally
                blended_g = item.portion_g * 0.5 + calculated_g * 0.5

                # Safety: don't deviate more than 2x from AI
                blended_g = max(item.portion_g * 0.4, min(item.portion_g * 2.0, blended_g))

                scale = blended_g / item.portion_g if item.portion_g > 0 else 1.0

                logger.info(
                    f"Calibrated '{item.name}': {item.portion_g}g -> {round(blended_g)}g "
                    f"(calc={round(calculated_g)}g, fraction={item.plate_fraction}, "
                    f"depth={item.depth_cm}cm, density={density})"
                )

                calibrated.append(item.model_copy(update={
                    "portion_g": round(blended_g, 1),
                    "calories": round(item.calories * scale, 1),
                    "protein_g": round(item.protein_g * scale, 1),
                    "carbs_g": round(item.carbs_g * scale, 1),
                    "fat_g": round(item.fat_g * scale, 1),
                    "fiber_g": round((item.fiber_g or 0) * scale, 1),
                }))
            else:
                calibrated.append(item)
        else:
            calibrated.append(item)

    return calibrated
