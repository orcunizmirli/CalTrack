"""
OpenFoodFacts API client.
Provides lazy-load access to 4M+ food products worldwide.

Strategy: Search OFF API on-demand, cache results in our DB,
generate embeddings for cached items so they appear in future RAG searches.

API docs: https://openfoodfacts.github.io/openfoodfacts-server/api/
Rate limit: ~100 req/minute (be respectful, it's a volunteer project)
"""

import logging

import httpx
from app.config import settings

logger = logging.getLogger(__name__)

BASE_URL = "https://world.openfoodfacts.org"
USER_AGENT = "Forkcast/1.0 (forkcast.app)"


class OpenFoodFactsService:
    def __init__(self):
        self._client = httpx.AsyncClient(
            timeout=15,
            headers={"User-Agent": USER_AGENT},
        )

    async def search_by_name(
        self, query: str, page_size: int = 20, page: int = 1
    ) -> list[dict]:
        """Search OpenFoodFacts by product name."""
        try:
            response = await self._client.get(
                f"{BASE_URL}/cgi/search.pl",
                params={
                    "search_terms": query,
                    "search_simple": 1,
                    "action": "process",
                    "json": 1,
                    "page_size": page_size,
                    "page": page,
                    "fields": "code,product_name,brands,nutriments,"
                              "serving_size,serving_quantity,countries_tags,"
                              "categories_tags_en,image_front_small_url",
                },
            )
            response.raise_for_status()
            data = response.json()

            products = data.get("products", [])
            return [
                p for p in (self._parse_product(prod) for prod in products)
                if p is not None
            ]

        except Exception as e:
            logger.error(f"OpenFoodFacts search failed: {e}")
            return []

    async def get_by_barcode(self, barcode: str) -> dict | None:
        """Get product by barcode (EAN/UPC)."""
        try:
            response = await self._client.get(
                f"{BASE_URL}/api/v2/product/{barcode}.json",
                params={
                    "fields": "code,product_name,brands,nutriments,"
                              "serving_size,serving_quantity,countries_tags,"
                              "categories_tags_en,image_front_small_url",
                },
            )
            response.raise_for_status()
            data = response.json()

            if data.get("status") != 1:
                return None

            return self._parse_product(data.get("product", {}))

        except Exception as e:
            logger.error(f"OpenFoodFacts barcode lookup failed: {e}")
            return None

    async def fetch_by_country(
        self, country: str, page_size: int = 100, max_pages: int = 10
    ) -> list[dict]:
        """
        Fetch popular products from a specific country.
        country examples: "turkey", "united-states", "germany", "japan"
        """
        all_products: list[dict] = []

        for page in range(1, max_pages + 1):
            try:
                response = await self._client.get(
                    f"{BASE_URL}/cgi/search.pl",
                    params={
                        "tagtype_0": "countries",
                        "tag_contains_0": "contains",
                        "tag_0": country,
                        "sort_by": "popularity",  # renamed from unique_scans
                        "page_size": page_size,
                        "page": page,
                        "action": "process",
                        "json": 1,
                        "fields": "code,product_name,brands,nutriments,"
                                  "serving_size,serving_quantity,"
                                  "categories_tags_en",
                    },
                )
                response.raise_for_status()
                data = response.json()

                products = data.get("products", [])
                if not products:
                    break

                parsed = [
                    p for p in (self._parse_product(prod) for prod in products)
                    if p is not None
                ]
                all_products.extend(parsed)

                logger.info(
                    f"OFF {country} page {page}: "
                    f"{len(parsed)} products (total: {len(all_products)})"
                )

            except Exception as e:
                logger.error(f"OFF country fetch '{country}' page {page} failed: {e}")
                break

        return all_products

    def _parse_product(self, raw: dict) -> dict | None:
        """Parse an OpenFoodFacts product into our standard format."""
        try:
            name = raw.get("product_name", "").strip()
            if not name or len(name) < 2:
                return None

            nutriments = raw.get("nutriments", {})

            # Get calories - try multiple field names
            calories = (
                nutriments.get("energy-kcal_100g")
                or nutriments.get("energy-kcal_serving")
                or 0
            )

            if not calories or float(calories) == 0:
                return None

            # Parse serving size
            serving_g = raw.get("serving_quantity") or 100
            try:
                serving_g = float(serving_g)
            except (ValueError, TypeError):
                serving_g = 100

            brand = raw.get("brands", "").split(",")[0].strip() if raw.get("brands") else None
            barcode = raw.get("code")

            return {
                "name": name,
                "name_tr": None,
                "brand": brand,
                "barcode": barcode,
                "serving_size_g": 100,  # Normalize to per 100g
                "calories": float(calories),
                "protein_g": float(nutriments.get("proteins_100g", 0) or 0),
                "carbs_g": float(nutriments.get("carbohydrates_100g", 0) or 0),
                "fat_g": float(nutriments.get("fat_100g", 0) or 0),
                "fiber_g": float(nutriments.get("fiber_100g", 0) or 0) or None,
                "sugar_g": float(nutriments.get("sugars_100g", 0) or 0) or None,
                "saturated_fat_g": float(nutriments.get("saturated-fat_100g", 0) or 0) or None,
                "sodium_mg": float(nutriments.get("sodium_100g", 0) or 0) * 1000 if nutriments.get("sodium_100g") else None,
                "source": "openfoodfacts",
                "source_id": barcode,
                "data_type": None,
            }

        except Exception as e:
            logger.warning(f"Failed to parse OFF product: {e}")
            return None

    async def close(self):
        await self._client.aclose()
