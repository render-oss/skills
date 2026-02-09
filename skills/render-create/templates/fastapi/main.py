from fastapi import FastAPI
from app.config import settings
from app.database import engine
from app import models

# Create database tables
models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
)


@app.get("/health")
async def health_check():
    return {"status": "ok"}


@app.get("/")
async def root():
    return {"message": f"Welcome to {settings.app_name}"}
