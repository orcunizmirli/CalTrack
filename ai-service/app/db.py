import asyncpg
from app.config import settings

_pool: asyncpg.Pool | None = None


async def get_pool() -> asyncpg.Pool:
    global _pool
    if _pool is None:
        _pool = await asyncpg.create_pool(
            dsn=settings.DATABASE_URL,
            min_size=2,
            max_size=10,
        )
    return _pool


async def close_pool():
    global _pool
    if _pool:
        await _pool.close()
        _pool = None


async def init_db():
    """Initialize pgvector extension and food_embeddings table."""
    pool = await get_pool()
    async with pool.acquire() as conn:
        # Enable pgvector extension
        await conn.execute("CREATE EXTENSION IF NOT EXISTS vector;")

        # Create food_embeddings table linked to foods table
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

        # Create index for vector similarity search
        await conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_food_embeddings_vector
            ON food_embeddings
            USING ivfflat (embedding vector_cosine_ops)
            WITH (lists = 100);
        """)

        # Create index for food_id lookup
        await conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_food_embeddings_food_id
            ON food_embeddings (food_id);
        """)
