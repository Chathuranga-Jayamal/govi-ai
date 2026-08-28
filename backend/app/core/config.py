from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "Govi-AI Backend"
    debug: bool = False
    api_v1_prefix: str = "/api/v1"
    database_url: str = "postgresql://user:password@localhost:5432/govi_ai"
    jwt_secret_key: str = "changeme"
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 60
    llm_api_key: str = "changeme"
    llm_model: str = "nvidia/nemotron-3-ultra-550b-a55b:free"
    llm_base_url: str = "https://openrouter.ai/api/v1"

    model_config = SettingsConfigDict(
        env_file=".env", env_file_encoding="utf-8", extra="ignore"
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()
