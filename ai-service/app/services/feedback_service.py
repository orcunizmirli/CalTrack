"""
User Feedback Loop Service

Stores user corrections to AI food analysis results and uses them
to improve future predictions for the same user.

Feedback types:
1. Portion correction: user adjusted the portion size
2. Food correction: user changed the food identification
3. Nutrition correction: user manually edited macros

Learning mechanism:
- Store corrections in DB
- For returning users, check if they've corrected the same food before
- Apply personal correction factor to future predictions
- Aggregate corrections across users for global calibration
"""

import logging
from datetime import datetime

from app.db import get_pool
from app.models.schemas import FoodItem

logger = logging.getLogger(__name__)


class FeedbackService:

    async def save_correction(
        self,
        user_id: str,
        scan_id: str | None,
        original_item: dict,
        corrected_item: dict,
    ) -> None:
        """Save a user's correction to a food analysis result."""
        try:
            pool = await get_pool()
            async with pool.acquire() as conn:
                await conn.execute(
                    """
                    INSERT INTO user_food_corrections
                        (user_id, scan_id, food_name, food_name_en,
                         original_portion_g, corrected_portion_g,
                         original_calories, corrected_calories,
                         original_protein_g, corrected_protein_g,
                         original_carbs_g, corrected_carbs_g,
                         original_fat_g, corrected_fat_g,
                         correction_type, created_at)
                    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10,
                            $11, $12, $13, $14, $15, NOW())
                    """,
                    user_id,
                    scan_id,
                    original_item.get("name", ""),
                    original_item.get("name_en"),
                    original_item.get("portion_g", 0),
                    corrected_item.get("portion_g", 0),
                    original_item.get("calories", 0),
                    corrected_item.get("calories", 0),
                    original_item.get("protein_g", 0),
                    corrected_item.get("protein_g", 0),
                    original_item.get("carbs_g", 0),
                    corrected_item.get("carbs_g", 0),
                    original_item.get("fat_g", 0),
                    corrected_item.get("fat_g", 0),
                    _determine_correction_type(original_item, corrected_item),
                )

            logger.info(
                f"Saved correction for user {user_id}: "
                f"'{original_item.get('name')}' {original_item.get('portion_g')}g "
                f"-> {corrected_item.get('portion_g')}g"
            )
        except Exception as e:
            logger.error(f"Failed to save correction: {e}")

    async def get_user_correction_factor(
        self, user_id: str, food_name: str
    ) -> float | None:
        """
        Get the user's average correction factor for a specific food.
        Returns a multiplier (e.g., 0.8 means user typically reduces AI estimate by 20%).
        Returns None if no corrections found.
        """
        try:
            pool = await get_pool()
            async with pool.acquire() as conn:
                row = await conn.fetchrow(
                    """
                    SELECT
                        AVG(corrected_portion_g / NULLIF(original_portion_g, 0)) as avg_factor,
                        COUNT(*) as correction_count
                    FROM user_food_corrections
                    WHERE user_id = $1
                      AND LOWER(food_name) = LOWER($2)
                      AND original_portion_g > 0
                      AND corrected_portion_g > 0
                    """,
                    user_id,
                    food_name,
                )

                if row and row["correction_count"] >= 2:
                    factor = float(row["avg_factor"])
                    logger.info(
                        f"User {user_id} correction factor for '{food_name}': "
                        f"{factor:.2f} (based on {row['correction_count']} corrections)"
                    )
                    return factor

                return None
        except Exception as e:
            logger.error(f"Failed to get correction factor: {e}")
            return None

    async def get_global_correction_factor(self, food_name: str) -> float | None:
        """
        Get the global average correction factor across all users for a food.
        Requires at least 5 corrections for statistical significance.
        """
        try:
            pool = await get_pool()
            async with pool.acquire() as conn:
                row = await conn.fetchrow(
                    """
                    SELECT
                        AVG(corrected_portion_g / NULLIF(original_portion_g, 0)) as avg_factor,
                        COUNT(*) as correction_count
                    FROM user_food_corrections
                    WHERE LOWER(food_name) = LOWER($1)
                      AND original_portion_g > 0
                      AND corrected_portion_g > 0
                    """,
                    food_name,
                )

                if row and row["correction_count"] >= 5:
                    return float(row["avg_factor"])

                return None
        except Exception as e:
            logger.error(f"Failed to get global correction factor: {e}")
            return None

    async def apply_learned_corrections(
        self, user_id: str, items: list[FoodItem]
    ) -> list[FoodItem]:
        """
        Apply learned corrections to food items before returning to user.
        Priority: user-specific > global > no adjustment.
        """
        corrected: list[FoodItem] = []

        for item in items:
            factor = await self.get_user_correction_factor(user_id, item.name)

            if factor is None:
                factor = await self.get_global_correction_factor(item.name)

            if factor is not None and abs(factor - 1.0) > 0.05:
                # Apply correction factor (cap at 0.3x - 3.0x for safety)
                factor = max(0.3, min(3.0, factor))

                corrected.append(FoodItem(
                    name=item.name,
                    name_en=item.name_en,
                    portion_g=round(item.portion_g * factor, 1),
                    calories=round(item.calories * factor, 1),
                    protein_g=round(item.protein_g * factor, 1),
                    carbs_g=round(item.carbs_g * factor, 1),
                    fat_g=round(item.fat_g * factor, 1),
                    fiber_g=round((item.fiber_g or 0) * factor, 1),
                    confidence=item.confidence,
                    matched_food_id=item.matched_food_id,
                    standard_portion_g=item.standard_portion_g,
                    standard_portion_label=item.standard_portion_label,
                    portion_options=item.portion_options,
                    calories_per_100g=item.calories_per_100g,
                ))
            else:
                corrected.append(item)

        return corrected


def _determine_correction_type(original: dict, corrected: dict) -> str:
    """Determine what type of correction the user made."""
    if original.get("name") != corrected.get("name"):
        return "food_identity"
    if abs(original.get("portion_g", 0) - corrected.get("portion_g", 0)) > 5:
        return "portion"
    return "nutrition"
