"""
Global food database seeder.

Sources:
  1. Turkish foods (local JSON) — 118 items, high quality
  2. USDA Foundation + SR Legacy — ~7500 basic ingredients
  3. USDA Branded (popular categories) — ~5000 popular products
  4. OpenFoodFacts (Turkey + top countries) — lazy-load ready

Usage:
    python -m scripts.seed_foods                    # All sources
    python -m scripts.seed_foods --turkish-only     # Only Turkish foods
    python -m scripts.seed_foods --skip-embeddings  # Skip embedding generation
    python -m scripts.seed_foods --usda-only        # Only USDA data

Requires:
    - PostgreSQL running with pgvector extension
    - OPENAI_API_KEY set in environment
    - DATABASE_URL set in environment
    - USDA_API_KEY set (optional, DEMO_KEY works with rate limits)
"""

import argparse
import asyncio
import json
import logging
import sys
from pathlib import Path
from uuid import uuid4

import asyncpg
import openai

sys.path.insert(0, str(Path(__file__).parent.parent))
from app.config import settings
from app.services.usda_service import USDAService
from app.services.openfoodfacts_service import OpenFoodFactsService

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

EMBEDDING_BATCH_SIZE = 50
DATA_DIR = Path(__file__).parent.parent / "data"

# Popular USDA Branded categories to import
BRANDED_CATEGORIES = [
    "Chicken", "Beef", "Pork", "Fish", "Eggs",
    "Milk", "Cheese", "Yogurt", "Butter",
    "Rice", "Pasta", "Bread", "Cereal",
    "Apple", "Banana", "Orange", "Tomato", "Potato",
    "Olive oil", "Sunflower oil",
    "Chocolate", "Ice cream", "Cake",
    "Cola", "Juice", "Coffee", "Tea",
    "Pizza", "Hamburger", "Sandwich",
    "Nuts", "Almonds", "Peanut butter",
    "Protein bar", "Protein powder",
    "Salad", "Soup", "Sauce",
]


async def insert_food(conn, food: dict) -> str | None:
    """Insert a food item, skip if already exists. Returns food_id or None."""
    # Check duplicates by source_id or name
    source_id = food.get("source_id")
    if source_id:
        existing = await conn.fetchrow(
            "SELECT id FROM foods WHERE source = $1 AND barcode = $2",
            food.get("source", "custom"),
            source_id,
        )
        if existing:
            return None

    # Also check by exact name
    existing = await conn.fetchrow(
        "SELECT id FROM foods WHERE name = $1",
        food["name"],
    )
    if existing:
        return None

    food_id = str(uuid4())
    await conn.execute(
        """
        INSERT INTO foods (
            id, name, name_tr, brand, barcode, serving_size_g,
            calories, protein_g, carbs_g, fat_g, fiber_g,
            sugar_g, saturated_fat_g, sodium_mg,
            source, is_verified, created_at
        ) VALUES (
            $1, $2, $3, $4, $5, $6,
            $7, $8, $9, $10, $11,
            $12, $13, $14,
            $15, $16, NOW()
        )
        """,
        food_id,
        food["name"][:255],
        food.get("name_tr"),
        food.get("brand"),
        food.get("barcode") or food.get("source_id"),
        food.get("serving_size_g", 100),
        food.get("calories", 0),
        food.get("protein_g"),
        food.get("carbs_g"),
        food.get("fat_g"),
        food.get("fiber_g"),
        food.get("sugar_g"),
        food.get("saturated_fat_g"),
        food.get("sodium_mg"),
        food.get("source", "custom"),
        food.get("source") in ("usda", "custom"),  # USDA and custom are verified
    )
    return food_id


