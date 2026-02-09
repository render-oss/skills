from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_name: str = "{{PROJECT_NAME}}"
    database_url: str = ""

    class Config:
        env_file = ".env"


settings = Settings()
