from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    OPENAI_API_KEY: str = ""
    ANTHROPIC_API_KEY: str = ""
    USDA_API_KEY: str = "DEMO_KEY"
    ALLOWED_ORIGINS: list[str] = ["*"]

    # Model settings (API-only, no self-hosted models)
    PRIMARY_VISION_MODEL: str = "gpt-5.2"
    FALLBACK_VISION_MODEL: str = "claude-sonnet-4-20250514"
    RECIPE_MODEL: str = "claude-sonnet-4-20250514"

    # Processing
    MAX_IMAGE_SIZE_MB: int = 10
    ANALYSIS_TIMEOUT_SECONDS: int = 30

    class Config:
        env_file = ".env"


settings = Settings()
