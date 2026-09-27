import os
from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field

class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        case_sensitive=True,
        extra="allow"
    )

    PROJECT_NAME: str = "Sarjan AI Automation & CRM"
    PROJECT_VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    ENVIRONMENT: str = "development"
    
    # Supabase Configuration
    SUPABASE_URL: str = "https://lrbmqfirkfogougzbvty.supabase.co"
    SUPABASE_SERVICE_ROLE_KEY: str = "mock_service_role_key_for_dev_mode"
    SUPABASE_ANON_KEY: str = "mock_anon_key_for_dev_mode"
    
    # Security
    JWT_SECRET: str = "super-secret-sarjan-jwt-key-2026-production-ready"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    
    # WhatsApp Cloud API (Prepared for Phase 9)
    WHATSAPP_ACCESS_TOKEN: str = ""
    WHATSAPP_VERIFY_TOKEN: str = "sarjan_whatsapp_verify_token_2026"
    WHATSAPP_PHONE_NUMBER_ID: str = ""
    
    # AI Engine (Prepared for Phase 10)
    AI_API_KEY: str = ""
    AI_MODEL: str = "gemini-1.5-flash"
    
    # CORS
    CORS_ORIGINS: List[str] = [
        "http://localhost:5173",
        "http://localhost:3000",
        "http://127.0.0.1:5173",
        "http://127.0.0.1:3000",
        "*"
    ]

settings = Settings()
