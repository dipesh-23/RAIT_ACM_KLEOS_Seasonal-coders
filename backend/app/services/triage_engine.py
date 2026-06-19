import json
from pathlib import Path
from dataclasses import dataclass

import numpy as np
from sentence_transformers import SentenceTransformer

from app.config import ANCHORS_PATH, EMBEDDING_MODEL


@dataclass
class AnchorEntry:
    """Represents a single clinical anchor with English and Hindi phrases."""
    phrase_en: str
    phrase_hi: str
    weight: float


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
        # Per-level anchor entries
        self._anchors: dict[str, list[AnchorEntry]] = {}
        # Per-level stacked embeddings (shape: N_anchors x embed_dim)
        # Each anchor contributes TWO rows: English embedding + Hindi embedding
        self._anchor_embeddings: dict[str, np.ndarray] = {}
        # Mapping from embedding row index → anchor entry index (2 rows per entry)
        self._row_to_entry: dict[str, list[int]] = {}
        self._loaded = False

    def load(self) -> None:
        if self._loaded:
            return

        raw = ANCHORS_PATH.read_text(encoding="utf-8")
        raw_data: dict[str, list[dict]] = json.loads(raw)
        EmbeddingService.load()

        for level, entries in raw_data.items():
            parsed: list[AnchorEntry] = []
            texts_to_embed: list[str] = []
            row_map: list[int] = []

            for idx, entry in enumerate(entries):
                phrase_en = entry.get("phrase", "")
                phrase_hi = entry.get("hindi", "")
                weight = float(entry.get("weight", 1))

                anchor = AnchorEntry(
                    phrase_en=phrase_en,
                    phrase_hi=phrase_hi,
                    weight=weight,
                )
                parsed.append(anchor)

                # Embed both English and Hindi phrases for bilingual matching
                if phrase_en:
                    texts_to_embed.append(phrase_en)
                    row_map.append(idx)
                if phrase_hi:
                    texts_to_embed.append(phrase_hi)
                    row_map.append(idx)

            self._anchors[level] = parsed
            self._row_to_entry[level] = row_map

            if texts_to_embed:
                embeddings = EmbeddingService.embed(texts_to_embed)  # (N, D)
                # Store raw normalized embeddings; weights applied at scoring time
                self._anchor_embeddings[level] = embeddings

        self._loaded = True

    def classify(self, transcript: str) -> tuple[str, float, str, str]:
        """
        Classify a transcript (English or Hindi) into a triage level.

        Returns:
            level         – "RED" | "YELLOW" | "GREEN"
            confidence    – float in [0, 1]
            matched_anchor_en – matched English phrase
            matched_anchor_hi – matched Hindi phrase
        """
        self.load()
        query = EmbeddingService.embed(transcript)  # (D,)

        best_level = "GREEN"
        best_score = -1.0
        best_entry: AnchorEntry | None = None

        for level, embeddings in self._anchor_embeddings.items():
            if embeddings.ndim == 1:
                embeddings = embeddings.reshape(1, -1)

            # Pure cosine similarity (embeddings are L2-normalized)
            cos_scores = embeddings @ query  # (N,)

            # Small additive weight bonus as tie-breaker (weight=10 → +0.02)
            entries = self._anchors[level]
            row_map = self._row_to_entry[level]
            weight_bonus = np.array(
                [entries[row_map[i]].weight * 0.002 for i in range(len(row_map))],
                dtype=np.float32,
            )
            composite_scores = cos_scores + weight_bonus

            row_idx = int(np.argmax(composite_scores))
            composite = float(composite_scores[row_idx])

            if composite > best_score:
                best_score = composite
                best_level = level
                entry_idx = self._row_to_entry[level][row_idx]
                best_entry = self._anchors[level][entry_idx]

        confidence = max(0.0, min(1.0, best_score))
        en = best_entry.phrase_en if best_entry else ""
        hi = best_entry.phrase_hi if best_entry else ""
        return best_level, confidence, en, hi
