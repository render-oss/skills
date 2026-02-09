from datetime import datetime
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="API")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
async def health():
    """Health check endpoint."""
    return {"status": "ok"}


@app.get("/api/hello")
async def hello():
    """Hello endpoint."""
    return {
        "message": "Hello from FastAPI!",
        "timestamp": datetime.now().isoformat(),
    }
