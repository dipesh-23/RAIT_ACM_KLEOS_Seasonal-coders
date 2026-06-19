from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routes.triage import database_service, router


@asynccontextmanager
async def lifespan(app: FastAPI):
    await database_service.init()
    yield


app = FastAPI(
    title="ASHA Triage API",
    description="Backend for voice-based clinical triage",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router)
