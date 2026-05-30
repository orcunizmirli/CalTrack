from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    OPENAI_API_KEY: str = ""
    ANTHROPIC_API_KEY: str = ""
    USDA_API_KEY: str = "DEMO_KEY"
    ALLOWED_ORIGINS: list[str] = ["*"]

    # Model settings — cost-optimized, API-only
    PRIMARY_VISION_MODEL: str = "gpt-4.1-mini"
    FALLBACK_VISION_MODEL: str = "claude-haiku-4-5-20251001"
    RECIPE_MODEL: str = "gpt-4.1-mini"

    # Processing
    MAX_IMAGE_SIZE_MB: int = 10
    ANALYSIS_TIMEOUT_SECONDS: int = 30

    class Config:
        env_file = ".env"


settings = Settings()
