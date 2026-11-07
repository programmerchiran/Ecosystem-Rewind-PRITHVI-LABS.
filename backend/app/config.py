
import os
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    
    APP_NAME: str = "Ecosystem Rewind API"
    APP_VERSION: str = "1.0.0"
    ORGANIZATION: str = "PRITHVI LABS"
    API_PREFIX: str = "/api"
    DEBUG: bool = True
    ALLOWED_ORIGINS: list[str] = [
        "http://localhost:3000",
        "http://localhost:8080",
        "http://localhost:5000",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:8080",
        "http://127.0.0.1:5000",
        "http://localhost",
        "http://127.0.0.1",
        "*"
    ]
    DATA_DIR: str = os.path.join(os.path.dirname(__file__), "data")
    
    NUGEN_API_KEY: str = ""
    NUGEN_MODEL_ID: str = ""
    NUGEN_API_URL: str = (
        "https://api.nugen.in/api/v3/inference/chat/completions"
    )

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


settings = Settings()