async def generate_embeddings(
    pool: asyncpg.Pool,
    food_ids: list[str],
    foods: list[dict],
    openai_client: openai.AsyncOpenAI,
):
    """Generate and store embeddings for a batch of foods."""
    for i in range(0, len(food_ids), EMBEDDING_BATCH_SIZE):
        batch_ids = food_ids[i : i + EMBEDDING_BATCH_SIZE]
        batch_foods = foods[i : i + EMBEDDING_BATCH_SIZE]

        search_texts = []
        for food in batch_foods:
            parts = []
            if food.get("name_tr"):
                parts.append(food["name_tr"])
            parts.append(food["name"])
            if food.get("brand"):
                parts.append(food["brand"])
            search_texts.append(" ".join(parts))

        try:
            response = await openai_client.embeddings.create(
                model=settings.EMBEDDING_MODEL,
                input=search_texts,
            )

            async with pool.acquire() as conn:
                for j, emb_data in enumerate(response.data):
                    embedding_str = (
                        "[" + ",".join(str(x) for x in emb_data.embedding) + "]"
                    )
                    food = batch_foods[j]

                    await conn.execute(
                        """
                        INSERT INTO food_embeddings
                            (id, food_id, food_name, food_name_tr, search_text, embedding)
                        VALUES ($1, $2, $3, $4, $5, $6::vector)
                        ON CONFLICT (food_id) DO UPDATE
                        SET embedding = $6::vector,
                            search_text = $5,
                            food_name = $3,
                            food_name_tr = $4
                        """,
                        str(uuid4()),
                        batch_ids[j],
                        food["name"][:255],
                        food.get("name_tr"),
                        search_texts[j],
                        embedding_str,
                    )

            logger.info(
                f"Embedded batch {i // EMBEDDING_BATCH_SIZE + 1}: "
                f"{len(batch_ids)} items"
            )

        except Exception as e:
            logger.error(f"Embedding batch failed: {e}")


async def seed_turkish_foods(pool: asyncpg.Pool) -> tuple[list[str], list[dict]]:
    """Seed Turkish food data from local JSON."""
    turkish_file = DATA_DIR / "turkish_foods.json"
    if not turkish_file.exists():
        logger.warning("Turkish foods file not found, skipping")
        return [], []

    with open(turkish_file) as f:
        foods = json.load(f)

    logger.info(f"Importing {len(foods)} Turkish foods...")

    inserted_ids = []
    inserted_foods = []

    async with pool.acquire() as conn:
        for food in foods:
            food_id = await insert_food(conn, food)
            if food_id:
                inserted_ids.append(food_id)
                inserted_foods.append(food)

    logger.info(f"Turkish foods: {len(inserted_ids)} inserted, {len(foods) - len(inserted_ids)} skipped")
    return inserted_ids, inserted_foods


async def seed_usda_foods(pool: asyncpg.Pool) -> tuple[list[str], list[dict]]:
    """Seed USDA Foundation + SR Legacy + popular Branded foods."""
    usda = USDAService()
    inserted_ids = []
    inserted_foods = []

    try:
        # Faz 1: Foundation + SR Legacy
        logger.info("Fetching USDA Foundation + SR Legacy foods...")
        foundation_foods = await usda.fetch_foundation_foods(
            page_size=200, max_pages=50
        )
        logger.info(f"Fetched {len(foundation_foods)} foundation/legacy foods from USDA")

        async with pool.acquire() as conn:
            for food in foundation_foods:
                food_id = await insert_food(conn, food)
                if food_id:
                    inserted_ids.append(food_id)
                    inserted_foods.append(food)

        logger.info(f"USDA Foundation: {len(inserted_ids)} inserted")

        # Faz 2: Popular Branded
        logger.info("Fetching USDA popular branded foods...")
        branded_foods = await usda.fetch_branded_popular(
            categories=BRANDED_CATEGORIES, page_size=100
        )
        logger.info(f"Fetched {len(branded_foods)} branded foods from USDA")

        branded_inserted = 0
        async with pool.acquire() as conn:
            for food in branded_foods:
                food_id = await insert_food(conn, food)
                if food_id:
                    inserted_ids.append(food_id)
                    inserted_foods.append(food)
                    branded_inserted += 1

        logger.info(f"USDA Branded: {branded_inserted} inserted")

    except Exception as e:
        logger.error(f"USDA seed failed: {e}")
    finally:
        await usda.close()

    return inserted_ids, inserted_foods


