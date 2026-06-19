from datetime import datetime

from fastapi import APIRouter, HTTPException

from app.models.session import SessionCreate, SessionResponse
from app.models.triage_result import TriageRequest, TriageResult, TriageLevel
from app.services.database_service import DatabaseService
from app.services.triage_engine import TriageEngine

router = APIRouter(prefix="/api", tags=["triage"])

triage_engine = TriageEngine()
database_service = DatabaseService()


@router.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}


@router.post("/triage/classify", response_model=TriageResult)
async def classify(request: TriageRequest) -> TriageResult:
    transcript = request.transcript.strip()
    if not transcript:
        raise HTTPException(status_code=400, detail="Transcript cannot be empty")

    level, confidence, matched_anchor = triage_engine.classify(transcript)
    return TriageResult(
        level=TriageLevel(level),
        transcript=transcript,
        confidence=confidence,
        matched_anchor=matched_anchor,
        timestamp=datetime.utcnow(),
    )


@router.post("/sessions", response_model=SessionResponse)
async def save_session(session: SessionCreate) -> SessionResponse:
    return await database_service.save_session(session)


@router.get("/sessions", response_model=list[SessionResponse])
async def list_sessions() -> list[SessionResponse]:
    return await database_service.get_all_sessions()
