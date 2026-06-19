# ASHA Voice-based Clinical Triage Assistant

## 🔹 Basic Features
* **Voice-Based Symptom Logging:** ASHA workers simply press a button and speak the patient's symptoms instead of typing into complex forms.
* **Smart Clinical Confirmation:** The system extracts medical concepts from the speech and asks simple "Yes/No" follow-up questions to verify symptoms (including a mandatory safety-net question).
* **Automated Triage Engine:** Automatically categorizes the patient into **RED** (Emergency), **YELLOW** (Urgent), or **GREEN** (Routine) based on verified symptoms, patient age, and duration of illness.
* **Referral Slip Generation:** Instantly creates a printable/shareable PDF triage slip to hand over to the patient for hospital visits.
* **Multilingual Interface:** The entire UI dynamically switches between Hindi, Marathi, and English to suit the worker's preference.

---

## 🚀 Special Features
* **100% Offline Architecture:** Designed specifically to function flawlessly in "Airplane Mode" with absolutely zero internet connectivity required.
* **On-Device Speech-to-Text (Whisper.cpp):** Integrates the localized Whisper `ggml-tiny` model via FFI to transcribe multilingual audio locally on the phone.
* **On-Device Semantic NLP (TFLite):** Uses a highly-compressed `MiniLM-L6-v2` TensorFlow Lite model to mathematically map spoken words to standard clinical anchors (e.g., mapping "chest is hurting badly" to "Chest pain").
* **Native Voice Output (TTS):** The app reads out questions, instructions, and triage results in the local language, assisting workers with lower reading literacy.
* **Epidemic Alert System:** Continuously monitors recent local offline scans. If a sudden cluster of specific high-risk symptoms is detected (e.g., multiple fever/rash cases in 48 hours), it triggers a local epidemic warning.
* **High-Risk Pregnancy Tracker:** A dedicated module for tracking maternal danger signs with distinct clinical anchors.
* **Follow-up Tracker:** Allows the ASHA worker to manage pending referrals, checking off when patients reach the hospital, receive treatment, and return home.
* **Optical Data Sync (QR Share):** Allows ASHA workers to securely sync their local triage data to an ANM (Auxiliary Nurse Midwife) Supervisor by generating offline QR codes—bypassing the need for Wi-Fi or Bluetooth.

---

## ⭐ Unique Selling Points (USPs)
1. **True Zero-Connectivity Design:** While most healthcare apps fail in remote Indian villages due to poor networks, this app’s AI models are fully embedded within the APK, guaranteeing uninterrupted service anywhere.
2. **Voice-First, Low-Friction UX:** Replaces exhaustive, intimidating 50-field medical questionnaires with a simple, conversational audio interface that matches the natural workflow of a community health worker.
3. **Absolute Data Privacy:** Because all AI transcription and NLP processing occurs locally on the silicon of the smartphone, sensitive patient medical data and voice recordings never hit the cloud.
4. **Hardware Optimized for the Field:** The combination of a 75MB Whisper model and a lightweight TFLite model ensures that cutting-edge AI runs smoothly even on the low-end, budget Android smartphones typically distributed to ASHA workers.
