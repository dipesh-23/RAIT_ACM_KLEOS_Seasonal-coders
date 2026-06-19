// ===== FILE: lib/utils/app_strings.dart =====

/// Monolingual string lookup for Hindi ('hi') and English ('en').
/// Fallback chain: requested lang → 'hi' → key itself.
class AppStrings {
  AppStrings._();

  static String get(String key, String lang) {
    return _strings[key]?[lang] ?? _strings[key]?['hi'] ?? key;
  }

  static const Map<String, Map<String, String>> _strings = {
    // ── Session start screen ────────────────────────────────────────────
    'fill_all_options': {
      'hi': 'कृपया सभी विकल्प चुनें',
      'en': 'Please select all options',
    },
    'hello': {
      'hi': 'नमस्ते,',
      'en': 'Hello,',
    },
    'asha_worker': {
      'hi': 'ASHA कार्यकर्ता',
      'en': 'ASHA Worker',
    },
    'new_patient_triage': {
      'hi': 'नया मरीज ट्राइएज शुरू करें',
      'en': 'Start New Patient Triage',
    },
    'patient_details_title': {
      'hi': 'मरीज का विवरण',
      'en': 'Patient Details',
    },
    'patient_name_label': {
      'hi': 'मरीज का नाम',
      'en': 'Patient Name',
    },
    'patient_name_hint': {
      'hi': 'नाम दर्ज करें',
      'en': 'Enter Name',
    },
    'patient_contact_label': {
      'hi': 'मोबाइल नंबर',
      'en': 'Mobile Number',
    },
    'patient_contact_hint': {
      'hi': '10 अंकों का नंबर',
      'en': '10-digit number',
    },
    'invalid_contact': {
      'hi': 'कृपया सही 10-अंकों का नंबर दर्ज करें',
      'en': 'Please enter a valid 10-digit number',
    },
    'patient_gender_label': {
      'hi': 'लिंग',
      'en': 'Gender',
    },
    'gender_male': {
      'hi': 'पुरुष',
      'en': 'Male',
    },
    'gender_female': {
      'hi': 'महिला',
      'en': 'Female',
    },
    'worker_name_label': {
      'hi': 'कार्यकर्ता का नाम दर्ज करें',
      'en': 'Enter Worker Name',
    },
    'worker_name_hint': {
      'hi': 'यहाँ नाम लिखें...',
      'en': 'Enter name here...',
    },
    'patient_age_label': {
      'hi': 'मरीज की आयु वर्ग',
      'en': 'Patient Age Group',
    },
    'symptom_duration_label': {
      'hi': 'लक्षण कितने दिन से',
      'en': 'Symptom Duration',
    },
    'today_patients': {
      'hi': 'आज के मरीज',
      'en': 'Today\'s Patients',
    },
    'critical_cases': {
      'hi': 'गंभीर केस',
      'en': 'Critical Cases',
    },
    'normal_cases': {
      'hi': 'सामान्य',
      'en': 'Normal',
    },
    'start_btn': {
      'hi': 'शुरू करें  →',
      'en': 'Start  →',
    },
    'asha_triage': {
      'hi': 'ASHA ट्राइएज',
      'en': 'ASHA Triage',
    },

    // ── Voice screen ────────────────────────────────────────────────────
    'voice_screen_title': {
      'hi': 'लक्षण रिकॉर्ड करें',
      'en': 'Record Symptoms',
    },
    'speak_instruction': {
      'hi': 'बोलें —',
      'en': 'Speak —',
    },
    'describe_symptoms': {
      'hi': 'मरीज के लक्षण बताएं',
      'en': 'Describe patient\'s symptoms',
    },
    'live_transcription': {
      'hi': 'लाइव ट्रांसक्रिप्शन',
      'en': 'Live Transcription',
    },
    'words_placeholder': {
      'hi': 'यहाँ आपकी बातें दिखेंगी...',
      'en': 'Your words will appear here...',
    },
    'press_mic': {
      'hi': 'माइक दबाएं और लक्षण बोलें',
      'en': 'Press mic and describe symptoms',
    },
    'listening': {
      'hi': 'सुन रहा है...',
      'en': 'Listening...',
    },
    'processing': {
      'hi': 'समझ रहा है...',
      'en': 'Processing...',
    },
    'rerecord': {
      'hi': 'दोबारा बोलें',
      'en': 'Record again',
    },
    'continue_btn': {
      'hi': 'आगे बढ़ें',
      'en': 'Continue',
    },

    // ── Transcription screen ─────────────────────────────────────────────
    'heard_label': {
      'hi': 'यह सुना गया:',
      'en': 'This was heard:',
    },
    'check_patient_options': {
      'hi': 'इसमें पेशेंट के लिए विकल्प की जाँच करो!',
      'en': 'Check options for the patient here!',
    },
    'audio_transcription': {
      'hi': 'ऑडियो ट्रांसक्रिप्शन',
      'en': 'Audio Transcription',
    },
    'detected_symptoms': {
      'hi': 'पहचाने गए लक्षण',
      'en': 'Detected Symptoms',
    },
    'ai_confidence_score': {
      'hi': 'AI विश्वास स्कोर',
      'en': 'AI Confidence Score',
    },
    'is_this_correct': {
      'hi': 'क्या यह सही है?',
      'en': 'Is this correct?',
    },
    'analysing': {
      'hi': 'विश्लेषण हो रहा है...',
      'en': 'Analysing...',
    },
    'correct_continue': {
      'hi': 'सही है, आगे बढ़ें',
      'en': 'Correct, continue',
    },

    // ── Confirmation screen ──────────────────────────────────────────────
    'question_label': {
      'hi': 'प्रश्न',
      'en': 'Question',
    },
    'question_prefix': {
      'hi': 'प्रश्न',
      'en': 'Question',
    },
    'pay_attention': {
      'hi': 'इसमें ध्यान दें और सही विकल्प चुनें',
      'en': 'Pay attention and select correct option',
    },
    'yes_severe': {
      'hi': 'हाँ, गंभीर है',
      'en': 'Yes, severe',
    },
    'no_normal': {
      'hi': 'नहीं, सामान्य है',
      'en': 'No, normal',
    },
    // ── Result screen ──────────────────────────────────────────────
    'transcription_title': {
      'hi': 'ट्रांसक्रिप्शन',
      'en': 'Transcription',
    },
    'asha_advice': {
      'hi': 'ASHA सलाह',
      'en': 'ASHA Advice',
    },
    'listen_audio': {
      'hi': 'आवाज में सुनें',
      'en': 'Listen in Audio',
    },
    'create_referral_slip': {
      'hi': 'रेफरल स्लिप बनाएं',
      'en': 'Create Referral Slip',
    },
    'new_patient': {
      'hi': 'नया मरीज →',
      'en': 'New Patient →',
    },
    'yes_btn': {
      'hi': '✓  हाँ',
      'en': '✓  Yes',
    },
    'no_btn': {
      'hi': '✗  नहीं',
      'en': '✗  No',
    },
    'safety_net_q': {
      'hi': 'क्या मरीज की हालत आपको बहुत गंभीर लग रही है?',
      'en': 'Does the patient appear very serious to you?',
    },

    // ── Errors ───────────────────────────────────────────────────────────
    'mic_error': {
      'hi': 'माइक काम नहीं कर रहा। दोबारा कोशिश करें।',
      'en': 'Microphone not working. Please try again.',
    },
    'analysis_error': {
      'hi': 'विश्लेषण विफल हुआ। दोबारा बोलें।',
      'en': 'Analysis failed. Please speak again.',
    },
  };
}
