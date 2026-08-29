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
    artifacts_dir: str | None = None
    payhere_merchant_id: str = "changeme"
    payhere_merchant_secret: str = "changeme"
    payhere_mode: str = "sandbox"
    # Used to build notify_url/return_url/cancel_url for PayHere. Not derived
    # from request.base_url (unlike product image URLs) because Fly.io
    # terminates TLS at its edge and forwards internally over plain HTTP —
    # request.base_url could resolve to http:// without proxy-header
    # handling, which would break the notify webhook's scheme silently.
    public_base_url: str = "https://govi-ai.fly.dev"

    model_config = SettingsConfigDict(
        env_file=".env", env_file_encoding="utf-8", extra="ignore"
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()
