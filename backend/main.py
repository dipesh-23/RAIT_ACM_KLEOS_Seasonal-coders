"""
ASHA Triage Backend — Python FastAPI
Mirrors the Flutter triage logic for demo, testing, and web access.
Strict rules: No diagnosis. No medication. Triage referral guidance only.
"""

from __future__ import annotations
import json
import math
import os
from pathlib import Path
from typing import List, Optional
from datetime import datetime

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse
from pydantic import BaseModel

# ── Imports deferred so server starts even if model not yet downloaded ──
try:
    from sentence_transformers import SentenceTransformer
    _MODEL_AVAILABLE = True
except ImportError:
    _MODEL_AVAILABLE = False

# ─────────────────────────── App setup ────────────────────────────────
app = FastAPI(
    title="ASHA Triage API",
    description="Offline-first triage decision support for ASHA frontline health workers. "
                "NO diagnosis. NO medication. RED / YELLOW / GREEN referral only.",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

BASE_DIR = Path(__file__).parent
ANCHORS_PATH = BASE_DIR / "clinical_anchors.json"

# ─────────────────────────── Global state ─────────────────────────────
_model: Optional[object] = None
_anchors: List[dict] = []
_anchor_embeddings: dict[str, List[float]] = {}


def _load_anchors() -> List[dict]:
    with open(ANCHORS_PATH, encoding="utf-8") as f:
        data = json.load(f)
    return data["anchors"]


def _cosine_similarity(a: List[float], b: List[float]) -> float:
    dot = sum(x * y for x, y in zip(a, b))
    norm_a = math.sqrt(sum(x * x for x in a))
    norm_b = math.sqrt(sum(x * x for x in b))
    if norm_a == 0 or norm_b == 0:
        return 0.0
    return max(0.0, min(1.0, dot / (norm_a * norm_b)))


@app.on_event("startup")
async def startup():
    global _model, _anchors, _anchor_embeddings
    _anchors = _load_anchors()

    if _MODEL_AVAILABLE:
        try:
            print("Loading MiniLM model (paraphrase-multilingual-MiniLM-L12-v2)...")
            _model = SentenceTransformer(
                "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
            )
            print("Pre-computing anchor embeddings...")
            for anchor in _anchors:
                emb = _model.encode(anchor["concept"]).tolist()
                _anchor_embeddings[anchor["key"]] = emb
            print(f"✓ Triage engine ready — {len(_anchors)} anchors loaded")
        except Exception as e:
            print(f"⚠ Model load failed: {e} — keyword fallback active")
            _model = None
    else:
        print("⚠ sentence-transformers not installed — keyword fallback active")


# ─────────────────────────── Schemas ──────────────────────────────────

class AnalyzeRequest(BaseModel):
    transcript: str
    age_group: str  # NEWBORN | CHILD | ADULT | ELDERLY
    duration: str   # TODAY | TWO_THREE_DAYS | FOUR_PLUS_DAYS

class DetectedConceptOut(BaseModel):
    concept_key: str
    hindi_question: str
    category: str
    similarity_score: float
    weight: float

class AnalyzeResponse(BaseModel):
    detected_concepts: List[DetectedConceptOut]
    model_used: str

class TriageRequest(BaseModel):
    confirmed_concepts: List[DetectedConceptOut]
    age_group: str
    duration: str
    force_red: bool = False
    worker_name: str = ""

class TriageResponse(BaseModel):
    triage_level: str       # RED | YELLOW | GREEN
    hindi_reason: str
    level_hindi: str
    session_code: str
    timestamp: str
    confirmed_concepts: List[DetectedConceptOut]

class HealthResponse(BaseModel):
    status: str
    model_loaded: bool
    anchors_loaded: int
    message: str


# ─────────────────────────── Helpers ──────────────────────────────────

_HINDI_KEYWORDS: dict[str, List[str]] = {
    "breathing_difficulty": ["सांस", "saans", "breath", "respiratory"],
    "unconscious": ["बेहोश", "behosh", "unconscious", "faint", "collapse"],
    "seizure": ["दौरा", "daura", "seizure", "convuls", "fits"],
    "severe_bleeding": ["खून", "khoon", "bleed", "blood", "haemorrhage"],
    "chest_pain": ["सीने", "chest", "seene", "heart", "cardiac"],
    "newborn_emergency": ["नवजात", "navjat", "newborn", "baby", "infant"],
    "labor_complication": ["प्रसव", "prasav", "labor", "delivery", "birth"],
    "not_eating_drinking": ["खाना", "khana", "eating", "drinking", "refuse"],
    "high_fever_prolonged": ["तेज बुखार", "high fever", "bukhar", "fever"],
    "repeated_vomiting": ["उल्टी", "ulti", "vomit"],
    "severe_diarrhea": ["दस्त", "dast", "diarrhea", "loose", "motion"],
    "severe_headache": ["सिरदर्द", "sirdarad", "headache"],
    "pregnancy_concern": ["गर्भ", "garbh", "pregnant", "pregnancy"],
    "child_lethargic": ["सुस्त", "sust", "letharg", "weak", "dull"],
    "body_swelling": ["सूजन", "sujan", "swelling", "edema"],
    "mild_fever": ["हल्का बुखार", "mild fever", "halka bukhar"],
    "common_cold": ["सर्दी", "sardi", "cold", "cough", "jukam", "sneez"],
    "minor_body_ache": ["हल्का दर्द", "body ache", "mild pain"],
    "minor_stomach_ache": ["पेट दर्द", "stomach", "indigestion", "gas"],
}

def _keyword_fallback(transcript: str, age_group: str) -> List[DetectedConceptOut]:
    lower = transcript.lower()
    results = []
    for anchor in _anchors:
        kws = _HINDI_KEYWORDS.get(anchor["key"], [])
        if any(kw in lower for kw in kws):
            weight = anchor["weight"]
            if age_group == "NEWBORN" and anchor["category"] == "RED":
                weight *= 1.5
            if age_group == "ELDERLY" and anchor["key"] == "chest_pain":
                weight *= 1.3
            results.append(DetectedConceptOut(
                concept_key=anchor["key"],
                hindi_question=anchor["hindi_question"],
                category=anchor["category"],
                similarity_score=0.75,
                weight=weight,
            ))
    results.sort(key=lambda x: x.weight, reverse=True)
    return results[:3]

def _apply_multipliers(
    weight: float, category: str, key: str, age_group: str, duration: str
) -> float:
    if age_group == "NEWBORN" and category == "RED":
        weight *= 1.5
    if age_group == "ELDERLY" and key == "chest_pain":
        weight *= 1.3
    if duration == "FOUR_PLUS_DAYS" and key in (
        "high_fever_prolonged", "mild_fever"
    ):
        weight *= 1.4
    return weight

def _score_triage(
    confirmed: List[DetectedConceptOut],
    age_group: str,
    duration: str,
    session_code: str,
    force_red: bool,
) -> TriageResponse:
    ts = datetime.now().isoformat()

    if force_red:
        return TriageResponse(
            triage_level="RED",
            hindi_reason="मरीज की स्थिति गंभीर है। तुरंत जिला अस्पताल रेफर करें।",
            level_hindi="तुरंत रेफर करें",
            session_code=session_code,
            timestamp=ts,
            confirmed_concepts=confirmed,
        )

    red_score = 0.0
    yellow_score = 0.0

    for c in confirmed:
        if c.category == "RED":
            red_score += c.weight
            if c.weight >= 8.0:
                return TriageResponse(
                    triage_level="RED",
                    hindi_reason="मरीज की स्थिति गंभीर है। तुरंत जिला अस्पताल रेफर करें।",
                    level_hindi="तुरंत रेफर करें",
                    session_code=session_code,
                    timestamp=ts,
                    confirmed_concepts=confirmed,
                )
        elif c.category == "YELLOW":
            yellow_score += c.weight

    if red_score >= 6.5:
        return TriageResponse(
            triage_level="RED",
            hindi_reason="मरीज की स्थिति गंभीर है। तुरंत जिला अस्पताल रेफर करें।",
            level_hindi="तुरंत रेफर करें",
            session_code=session_code,
            timestamp=ts,
            confirmed_concepts=confirmed,
        )

    if yellow_score >= 5.0:
        return TriageResponse(
            triage_level="YELLOW",
            hindi_reason="मरीज को आज रेफर करें। स्थिति पर नज़र रखें।",
            level_hindi="आज रेफर करें",
            session_code=session_code,
            timestamp=ts,
            confirmed_concepts=confirmed,
        )

    return TriageResponse(
        triage_level="GREEN",
        hindi_reason="मरीज को स्थानीय देखभाल दी जा सकती है।",
        level_hindi="स्थानीय उपचार",
        session_code=session_code,
        timestamp=ts,
        confirmed_concepts=confirmed,
    )


# ─────────────────────────── Endpoints ────────────────────────────────

@app.get("/", response_class=HTMLResponse, include_in_schema=False)
async def root():
    html = Path(BASE_DIR / "static" / "index.html")
    if html.exists():
        return html.read_text(encoding="utf-8")
    return "<h1>ASHA Triage API</h1><p>See <a href='/docs'>/docs</a></p>"


@app.get("/health", response_model=HealthResponse, tags=["System"])
async def health():
    return HealthResponse(
        status="ok",
        model_loaded=_model is not None,
        anchors_loaded=len(_anchors),
        message="ASHA Triage API running. No diagnosis. No medication. Triage only.",
    )


@app.post("/analyze", response_model=AnalyzeResponse, tags=["Triage"])
async def analyze(req: AnalyzeRequest):
    """
    Step 1 — Analyse transcript and return top-3 detected clinical concepts.
    Worker must confirm each concept on the confirmation screen before scoring.
    """
    if not req.transcript.strip():
        raise HTTPException(status_code=400, detail="Transcript cannot be empty.")

    if _model is not None:
        transcript_emb = _model.encode(req.transcript).tolist()
        results = []
        for anchor in _anchors:
            anchor_emb = _anchor_embeddings.get(anchor["key"])
            if not anchor_emb:
                continue
            sim = _cosine_similarity(transcript_emb, anchor_emb)
            if sim >= 0.65:
                weight = _apply_multipliers(
                    anchor["weight"],
                    anchor["category"],
                    anchor["key"],
                    req.age_group,
                    req.duration,
                )
                results.append(DetectedConceptOut(
                    concept_key=anchor["key"],
                    hindi_question=anchor["hindi_question"],
                    category=anchor["category"],
                    similarity_score=round(sim, 4),
                    weight=weight,
                ))
        results.sort(key=lambda x: x.similarity_score, reverse=True)
        return AnalyzeResponse(
            detected_concepts=results[:3],
            model_used="MiniLM-L12-v2 (sentence-transformers)",
        )
    else:
        results = _keyword_fallback(req.transcript, req.age_group)
        return AnalyzeResponse(
            detected_concepts=results,
            model_used="keyword-fallback",
        )


@app.post("/triage", response_model=TriageResponse, tags=["Triage"])
async def triage(req: TriageRequest):
    """
    Step 2 — Score confirmed concepts and return RED / YELLOW / GREEN triage level.
    SAFETY RULE: No diagnosis. No medication. Referral guidance only.
    """
    import random
    session_code = str(random.randint(100000, 999999))

    return _score_triage(
        confirmed=req.confirmed_concepts,
        age_group=req.age_group,
        duration=req.duration,
        session_code=session_code,
        force_red=req.force_red,
    )


@app.post("/full-triage", response_model=TriageResponse, tags=["Triage"])
async def full_triage(req: AnalyzeRequest):
    """
    Single-shot endpoint: transcript → auto-confirm all detected concepts → triage result.
    Use for demo / testing only. Production app uses /analyze + worker confirmation.
    """
    analyze_resp = await analyze(req)
    confirmed = [
        DetectedConceptOut(**c.model_dump())
        for c in analyze_resp.detected_concepts
    ]
    import random
    session_code = str(random.randint(100000, 999999))
    return _score_triage(
        confirmed=confirmed,
        age_group=req.age_group,
        duration=req.duration,
        session_code=session_code,
        force_red=False,
    )
