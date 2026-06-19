from datetime import datetime

from pydantic import BaseModel, Field

from .triage_result import TriageLevel


class SessionCreate(BaseModel):
    id: str
    started_at: datetime
    completed_at: datetime | None = None
    transcript: str | None = None
    level: TriageLevel | None = None
    confidence: float | None = None
    matched_anchor: str | None = None


class SessionResponse(BaseModel):
    id: str
    started_at: datetime
    completed_at: datetime | None = None
    transcript: str | None = None
    level: TriageLevel | None = None
    confidence: float | None = None
    matched_anchor: str | None = None
