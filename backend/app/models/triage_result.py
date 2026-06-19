from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field


class TriageLevel(str, Enum):
    red = "red"
    yellow = "yellow"
    green = "green"


class TriageRequest(BaseModel):
    transcript: str = Field(min_length=1)


class TriageResult(BaseModel):
    level: TriageLevel
    transcript: str
    confidence: float
    matched_anchor: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)
