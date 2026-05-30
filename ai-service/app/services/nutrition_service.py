"""
Lightweight nutrition lookup with in-memory cache.
Uses USDA + OpenFoodFacts APIs — no DB, no embeddings.
"""

import logging
import time
from app.models.schemas import FoodItem
from app.services.usda_service import USDAService
from app.services.openfoodfacts_service import OpenFoodFactsService

logger = logging.getLogger(__name__)

_usda = USDAService()
_off = OpenFoodFactsService()

_cache: dict[str, tuple[float, dict | None]] = {}
CACHE_TTL = 3600  # 1 hour


def _cache_get(key: str) -> dict | None:
    entry = _cache.get(key)
    if entry and (time.time() - entry[0]) < CACHE_TTL:
        return entry[1]
    return None


def _cache_set(key: str, value: dict | None):
    if len(_cache) > 5000:
        cutoff = time.time() - CACHE_TTL
        expired = [k for k, (t, _) in _cache.items() if t < cutoff]
        for k in expired:
            del _cache[k]
    _cache[key] = (time.time(), value)


async def enhance_food_item(item: FoodItem) -> FoodItem:
    query = item.name_en or item.name

    match = await _lookup_nutrition(query)
    if not match and item.name_en and item.name_en != item.name:
        match = await _lookup_nutrition(item.name)

    if not match:
        return item

    portion_ratio = item.portion_g / 100.0
    db_cal = match.get("calories", 0) * portion_ratio
    db_pro = match.get("protein_g", 0) * portion_ratio
    db_carb = match.get("carbs_g", 0) * portion_ratio
    db_fat = match.get("fat_g", 0) * portion_ratio
    db_fiber = (match.get("fiber_g") or 0) * portion_ratio

    r = 0.6
    return FoodItem(
        name=item.name,
        name_en=item.name_en,
        portion_g=item.portion_g,
        calories=round(db_cal * r + item.calories * (1 - r), 1),
        protein_g=round(db_pro * r + item.protein_g * (1 - r), 1),
        carbs_g=round(db_carb * r + item.carbs_g * (1 - r), 1),
        fat_g=round(db_fat * r + item.fat_g * (1 - r), 1),
        fiber_g=round(db_fiber * r + (item.fiber_g or 0) * (1 - r), 1),
        confidence=min(0.95, item.confidence + 0.1),
        plate_fraction=item.plate_fraction,
        depth_cm=item.depth_cm,
        standard_portion_g=item.standard_portion_g,
        standard_portion_label=item.standard_portion_label,
        portion_options=item.portion_options,
        calories_per_100g=round(match.get("calories", 0), 1),
    )


async def _lookup_nutrition(query: str) -> dict | None:
    key = query.lower().strip()
    cached = _cache_get(key)
    if cached is not None:
        return cached

    result = None

    try:
        usda_results = await _usda.search_foods(query, page_size=1)
        if usda_results:
            result = usda_results[0]
    except Exception as e:
        logger.warning(f"USDA lookup failed for '{query}': {e}")

    if not result:
        try:
            off_results = await _off.search_by_name(query, page_size=1)
            if off_results:
                result = off_results[0]
        except Exception as e:
            logger.warning(f"OFF lookup failed for '{query}': {e}")

    _cache_set(key, result)
    return result


async def search_foods(query: str, limit: int = 10) -> list[dict]:
    results: list[dict] = []
    seen_names: set[str] = set()

    try:
        usda_results = await _usda.search_foods(query, page_size=limit)
        for r in usda_results:
            key = r["name"].lower().strip()
            if key not in seen_names:
                seen_names.add(key)
                results.append(_format_search_result(r, "usda"))
    except Exception as e:
        logger.warning(f"USDA search failed: {e}")

    remaining = limit - len(results)
    if remaining > 0:
        try:
            off_results = await _off.search_by_name(query, page_size=remaining)
            for r in off_results:
                key = r["name"].lower().strip()
                if key not in seen_names:
                    seen_names.add(key)
                    results.append(_format_search_result(r, "openfoodfacts"))
        except Exception as e:
            logger.warning(f"OFF search failed: {e}")

    return results[:limit]


def _format_search_result(food: dict, source: str) -> dict:
    return {
        "name": food.get("name", ""),
        "name_tr": food.get("name_tr"),
        "brand": food.get("brand"),
        "calories_per_100g": float(food.get("calories", 0)),
        "protein_g_per_100g": float(food.get("protein_g", 0) or 0),
        "carbs_g_per_100g": float(food.get("carbs_g", 0) or 0),
        "fat_g_per_100g": float(food.get("fat_g", 0) or 0),
        "fiber_g_per_100g": float(food.get("fiber_g", 0) or 0),
        "source": source,
        "barcode": food.get("barcode"),
    }
