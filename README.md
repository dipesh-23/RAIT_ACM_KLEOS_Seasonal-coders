# ASHA Triage: Intelligent Offline Health Screening

ASHA Triage is a highly advanced, **100% offline** Flutter application designed specifically for ASHA (Accredited Social Health Activist) workers in rural India. It empowers frontline healthcare workers to quickly and accurately triage patients using voice, text, or an interactive body map, without requiring any internet connection.

---

## 🌟 Unique Selling Propositions (USPs)

1. **Zero Internet Required (100% Offline)**
   All Speech-to-Text (STT), Natural Language Processing (NLP), data storage, and triage logic run entirely locally on the device. Perfect for remote rural clinics with zero connectivity.
2. **Tri-lingual Support**
   Natively supports **Hindi, Marathi, and English**. The UI, voice recognition, and Text-to-Speech all switch dynamically based on the worker's preference.
3. **Advanced Offline NLP Triage Engine**
   Uses a custom-built, on-device NLP matching engine that compares transcribed speech against a robust dataset (`clinical_anchors.json`) of over 40 distinct medical concepts to accurately assign RED (Emergency), YELLOW (Observation), or GREEN (Normal) urgency levels.
4. **Interactive "Body Tap" Interface**
   A futuristic, premium, animated human silhouette that allows users to simply tap on body regions to select symptoms, designed specifically as a highly intuitive fallback for users who prefer not to use voice.
5. **Hardware-Level Audio DSP**
   Utilizes deep hardware integration for Automatic Gain Control (AGC), Acoustic Echo Cancellation (AEC), and Active Noise Suppression, ensuring highly accurate voice transcriptions even in noisy rural environments.

---

## 🛠️ Key Features & Workflows

### 1. Worker Dashboard
- **Component:** `SessionStartScreen`
- **Workflow:** The ASHA worker opens the app to a dashboard displaying their real-time daily statistics (Today's Patients, Critical Cases, Normal Cases). From here, they can register a new patient by entering their name, age, gender, and symptom duration.

### 2. Multi-Modal Input (Voice & Body)
- **Component:** `VoiceScreen` & `BodyTapScreen`
- **Workflow:** 
  - **Voice:** The worker presses the microphone. The app utilizes `stt_service.dart` (powered by Vosk) and the device's hardware DSP to capture clean audio, converting it to text instantly.
  - **Body Tap:** The worker taps the body icon to open an interactive silhouette. They can select specific body parts (e.g., Chest, Head) and choose from a localized list of symptoms.
  - **Merge:** The app seamlessly merges both manual Body Tap selections and AI-extracted voice concepts into a single patient profile.

### 3. NLP Triage Engine
- **Component:** `TriageEngine` & `EmbeddingService`
- **Workflow:** The recorded text is fed into the offline engine. It uses string similarity algorithms and medical anchor matching to detect clinical concepts (e.g., "तेज बुखार" -> High Fever). It then calculates a triage score based on the severity weights of the detected concepts.

### 4. Interactive Confirmation & TTS
- **Component:** `ConfirmationScreen` & `TtsService`
- **Workflow:** The engine may identify symptoms that require verification (e.g., "Are they unconscious?"). The app asks the worker these questions dynamically. `flutter_tts` reads these questions out loud in Hindi or Marathi.

### 5. Final Result & Referral Generation
- **Component:** `ResultScreen` & `ReferralScreen`
- **Workflow:** Based on the final score, the app flashes RED, YELLOW, or GREEN. If the patient is RED, the app generates an instant Referral Slip with a QR Code (`qr_flutter`) that can be scanned by the destination hospital, seamlessly transferring the offline data.

---

## 📦 Technical Components Used

| Component | Technology | Purpose |
| :--- | :--- | :--- |
| **Frontend Framework** | Flutter / Dart | Cross-platform UI rendering |
| **State Management** | `provider` | Manages `TriageProvider` state across complex navigation flows |
| **Offline Speech-to-Text** | `vosk_flutter` | Converts Hindi/Marathi/English audio to text entirely offline |
| **Audio Capture & DSP** | `record` (v5.0.4) | Captures PCM-16 audio and applies hardware Noise Suppression |
| **Offline Database** | `sqflite` | Stores all patient sessions, triage results, and worker stats locally |
| **Text-to-Speech** | `flutter_tts` | Reads questions and recommendations aloud to the worker |
| **QR Generation** | `qr_flutter` | Encodes critical patient triage data into an offline scannable QR code |
| **Visuals & Animations** | `CustomPainter`, `AnimationController` | Renders the complex glowing Body Tap interface and audio waveform Visualizers |

---

## 🚀 How to Run

1. Clone the repository.
2. Ensure you have the Vosk language models (Hindi, English) placed in `assets/vosk/`.
3. Run `flutter pub get` to install all dependencies.
4. Run `flutter run` on a physical Android device (Microphone hardware DSP requires a physical device for optimal performance).
