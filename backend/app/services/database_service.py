from datetime import datetime

import aiosqlite

from app.config import DB_PATH
from app.models.session import SessionCreate, SessionResponse
from app.models.triage_result import TriageLevel


class DatabaseService:
    async def init(self) -> None:
        DB_PATH.parent.mkdir(parents=True, exist_ok=True)
        async with aiosqlite.connect(DB_PATH) as db:
            await db.execute(
                """
                CREATE TABLE IF NOT EXISTS sessions (
                    id TEXT PRIMARY KEY,
                    started_at TEXT NOT NULL,
                    completed_at TEXT,
                    transcript TEXT,
                    level TEXT,
                    confidence REAL,
                    matched_anchor TEXT
                )
                """
            )
            await db.commit()

    async def save_session(self, session: SessionCreate) -> SessionResponse:
        async with aiosqlite.connect(DB_PATH) as db:
            await db.execute(
                """
                INSERT OR REPLACE INTO sessions
                (id, started_at, completed_at, transcript, level, confidence, matched_anchor)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    session.id,
                    session.started_at.isoformat(),
                    session.completed_at.isoformat() if session.completed_at else None,
                    session.transcript,
                    session.level.value if session.level else None,
                    session.confidence,
                    session.matched_anchor,
                ),
            )
            await db.commit()
        return SessionResponse(**session.model_dump())

    async def get_all_sessions(self) -> list[SessionResponse]:
        async with aiosqlite.connect(DB_PATH) as db:
            db.row_factory = aiosqlite.Row
            cursor = await db.execute(
                "SELECT * FROM sessions ORDER BY started_at DESC"
            )
            rows = await cursor.fetchall()

        sessions: list[SessionResponse] = []
        for row in rows:
            level = row["level"]
            sessions.append(
                SessionResponse(
                    id=row["id"],
                    started_at=datetime.fromisoformat(row["started_at"]),
                    completed_at=datetime.fromisoformat(row["completed_at"])
                    if row["completed_at"]
                    else None,
                    transcript=row["transcript"],
                    level=TriageLevel(level) if level else None,
                    confidence=row["confidence"],
                    matched_anchor=row["matched_anchor"],
                )
            )
        return sessions
