from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


class TriageLevel(str, Enum):
    RED = "RED"
    YELLOW = "YELLOW"
    GREEN = "GREEN"


class TriageRequest(BaseModel):
    transcript: str = Field(min_length=1)


class TriageResult(BaseModel):
    level: TriageLevel
    transcript: str
    confidence: float
    matched_anchor: str          # English anchor phrase
    matched_anchor_hi: str = "" # Hindi anchor phrase (bilingual support)
    timestamp: datetime = Field(default_factory=datetime.utcnow)
