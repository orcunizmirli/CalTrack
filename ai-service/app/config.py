from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    OPENAI_API_KEY: str = ""
    ANTHROPIC_API_KEY: str = ""
    DATABASE_URL: str = ""
    AWS_S3_BUCKET: str = "caltrack-photos"
    AWS_REGION: str = "eu-west-1"
    ALLOWED_ORIGINS: list[str] = ["*"]

    # Model settings
    PRIMARY_VISION_MODEL: str = "gpt-5.2"
    FALLBACK_VISION_MODEL: str = "claude-sonnet-4-20250514"
    RECIPE_MODEL: str = "claude-sonnet-4-20250514"
    EMBEDDING_MODEL: str = "text-embedding-3-small"

    # Processing
    MAX_IMAGE_SIZE_MB: int = 10
    ANALYSIS_TIMEOUT_SECONDS: int = 30

    class Config:
        env_file = ".env"


settings = Settings()
