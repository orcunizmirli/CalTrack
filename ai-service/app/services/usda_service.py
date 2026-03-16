"""
USDA FoodData Central API client.
Fetches Foundation Foods and SR Legacy data for our food database.

API docs: https://fdc.nal.usda.gov/api-guide/
Rate limit: 1000 req/hour with API key, 30 req/hour with DEMO_KEY
"""

import logging
from typing import Any

import httpx
from app.config import settings

logger = logging.getLogger(__name__)

BASE_URL = "https://api.nal.usda.gov/fdc/v1"

# Nutrient IDs we care about (USDA nutrient number -> our field)
NUTRIENT_MAP = {
    1008: "calories",       # Energy (kcal)
    1003: "protein_g",      # Protein
    1005: "carbs_g",        # Carbohydrate, by difference
    1004: "fat_g",          # Total lipid (fat)
    1079: "fiber_g",        # Fiber, total dietary
    2000: "sugar_g",        # Sugars, total
    1258: "saturated_fat_g",# Fatty acids, total saturated
    1093: "sodium_mg",      # Sodium
}


class USDAService:
    def __init__(self):
        self._api_key = settings.USDA_API_KEY or "DEMO_KEY"
        self._client = httpx.AsyncClient(timeout=30)

    async def search_foods(
        self,
        query: str,
        data_types: list[str] | None = None,
        page_size: int = 25,
        page: int = 1,
    ) -> list[dict]:
        """Search USDA FoodData Central."""
        if data_types is None:
            data_types = ["Foundation", "SR Legacy"]

        try:
            response = await self._client.post(
                f"{BASE_URL}/foods/search",
                params={"api_key": self._api_key},
                json={
                    "query": query,
                    "dataType": data_types,
                    "pageSize": page_size,
                    "pageNumber": page,
                    "sortBy": "dataType.keyword",
                    "sortOrder": "asc",
                },
            )
            response.raise_for_status()
            data = response.json()
            return [self._parse_food(f) for f in data.get("foods", [])]

        except Exception as e:
            logger.error(f"USDA search failed: {e}")
            return []

    async def get_food_details(self, fdc_id: int) -> dict | None:
        """Get detailed nutrition for a specific food by FDC ID."""
        try:
            response = await self._client.get(
                f"{BASE_URL}/food/{fdc_id}",
                params={"api_key": self._api_key},
            )
            response.raise_for_status()
            return self._parse_food(response.json())

        except Exception as e:
            logger.error(f"USDA food detail failed for {fdc_id}: {e}")
            return None

    async def fetch_foundation_foods(
        self, page_size: int = 200, max_pages: int = 50
    ) -> list[dict]:
        """
        Fetch all Foundation Foods from USDA.
        Foundation Foods are ~7500 basic ingredients with high-quality data.
        """
        all_foods: list[dict] = []

        for page in range(1, max_pages + 1):
            try:
                response = await self._client.post(
                    f"{BASE_URL}/foods/search",
                    params={"api_key": self._api_key},
                    json={
                        "query": "",
                        "dataType": ["Foundation", "SR Legacy"],
                        "pageSize": page_size,
                        "pageNumber": page,
                    },
                )
                response.raise_for_status()
                data = response.json()
                foods = data.get("foods", [])

                if not foods:
                    break

                parsed = [self._parse_food(f) for f in foods]
                all_foods.extend([f for f in parsed if f is not None])

                total_pages = data.get("totalPages", 0)
                logger.info(
                    f"USDA fetch page {page}/{total_pages}: "
                    f"got {len(foods)} foods (total: {len(all_foods)})"
                )

                if page >= total_pages:
                    break

            except Exception as e:
                logger.error(f"USDA fetch page {page} failed: {e}")
                break

        return all_foods

    async def fetch_branded_popular(
        self, categories: list[str], page_size: int = 200
    ) -> list[dict]:
        """
        Fetch popular branded foods by category.
        Categories like: "Snacks", "Beverages", "Dairy", "Cereals", etc.
        """
        all_foods: list[dict] = []

        for category in categories:
            try:
                response = await self._client.post(
                    f"{BASE_URL}/foods/search",
                    params={"api_key": self._api_key},
                    json={
                        "query": category,
                        "dataType": ["Branded"],
                        "pageSize": page_size,
                        "pageNumber": 1,
                    },
                )
                response.raise_for_status()
                data = response.json()
                foods = data.get("foods", [])
                parsed = [self._parse_food(f) for f in foods]
                all_foods.extend([f for f in parsed if f is not None])

                logger.info(f"USDA branded '{category}': {len(foods)} foods")

            except Exception as e:
                logger.error(f"USDA branded fetch '{category}' failed: {e}")

        return all_foods

    def _parse_food(self, raw: dict) -> dict | None:
        """Parse a USDA food item into our standard format."""
        try:
            name = raw.get("description", "").strip()
            if not name:
                return None

            brand = raw.get("brandOwner") or raw.get("brandName")

            # Extract nutrients
            nutrients: dict[str, float] = {}
            for nutrient in raw.get("foodNutrients", []):
                # Search result format
                nutrient_id = nutrient.get("nutrientId") or nutrient.get(
                    "nutrient", {}
                ).get("id")
                if nutrient_id in NUTRIENT_MAP:
                    value = nutrient.get("value") or nutrient.get("amount") or 0
                    nutrients[NUTRIENT_MAP[nutrient_id]] = float(value)

            # Skip foods with no calorie data
            if "calories" not in nutrients or nutrients["calories"] == 0:
                return None

            return {
                "name": name,
                "name_tr": None,
                "brand": brand,
                "barcode": raw.get("gtinUpc"),
                "serving_size_g": 100,  # USDA data is per 100g
                "calories": nutrients.get("calories", 0),
                "protein_g": nutrients.get("protein_g", 0),
                "carbs_g": nutrients.get("carbs_g", 0),
                "fat_g": nutrients.get("fat_g", 0),
                "fiber_g": nutrients.get("fiber_g"),
                "sugar_g": nutrients.get("sugar_g"),
                "saturated_fat_g": nutrients.get("saturated_fat_g"),
                "sodium_mg": nutrients.get("sodium_mg"),
                "source": "usda",
                "source_id": str(raw.get("fdcId", "")),
                "data_type": raw.get("dataType"),
            }

        except Exception as e:
            logger.warning(f"Failed to parse USDA food: {e}")
            return None

    async def close(self):
        await self._client.aclose()
