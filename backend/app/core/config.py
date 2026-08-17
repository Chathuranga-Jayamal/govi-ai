from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "Govi-AI Backend"
    debug: bool = False
    api_v1_prefix: str = "/api/v1"
    database_url: str = "postgresql://user:password@localhost:5432/govi_ai"

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")


@lru_cache
def get_settings() -> Settings:
    return Settings()
