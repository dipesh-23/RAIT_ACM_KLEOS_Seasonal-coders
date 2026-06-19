import json
from pathlib import Path

import numpy as np
from sentence_transformers import SentenceTransformer

from app.config import ANCHORS_PATH, EMBEDDING_MODEL


class EmbeddingService:
    _model: SentenceTransformer | None = None

    @classmethod
    def load(cls) -> None:
        if cls._model is None:
            cls._model = SentenceTransformer(EMBEDDING_MODEL)

    @classmethod
    def embed(cls, text: str | list[str]) -> np.ndarray:
        cls.load()
        assert cls._model is not None
        return cls._model.encode(text, normalize_embeddings=True)


class TriageEngine:
    def __init__(self) -> None:
        self._anchors: dict[str, list[str]] = {}
        self._anchor_embeddings: dict[str, np.ndarray] = {}
        self._loaded = False

    def load(self) -> None:
        if self._loaded:
            return

        raw = ANCHORS_PATH.read_text(encoding="utf-8")
        self._anchors = json.loads(raw)
        EmbeddingService.load()

        for level, phrases in self._anchors.items():
            if phrases:
                self._anchor_embeddings[level] = EmbeddingService.embed(phrases)

        self._loaded = True

    def classify(self, transcript: str) -> tuple[str, float, str]:
        self.load()
        query = EmbeddingService.embed(transcript)

        best_level = "green"
        best_score = -1.0
        best_anchor = ""

        for level, phrases in self._anchors.items():
            embeddings = self._anchor_embeddings.get(level)
            if embeddings is None or len(phrases) == 0:
                continue

            if embeddings.ndim == 1:
                embeddings = embeddings.reshape(1, -1)

            scores = embeddings @ query
            idx = int(np.argmax(scores))
            score = float(scores[idx])

            if score > best_score:
                best_score = score
                best_level = level
                best_anchor = phrases[idx]

        confidence = max(0.0, min(1.0, best_score))
        return best_level, confidence, best_anchor