async def ensure_schema(pool: asyncpg.Pool):
    """Ensure database tables and extensions exist."""
    async with pool.acquire() as conn:
        await conn.execute("CREATE EXTENSION IF NOT EXISTS vector;")

        await conn.execute("""
            CREATE TABLE IF NOT EXISTS food_embeddings (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                food_id UUID NOT NULL,
                food_name VARCHAR(255) NOT NULL,
                food_name_tr VARCHAR(255),
                search_text TEXT NOT NULL,
                embedding vector(1536),
                created_at TIMESTAMPTZ DEFAULT NOW(),
                CONSTRAINT fk_food
                    FOREIGN KEY (food_id)
                    REFERENCES foods(id)
                    ON DELETE CASCADE
            );
        """)

        try:
            await conn.execute(
                "CREATE UNIQUE INDEX IF NOT EXISTS idx_food_embeddings_food_id_unique "
                "ON food_embeddings (food_id);"
            )
        except Exception:
            pass


async def create_vector_index(pool: asyncpg.Pool):
    """Create IVFFlat index if enough rows exist."""
    async with pool.acquire() as conn:
        count = await conn.fetchval(
            "SELECT COUNT(*) FROM food_embeddings WHERE embedding IS NOT NULL"
        )
        if count >= 100:
            lists = min(count // 10, 1000)  # IVFFlat: lists ≈ sqrt(rows) or rows/10
            try:
                await conn.execute(f"""
                    DROP INDEX IF EXISTS idx_food_embeddings_vector;
                    CREATE INDEX idx_food_embeddings_vector
                    ON food_embeddings
                    USING ivfflat (embedding vector_cosine_ops)
                    WITH (lists = {lists});
                """)
                logger.info(f"Created IVFFlat index with {lists} lists for {count} embeddings")
            except Exception as e:
                logger.warning(f"IVFFlat index creation failed: {e}")


async def main():
    parser = argparse.ArgumentParser(description="Seed Forkcast food database")
    parser.add_argument("--turkish-only", action="store_true", help="Only import Turkish foods")
    parser.add_argument("--usda-only", action="store_true", help="Only import USDA foods")
    parser.add_argument("--skip-embeddings", action="store_true", help="Skip embedding generation")
    args = parser.parse_args()

    logger.info("=== Forkcast Food Database Seeder ===")

    pool = await asyncpg.create_pool(dsn=settings.DATABASE_URL, min_size=2, max_size=10)
    await ensure_schema(pool)

    all_ids: list[str] = []
    all_foods: list[dict] = []

    # Source 1: Turkish foods
    if not args.usda_only:
        ids, foods = await seed_turkish_foods(pool)
        all_ids.extend(ids)
        all_foods.extend(foods)

    # Source 2+3: USDA Foundation + Branded
    if not args.turkish_only:
        ids, foods = await seed_usda_foods(pool)
        all_ids.extend(ids)
        all_foods.extend(foods)

    logger.info(f"Total new foods inserted: {len(all_ids)}")

    # Generate embeddings
    if not args.skip_embeddings and all_ids:
        logger.info(f"Generating embeddings for {len(all_ids)} foods...")
        openai_client = openai.AsyncOpenAI(api_key=settings.OPENAI_API_KEY)
        await generate_embeddings(pool, all_ids, all_foods, openai_client)

    # Create/update vector index
    await create_vector_index(pool)

    # Final stats
    async with pool.acquire() as conn:
        total_foods = await conn.fetchval("SELECT COUNT(*) FROM foods")
        total_embeddings = await conn.fetchval(
            "SELECT COUNT(*) FROM food_embeddings WHERE embedding IS NOT NULL"
        )
        sources = await conn.fetch(
            "SELECT source, COUNT(*) as cnt FROM foods GROUP BY source ORDER BY cnt DESC"
        )

    logger.info("=== Final Database Stats ===")
    logger.info(f"Total foods: {total_foods}")
    logger.info(f"Total embeddings: {total_embeddings}")
    for row in sources:
        logger.info(f"  {row['source'] or 'unknown'}: {row['cnt']}")

    await pool.close()


if __name__ == "__main__":
    asyncio.run(main())
