// ===== FILE: lib/utils/app_strings.dart =====

/// Trilingual string lookup for Hindi ('hi'), Marathi ('mr'), English ('en').
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
      'mr': 'कृपया सर्व पर्याय निवडा',
      'en': 'Please select all options',
    },
    'hello': {
      'hi': 'नमस्ते,',
      'mr': 'नमस्कार,',
      'en': 'Hello,',
    },
    'asha_worker': {
      'hi': 'ASHA कार्यकर्ता',
      'mr': 'ASHA कार्यकर्ता',
      'en': 'ASHA Worker',
    },
    'new_patient_triage': {
      'hi': 'नया मरीज ट्राइएज शुरू करें',
      'mr': 'नवीन रुग्ण ट्राइएज सुरू करा',
      'en': 'Start New Patient Triage',
    },
    'patient_details_title': {
      'hi': 'मरीज का विवरण',
      'mr': 'रुग्णाचा तपशील',
      'en': 'Patient Details',
    },
    'patient_name_label': {
      'hi': 'मरीज का नाम',
      'mr': 'रुग्णाचे नाव',
      'en': 'Patient Name',
    },
    'patient_name_hint': {
      'hi': 'नाम दर्ज करें',
      'mr': 'नाव प्रविष्ट करा',
      'en': 'Enter Name',
    },
    'patient_contact_label': {
      'hi': 'मोबाइल नंबर',
      'mr': 'मोबाईल क्रमांक',
      'en': 'Mobile Number',
    },
    'patient_contact_hint': {
      'hi': '10 अंकों का नंबर',
      'mr': '१० अंकी क्रमांक',
      'en': '10-digit number',
    },
    'invalid_contact': {
      'hi': 'कृपया सही 10-अंकों का नंबर दर्ज करें',
      'mr': 'कृपया योग्य १०-अंकी क्रमांक प्रविष्ट करा',
      'en': 'Please enter a valid 10-digit number',
    },
    'patient_gender_label': {
      'hi': 'लिंग',
      'mr': 'लिंग',
      'en': 'Gender',
    },
    'gender_male': {
      'hi': 'पुरुष',
      'mr': 'पुरुष',
      'en': 'Male',
    },
    'gender_female': {
      'hi': 'महिला',
      'mr': 'स्त्री',
      'en': 'Female',
    },
    'worker_name_label': {
      'hi': 'कार्यकर्ता का नाम दर्ज करें',
      'mr': 'कार्यकर्त्याचे नाव प्रविष्ट करा',
      'en': 'Enter Worker Name',
    },
    'worker_name_hint': {
      'hi': 'यहाँ नाम लिखें...',
      'mr': 'येथे नाव लिहा...',
      'en': 'Enter name here...',
    },
    'patient_age_label': {
      'hi': 'मरीज की आयु वर्ग',
      'mr': 'रुग्णाचा वयोगट',
      'en': 'Patient Age Group',
    },
    'symptom_duration_label': {
      'hi': 'लक्षण कितने दिन से',
      'mr': 'लक्षणे किती दिवसांपासून',
      'en': 'Symptom Duration',
    },
    'today_patients': {
      'hi': 'आज के मरीज',
      'mr': 'आजचे रुग्ण',
      'en': 'Today\'s Patients',
    },
    'critical_cases': {
      'hi': 'गंभीर केस',
      'mr': 'गंभीर प्रकरणे',
      'en': 'Critical Cases',
    },
    'normal_cases': {
      'hi': 'सामान्य',
      'mr': 'सामान्य',
      'en': 'Normal',
    },
    'start_btn': {
      'hi': 'शुरू करें  →',
      'mr': 'सुरू करा  →',
      'en': 'Start  →',
    },
    'asha_triage': {
      'hi': 'ASHA ट्राइएज',
      'mr': 'ASHA ट्राइएज',
      'en': 'ASHA Triage',
    },

    // ── Voice screen ────────────────────────────────────────────────────
    'voice_screen_title': {
      'hi': 'लक्षण रिकॉर्ड करें',
      'mr': 'लक्षणे रेकॉर्ड करा',
      'en': 'Record Symptoms',
    },
    'speak_instruction': {
      'hi': 'बोलें —',
      'mr': 'बोला —',
      'en': 'Speak —',
    },
    'describe_symptoms': {
      'hi': 'मरीज के लक्षण बताएं',
      'mr': 'रुग्णाची लक्षणे सांगा',
      'en': 'Describe patient\'s symptoms',
    },
    'live_transcription': {
      'hi': 'लाइव ट्रांसक्रिप्शन',
      'mr': 'थेट लिप्यंतरण',
      'en': 'Live Transcription',
    },
    'words_placeholder': {
      'hi': 'यहाँ आपकी बातें दिखेंगी...',
      'mr': 'तुमचे बोलणे येथे दिसेल...',
      'en': 'Your words will appear here...',
    },
    'press_mic': {
      'hi': 'माइक दबाएं और लक्षण बोलें',
      'mr': 'मायक्रोफोन दाबा आणि लक्षणे सांगा',
      'en': 'Press mic and describe symptoms',
    },
    'listening': {
      'hi': 'सुन रहा है...',
      'mr': 'ऐकत आहे...',
      'en': 'Listening...',
    },
    'processing': {
      'hi': 'समझ रहा है...',
      'mr': 'समजत आहे...',
      'en': 'Processing...',
    },
    'rerecord': {
      'hi': 'दोबारा बोलें',
      'mr': 'पुन्हा बोला',
      'en': 'Record again',
    },
    'continue_btn': {
      'hi': 'आगे बढ़ें',
      'mr': 'पुढे जा',
      'en': 'Continue',
    },

    // ── Transcription screen ─────────────────────────────────────────────
    'heard_label': {
      'hi': 'यह सुना गया:',
      'mr': 'हे ऐकले गेले:',
      'en': 'This was heard:',
    },
    'check_patient_options': {
      'hi': 'इसमें पेशेंट के लिए विकल्प की जाँच करो!',
      'mr': 'यामध्ये रुग्णासाठी पर्यायांची तपासणी करा!',
      'en': 'Check options for the patient here!',
    },
    'audio_transcription': {
      'hi': 'ऑडियो ट्रांसक्रिप्शन',
      'mr': 'ऑडिओ लिप्यंतरण',
      'en': 'Audio Transcription',
    },
    'detected_symptoms': {
      'hi': 'पहचाने गए लक्षण',
      'mr': 'ओळखलेली लक्षणे',
      'en': 'Detected Symptoms',
    },
    'ai_confidence_score': {
      'hi': 'AI विश्वास स्कोर',
      'mr': 'AI विश्वास स्कोअर',
      'en': 'AI Confidence Score',
    },
    'is_this_correct': {
      'hi': 'क्या यह सही है?',
      'mr': 'हे बरोबर आहे का?',
      'en': 'Is this correct?',
    },
    'analysing': {
      'hi': 'विश्लेषण हो रहा है...',
      'mr': 'विश्लेषण होत आहे...',
      'en': 'Analysing...',
    },
    'correct_continue': {
      'hi': 'सही है, आगे बढ़ें',
      'mr': 'बरोबर आहे, पुढे जा',
      'en': 'Correct, continue',
    },

    // ── Confirmation screen ──────────────────────────────────────────────
    'question_label': {
      'hi': 'प्रश्न',
      'mr': 'प्रश्न',
      'en': 'Question',
    },
    'question_prefix': {
      'hi': 'प्रश्न',
      'mr': 'प्रश्न',
      'en': 'Question',
    },
    'pay_attention': {
      'hi': 'इसमें ध्यान दें और सही विकल्प चुनें',
      'mr': 'याकडे लक्ष द्या आणि योग्य पर्याय निवडा',
      'en': 'Pay attention and select correct option',
    },
    'yes_severe': {
      'hi': 'हाँ, गंभीर है',
      'mr': 'होय, गंभीर आहे',
      'en': 'Yes, severe',
    },
    'no_normal': {
      'hi': 'नहीं, सामान्य है',
      'mr': 'नाही, सामान्य आहे',
      'en': 'No, normal',
    },
    // ── Result screen ──────────────────────────────────────────────
    'transcription_title': {
      'hi': 'ट्रांसक्रिप्शन',
      'mr': 'लिप्यंतरण',
      'en': 'Transcription',
    },
    'asha_advice': {
      'hi': 'ASHA सलाह',
      'mr': 'ASHA सल्ला',
      'en': 'ASHA Advice',
    },
    'listen_audio': {
      'hi': 'आवाज में सुनें',
      'mr': 'आवाजात ऐका',
      'en': 'Listen in Audio',
    },
    'create_referral_slip': {
      'hi': 'रेफरल स्लिप बनाएं',
      'mr': 'रेफरल स्लिप बनवा',
      'en': 'Create Referral Slip',
    },
    'new_patient': {
      'hi': 'नया मरीज →',
      'mr': 'नवीन रुग्ण →',
      'en': 'New Patient →',
    },
    'yes_btn': {
      'hi': '✓  हाँ',
      'mr': '✓  होय',
      'en': '✓  Yes',
    },
    'no_btn': {
      'hi': '✗  नहीं',
      'mr': '✗  नाही',
      'en': '✗  No',
    },
    'safety_net_q': {
      'hi': 'क्या मरीज की हालत आपको बहुत गंभीर लग रही है?',
      'mr': 'रुग्णाची स्थिती तुम्हाला खूप गंभीर वाटते का?',
      'en': 'Does the patient appear very serious to you?',
    },

    // ── Errors ───────────────────────────────────────────────────────────
    'mic_error': {
      'hi': 'माइक काम नहीं कर रहा। दोबारा कोशिश करें।',
      'mr': 'मायक्रोफोन काम करत नाही। पुन्हा प्रयत्न करा।',
      'en': 'Microphone not working. Please try again.',
    },
    'analysis_error': {
      'hi': 'विश्लेषण विफल हुआ। दोबारा बोलें।',
      'mr': 'विश्लेषण अयशस्वी झाले. पुन्हा बोला.',
      'en': 'Analysis failed. Please speak again.',
    },
  };
}
