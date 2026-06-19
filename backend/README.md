# ASHA Triage — Backend

Python FastAPI server that mirrors the Flutter app's triage logic.  
Use for **demo, testing, and web access** during the hackathon.

## Structure

```
backend/
├── main.py                  # FastAPI app — all endpoints
├── clinical_anchors.json    # 19 clinical concepts (same as frontend)
├── requirements.txt
├── static/
│   └── index.html           # Web demo UI
└── scripts/
    └── convert_model.py     # Converts MiniLM to TFLite for the app
```

## Setup

```bash
cd backend
python -m venv venv
venv\Scripts\activate          # Windows
pip install -r requirements.txt
```

## Run

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

- **Web Demo UI**: http://localhost:8000
- **Swagger Docs**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/health

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Server + model status |
| POST | `/analyze` | Transcript → detected concepts (top 3) |
| POST | `/triage` | Confirmed concepts → RED/YELLOW/GREEN |
| POST | `/full-triage` | Single-shot: transcript → triage result |

## Demo Test Cases

**RED**
```json
POST /full-triage
{"transcript":"पांच साल का बच्चा, सांस लेने में बहुत तकलीफ","age_group":"CHILD","duration":"TWO_THREE_DAYS"}
```

**YELLOW**
```json
POST /full-triage
{"transcript":"महिला, गर्भवती, तीन दिन से उल्टी, कमज़ोरी","age_group":"ADULT","duration":"TWO_THREE_DAYS"}
```

**GREEN**
```json
POST /full-triage
{"transcript":"बड़ा आदमी, आज से हल्का बुखार, सर्दी जुकाम","age_group":"ADULT","duration":"TODAY"}
```

## Convert MiniLM to TFLite (for the Flutter app)

```bash
pip install tensorflow
python scripts/convert_model.py
```

Output files go directly to `frontend/assets/model/`.

## Safety Rules

- No disease names in any response
- No medication names in any response  
- Output is triage referral guidance only
- `hindi_reason` contains referral instruction, never a diagnosis
