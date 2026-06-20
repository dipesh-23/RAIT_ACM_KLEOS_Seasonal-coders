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
    'type_manually': {
      'hi': 'इसके बजाय टाइप करें',
      'en': 'Type instead',
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

    // ── Dashboard Screen ───────────────────────────────────────────────
    'performance_dashboard': {
      'hi': 'प्रदर्शन डैशबोर्ड',
      'en': 'Performance Dashboard',
    },
    'today': {
      'hi': 'आज',
      'en': 'Today',
    },
    'this_week': {
      'hi': 'इस हफ्ते',
      'en': 'This Week',
    },
    'this_month': {
      'hi': 'इस महीने',
      'en': 'This Month',
    },
    'total_patients_card': {
      'hi': 'कुल मरीज़',
      'en': 'Total Patients',
    },
    'immediate_referral': {
      'hi': 'तुरंत रेफर',
      'en': 'Immediate Referral',
    },
    'today_referral': {
      'hi': 'आज रेफर',
      'en': 'Today Referral',
    },
    'local_treatment': {
      'hi': 'स्थानीय उपचार',
      'en': 'Local Treatment',
    },
    'last_7_days': {
      'hi': 'पिछले 7 दिन',
      'en': 'Last 7 Days',
    },
    'referral_slip': {
      'hi': 'रेफरल स्लिप',
      'en': 'Referral Slip',
    },
    'pending_followup': {
      'hi': 'पेंडिंग फॉलो-अप',
      'en': 'Pending Follow-up',
    },
    'most_common_symptom': {
      'hi': 'सबसे आम लक्षण:',
      'en': 'Most Common Symptom:',
    },
    'generate_monthly_report': {
      'hi': '📄  मासिक रिपोर्ट बनाएं',
      'en': '📄  Generate Monthly Report',
    },

    // ── Epidemic Alert Screen ──────────────────────────────────────────
    'epidemic_alert': {
      'hi': 'एपिडेमिक अलर्ट',
      'en': 'Epidemic Alert',
    },
    'informed_anm': {
      'hi': '📞  ANM को सूचित किया',
      'en': '📞  Informed ANM',
    },
    'no_unusual_pattern': {
      'hi': 'कोई असामान्य पैटर्न नहीं',
      'en': 'No unusual pattern',
    },
    'alert_history': {
      'hi': 'पिछले अलर्ट',
      'en': 'Alert History',
    },
    'no_previous_alerts': {
      'hi': 'कोई पिछला अलर्ट नहीं है',
      'en': 'No previous alerts',
    },
    'ok_btn': {
      'hi': 'ठीक है',
      'en': 'OK',
    },

    // ── Pregnancy Tracker Screen ───────────────────────────────────────
    'pregnancy_tracker': {
      'hi': 'गर्भावस्था ट्रैकर',
      'en': 'Pregnancy Tracker',
    },
    'patients': {
      'hi': 'मरीज़',
      'en': 'Patients',
    },
    'new_patient_tab': {
      'hi': 'नई मरीज़',
      'en': 'New Patient',
    },
    'no_patients_found': {
      'hi': 'कोई मरीज़ नहीं',
      'en': 'No patients found',
    },
    'unknown': {
      'hi': 'अज्ञात',
      'en': 'Unknown',
    },
    'normal': {
      'hi': 'सामान्य',
      'en': 'Normal',
    },
    'high_risk': {
      'hi': 'उच्च जोखिम',
      'en': 'High Risk',
    },
    'medium_risk': {
      'hi': 'मध्यम जोखिम',
      'en': 'Medium Risk',
    },
    'week_prefix': {
      'hi': 'सप्ताह',
      'en': 'Week',
    },
    'delivery_date': {
      'hi': 'प्रसव तिथि:',
      'en': 'Delivery Date:',
    },
    'days_left': {
      'hi': 'दिन बाकी',
      'en': 'days left',
    },
    'patient_name_optional': {
      'hi': 'मरीज़ का नाम (वैकल्पिक)',
      'en': 'Patient name (optional)',
    },
    'age': {
      'hi': 'उम्र',
      'en': 'Age',
    },
    'lmp_date_label': {
      'hi': 'आखिरी माहवारी की तारीख',
      'en': 'Last Menstrual Period',
    },
    'select_date': {
      'hi': 'तारीख चुनें',
      'en': 'Select Date',
    },
    'create_profile': {
      'hi': 'प्रोफाइल बनाएं',
      'en': 'Create Profile',
    },
    'danger_signs': {
      'hi': 'खतरे के संकेत',
      'en': 'Danger Signs',
    },
    'notes_optional': {
      'hi': 'Notes (Optional)',
      'en': 'Notes (Optional)',
    },
    'record_visit': {
      'hi': 'विज़िट दर्ज करें',
      'en': 'Record Visit',
    },

    // ── Followup Tracker Screen ────────────────────────────────────────
    'followup': {
      'hi': 'फॉलो-अप',
      'en': 'Follow-up',
    },
    'referred': {
      'hi': 'रेफर',
      'en': 'Referred',
    },
    'reached': {
      'hi': 'पहुंचे',
      'en': 'Reached',
    },
    'treated': {
      'hi': 'इलाज',
      'en': 'Treated',
    },
    'returned': {
      'hi': 'वापसी',
      'en': 'Returned',
    },
    'pending': {
      'hi': 'पेंडिंग',
      'en': 'Pending',
    },
    'all': {
      'hi': 'सभी',
      'en': 'All',
    },
    'all_followups_complete': {
      'hi': 'सभी फॉलो-अप पूरे हैं',
      'en': 'All follow-ups complete',
    },
    'followup_complete_check': {
      'hi': '✓ फॉलो-अप पूरा',
      'en': '✓ Follow-up Complete',
    },
    'reached_hospital_q': {
      'hi': '🏥  अस्पताल पहुंचे?',
      'en': '🏥  Reached Hospital?',
    },
    'treatment_received_q': {
      'hi': '💊  इलाज हुआ?',
      'en': '💊  Treatment Received?',
    },
    'returned_home_q': {
      'hi': '🏠  घर वापसी?',
      'en': '🏠  Returned Home?',
    },

    // ── QR Sync Screen ─────────────────────────────────────────────────
    'qr_sync': {
      'hi': 'QR सिंक',
      'en': 'QR Sync',
    },
    'share_data': {
      'hi': 'डेटा भेजें',
      'en': 'Share Data',
    },
    'receive_data': {
      'hi': 'डेटा पाएं',
      'en': 'Receive Data',
    },
    'which_period': {
      'hi': 'किस अवधि का डेटा?',
      'en': 'Which period?',
    },
    'show_qr_to_anm': {
      'hi': 'ANM को यह QR दिखाएं',
      'en': 'Show this QR to ANM',
    },
    'valid_30_mins': {
      'hi': 'QR 30 मिनट के लिए मान्य है',
      'en': 'Valid for 30 mins',
    },
    'scan_qr': {
      'hi': '📷 स्कैन करें',
      'en': '📷 Scan QR',
    },
    'data_received': {
      'hi': '✓ डेटा प्राप्त हुआ',
      'en': '✓ Data Received',
    },
    'save_report': {
      'hi': '📄  रिपोर्ट सेव करें',
      'en': '📄  Save Report',
    },
    'scan_again': {
      'hi': '🔄  दोबारा स्कैन करें',
      'en': '🔄  Scan Again',
    },
    'invalid_qr': {
      'hi': '❌ अमान्य QR',
      'en': '❌ Invalid QR Code',
    },
  };
}
