# ASHA Triage — Backend

FastAPI server handling triage classification, embeddings, and session storage.

## Run

```powershell
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Endpoints

- `GET /api/health`
- `POST /api/triage/classify` — body: `{ "transcript": "..." }`
- `POST /api/sessions` — save session
- `GET /api/sessions` — list sessions

## Assets

- `assets/anchors/clinical_anchors.json` — red/yellow/green anchor phrases
- SQLite DB created at `data/asha_triage.db` on first run
