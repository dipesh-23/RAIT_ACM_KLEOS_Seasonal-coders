# ASHA Triage — Frontend

Flutter mobile app for ASHA workers. Handles voice capture, UI flow, and TTS; calls the backend for triage classification.

## Run

```powershell
flutter pub get
flutter run
```

Set backend URL for physical devices:

```powershell
flutter run --dart-define=API_BASE_URL=http://YOUR_PC_IP:8000
```

## Manual assets

Add to `assets/audio/`:
- `red_hindi.mp3`
- `yellow_hindi.mp3`
- `green_hindi.mp3`
