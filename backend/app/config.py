from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
ASSETS_DIR = BASE_DIR / "assets"
ANCHORS_PATH = ASSETS_DIR / "anchors" / "clinical_anchors.json"
DB_PATH = BASE_DIR / "data" / "asha_triage.db"
EMBEDDING_MODEL = "all-MiniLM-L6-v2"
