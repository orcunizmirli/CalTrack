import logging
import openai
from app.config import settings
from app.db import get_pool
from app.models.schemas import FoodItem

logger = logging.getLogger(__name__)

# Similarity threshold: above this we trust DB values
HIGH_CONFIDENCE_THRESHOLD = 0.88
# Above this we blend AI + DB values
MEDIUM_CONFIDENCE_THRESHOLD = 0.75


class RAGService:
    """
    Retrieval-Augmented Generation service for enhancing AI food analysis
    with data from our food database using pgvector similarity search.

    Pipeline:
    1. AI detects food items from photo (name + estimated nutrition)
    2. For each item, generate embedding from food name
    3. Search pgvector for semantically similar foods in our DB
    4. If high-confidence match: use DB nutrition per 100g, scale by AI portion
    5. If medium-confidence match: blend AI + DB values
    6. If no match: keep AI-estimated values as-is
    """

    def __init__(self):
        self._openai_client = openai.AsyncOpenAI(api_key=settings.OPENAI_API_KEY)
        self._embedding_cache: dict[str, list[float]] = {}

    async def enhance_food_item(self, item: FoodItem) -> FoodItem:
        """Enhance an AI-detected food item with database nutrition data."""
        try:
            # Build search text from both names
            search_text = item.name
            if item.name_en:
                search_text = f"{item.name} {item.name_en}"

            # Generate embedding
            embedding = await self._get_embedding(search_text)
            if not embedding:
                return item

            # Search for similar foods
            matches = await self._search_similar_foods(embedding, top_k=3)
            if not matches:
                return item

            best_match = matches[0]
            similarity = 1 - best_match["distance"]  # cosine distance to similarity

            logger.info(
                f"RAG match for '{item.name}': '{best_match['food_name_tr'] or best_match['food_name']}' "
                f"(similarity: {similarity:.3f})"
            )

            if similarity >= HIGH_CONFIDENCE_THRESHOLD:
                # High confidence: use DB nutrition, scale by AI portion
                return self._apply_db_nutrition(item, best_match, blend_ratio=1.0)
            elif similarity >= MEDIUM_CONFIDENCE_THRESHOLD:
                # Medium confidence: blend AI + DB values (60% DB, 40% AI)
                return self._apply_db_nutrition(item, best_match, blend_ratio=0.6)
            else:
                # Low confidence: keep AI values but note the closest match
                logger.info(
                    f"Low similarity ({similarity:.3f}) for '{item.name}', keeping AI values"
                )
                return item

        except Exception as e:
            logger.warning(f"RAG enhancement failed for '{item.name}': {e}")
            return item

    def _apply_db_nutrition(
        self, item: FoodItem, db_match: dict, blend_ratio: float
    ) -> FoodItem:
        """
        Apply database nutrition values to the AI-detected item.

        DB values are per 100g. Scale by the AI-estimated portion size.
        blend_ratio: 1.0 = fully trust DB, 0.0 = fully trust AI
        """
        portion_ratio = item.portion_g / 100.0

        # DB nutrition per 100g, scaled to AI-estimated portion
        db_calories = float(db_match["calories"]) * portion_ratio
        db_protein = float(db_match["protein_g"] or 0) * portion_ratio
        db_carbs = float(db_match["carbs_g"] or 0) * portion_ratio
        db_fat = float(db_match["fat_g"] or 0) * portion_ratio
        db_fiber = float(db_match.get("fiber_g") or 0) * portion_ratio

        # Blend AI and DB values
        r = blend_ratio
        new_calories = db_calories * r + item.calories * (1 - r)
        new_protein = db_protein * r + item.protein_g * (1 - r)
        new_carbs = db_carbs * r + item.carbs_g * (1 - r)
        new_fat = db_fat * r + item.fat_g * (1 - r)
        new_fiber = db_fiber * r + (item.fiber_g or 0) * (1 - r)

        # Increase confidence based on DB match
        new_confidence = min(0.98, item.confidence + (0.15 * blend_ratio))

        return FoodItem(
            name=item.name,
            name_en=item.name_en,
            portion_g=item.portion_g,
            calories=round(new_calories, 1),
            protein_g=round(new_protein, 1),
            carbs_g=round(new_carbs, 1),
            fat_g=round(new_fat, 1),
            fiber_g=round(new_fiber, 1),
            confidence=round(new_confidence, 2),
            matched_food_id=db_match["food_id"],
        )

    async def _get_embedding(self, text: str) -> list[float]:
        """Generate text embedding using OpenAI, with caching."""
        cache_key = text.lower().strip()
        if cache_key in self._embedding_cache:
            return self._embedding_cache[cache_key]

        try:
            response = await self._openai_client.embeddings.create(
                model=settings.EMBEDDING_MODEL,
                input=text,
            )
            embedding = response.data[0].embedding
            self._embedding_cache[cache_key] = embedding
            return embedding
        except Exception as e:
            logger.error(f"Embedding generation failed: {e}")
            return []

    async def _search_similar_foods(
        self, embedding: list[float], top_k: int = 3
    ) -> list[dict]:
        """Search pgvector for similar food items with nutrition data."""
        try:
            pool = await get_pool()
            async with pool.acquire() as conn:
                # Convert embedding to pgvector format
                embedding_str = "[" + ",".join(str(x) for x in embedding) + "]"

                rows = await conn.fetch(
                    """
                    SELECT
                        fe.food_id,
                        fe.food_name,
                        fe.food_name_tr,
                        fe.embedding <=> $1::vector AS distance,
                        f.calories,
                        f.protein_g,
                        f.carbs_g,
                        f.fat_g,
                        f.fiber_g,
                        f.serving_size_g
                    FROM food_embeddings fe
                    JOIN foods f ON f.id = fe.food_id
                    WHERE fe.embedding IS NOT NULL
                    ORDER BY fe.embedding <=> $1::vector
                    LIMIT $2
                    """,
                    embedding_str,
                    top_k,
                )

                return [dict(row) for row in rows]

        except Exception as e:
            logger.error(f"pgvector search failed: {e}")
            return []

    async def search_foods_by_name(self, query: str, top_k: int = 5) -> list[dict]:
        """
        Public method: search foods by name for the food search feature.
        Returns similar foods from the database using semantic search.
        """
        embedding = await self._get_embedding(query)
        if not embedding:
            return []
        return await self._search_similar_foods(embedding, top_k=top_k)
