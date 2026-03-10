"""
Seed script: Populates the foods table with Turkish food data
and generates embeddings for pgvector similarity search.

Usage:
    python -m scripts.seed_foods

Requires:
    - PostgreSQL running with pgvector extension
    - OPENAI_API_KEY set in environment
    - DATABASE_URL set in environment
"""

import asyncio
import json
import logging
import os
import sys
from pathlib import Path
from uuid import uuid4

import asyncpg
import openai

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent.parent))
from app.config import settings

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

BATCH_SIZE = 20  # OpenAI embedding API batch size
DATA_FILE = Path(__file__).parent.parent / "data" / "turkish_foods.json"


async def main():
    logger.info("Starting food database seeding...")

    # Load food data
    with open(DATA_FILE) as f:
        foods = json.load(f)
    logger.info(f"Loaded {len(foods)} food items from seed data")

    # Connect to database
    pool = await asyncpg.create_pool(dsn=settings.DATABASE_URL, min_size=2, max_size=5)

    async with pool.acquire() as conn:
        # Ensure pgvector extension
        await conn.execute("CREATE EXTENSION IF NOT EXISTS vector;")

        # Ensure food_embeddings table exists
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

    # Insert foods and generate embeddings
    openai_client = openai.AsyncOpenAI(api_key=settings.OPENAI_API_KEY)
    inserted = 0
    skipped = 0

    for i in range(0, len(foods), BATCH_SIZE):
        batch = foods[i : i + BATCH_SIZE]
        food_ids = []
        search_texts = []

        async with pool.acquire() as conn:
            for food in batch:
                # Check if food already exists by name
                existing = await conn.fetchrow(
                    "SELECT id FROM foods WHERE name = $1 OR name_tr = $2",
                    food["name"],
                    food.get("name_tr"),
                )

                if existing:
                    food_id = str(existing["id"])
                    skipped += 1
                else:
                    food_id = str(uuid4())
                    await conn.execute(
                        """
                        INSERT INTO foods (id, name, name_tr, serving_size_g, calories,
                            protein_g, carbs_g, fat_g, fiber_g, source, is_verified, created_at)
                        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, true, NOW())
                        """,
                        food_id,
                        food["name"],
                        food.get("name_tr"),
                        food["serving_size_g"],
                        food["calories"],
                        food.get("protein_g"),
                        food.get("carbs_g"),
                        food.get("fat_g"),
                        food.get("fiber_g"),
                        food.get("source", "custom"),
                    )
                    inserted += 1

                food_ids.append(food_id)
                # Build search text: combine Turkish and English names for better matching
                name_tr = food.get("name_tr", "")
                name_en = food["name"]
                search_text = f"{name_tr} {name_en}".strip()
                search_texts.append(search_text)

        # Generate embeddings for the batch
        try:
            response = await openai_client.embeddings.create(
                model=settings.EMBEDDING_MODEL,
                input=search_texts,
            )

            async with pool.acquire() as conn:
                for j, emb_data in enumerate(response.data):
                    embedding = emb_data.embedding
                    embedding_str = "[" + ",".join(str(x) for x in embedding) + "]"
                    food = batch[j]

                    # Upsert embedding
                    await conn.execute(
                        """
                        INSERT INTO food_embeddings (id, food_id, food_name, food_name_tr, search_text, embedding)
                        VALUES ($1, $2, $3, $4, $5, $6::vector)
                        ON CONFLICT (food_id) DO UPDATE
                        SET embedding = $6::vector,
                            search_text = $5,
                            food_name = $3,
                            food_name_tr = $4
                        """,
                        str(uuid4()),
                        food_ids[j],
                        food["name"],
                        food.get("name_tr"),
                        search_texts[j],
                        embedding_str,
                    )

            logger.info(
                f"Batch {i // BATCH_SIZE + 1}: embedded {len(batch)} items"
            )

        except Exception as e:
            logger.error(f"Embedding batch failed: {e}")
            continue

    # Add unique constraint on food_id if not exists
    async with pool.acquire() as conn:
        try:
            await conn.execute(
                """
                CREATE UNIQUE INDEX IF NOT EXISTS idx_food_embeddings_food_id_unique
                ON food_embeddings (food_id);
                """
            )
        except Exception:
            pass  # Already exists

    # Create ivfflat index if enough rows
    async with pool.acquire() as conn:
        count = await conn.fetchval("SELECT COUNT(*) FROM food_embeddings WHERE embedding IS NOT NULL")
        if count >= 100:
            try:
                await conn.execute("""
                    CREATE INDEX IF NOT EXISTS idx_food_embeddings_vector
                    ON food_embeddings
                    USING ivfflat (embedding vector_cosine_ops)
                    WITH (lists = 100);
                """)
                logger.info("Created IVFFlat index for vector search")
            except Exception as e:
                logger.warning(f"IVFFlat index creation skipped: {e}")

    await pool.close()

    logger.info(f"Seeding complete: {inserted} inserted, {skipped} already existed")
    logger.info(f"Total foods with embeddings ready for RAG search")


if __name__ == "__main__":
    asyncio.run(main())
