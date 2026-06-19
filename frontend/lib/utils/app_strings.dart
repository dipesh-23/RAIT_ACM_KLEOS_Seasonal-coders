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
    'yes': {
      'hi': 'हाँ',
      'mr': 'होय',
      'en': 'Yes',
    },
    'no': {
      'hi': 'नहीं',
      'mr': 'नाही',
      'en': 'No',
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

    // ── Dashboard Screen ───────────────────────────────────────────────
    'performance_dashboard': {
      'hi': 'प्रदर्शन डैशबोर्ड',
      'mr': 'कामगिरी डॅशबोर्ड',
      'en': 'Performance Dashboard',
    },
    'today': {
      'hi': 'आज',
      'mr': 'आज',
      'en': 'Today',
    },
    'this_week': {
      'hi': 'इस हफ्ते',
      'mr': 'या आठवड्यात',
      'en': 'This Week',
    },
    'this_month': {
      'hi': 'इस महीने',
      'mr': 'या महिन्यात',
      'en': 'This Month',
    },
    'total_patients_card': {
      'hi': 'कुल मरीज़',
      'mr': 'एकूण रुग्ण',
      'en': 'Total Patients',
    },
    'immediate_referral': {
      'hi': 'तुरंत रेफर',
      'mr': 'तात्काळ संदर्भ',
      'en': 'Immediate Referral',
    },
    'today_referral': {
      'hi': 'आज रेफर',
      'mr': 'आज संदर्भ',
      'en': 'Today Referral',
    },
    'local_treatment': {
      'hi': 'स्थानीय उपचार',
      'mr': 'स्थानिक उपचार',
      'en': 'Local Treatment',
    },
    'last_7_days': {
      'hi': 'पिछले 7 दिन',
      'mr': 'गेले 7 दिवस',
      'en': 'Last 7 Days',
    },
    'referral_slip': {
      'hi': 'रेफरल स्लिप',
      'mr': 'रेफरल स्लिप',
      'en': 'Referral Slip',
    },
    'pending_followup': {
      'hi': 'पेंडिंग फॉलो-अप',
      'mr': 'प्रलंबित पाठपुरावा',
      'en': 'Pending Follow-up',
    },
    'most_common_symptom': {
      'hi': 'सबसे आम लक्षण:',
      'mr': 'सर्वात सामान्य लक्षण:',
      'en': 'Most Common Symptom:',
    },
    'generate_monthly_report': {
      'hi': '📄  मासिक रिपोर्ट बनाएं',
      'mr': '📄  मासिक अहवाल तयार करा',
      'en': '📄  Generate Monthly Report',
    },

    // ── Epidemic Alert Screen ──────────────────────────────────────────
    'epidemic_alert': {
      'hi': 'एपिडेमिक अलर्ट',
      'mr': 'महामारी सूचना',
      'en': 'Epidemic Alert',
    },
    'informed_anm': {
      'hi': '📞  ANM को सूचित किया',
      'mr': '📞  ANM ला सूचित केले',
      'en': '📞  Informed ANM',
    },
    'no_unusual_pattern': {
      'hi': 'कोई असामान्य पैटर्न नहीं',
      'mr': 'कोणताही असामान्य नमुना नाही',
      'en': 'No unusual pattern',
    },
    'alert_history': {
      'hi': 'पिछले अलर्ट',
      'mr': 'मागील सूचना',
      'en': 'Alert History',
    },
    'no_previous_alerts': {
      'hi': 'कोई पिछला अलर्ट नहीं है',
      'mr': 'कोणतीही मागील सूचना नाही',
      'en': 'No previous alerts',
    },
    'ok_btn': {
      'hi': 'ठीक है',
      'mr': 'ठीक आहे',
      'en': 'OK',
    },

    // ── Pregnancy Tracker Screen ───────────────────────────────────────
    'pregnancy_tracker': {
      'hi': 'गर्भावस्था ट्रैकर',
      'mr': 'गर्भधारणा ट्रॅकर',
      'en': 'Pregnancy Tracker',
    },
    'patients': {
      'hi': 'मरीज़',
      'mr': 'रुग्ण',
      'en': 'Patients',
    },
    'new_patient_tab': {
      'hi': 'नई मरीज़',
      'mr': 'नवीन रुग्ण',
      'en': 'New Patient',
    },
    'no_patients_found': {
      'hi': 'कोई मरीज़ नहीं',
      'mr': 'कोणतेही रुग्ण आढळले नाहीत',
      'en': 'No patients found',
    },
    'unknown': {
      'hi': 'अज्ञात',
      'mr': 'अज्ञात',
      'en': 'Unknown',
    },
    'normal': {
      'hi': 'सामान्य',
      'mr': 'सामान्य',
      'en': 'Normal',
    },
    'high_risk': {
      'hi': 'उच्च जोखिम',
      'mr': 'उच्च धोका',
      'en': 'High Risk',
    },
    'medium_risk': {
      'hi': 'मध्यम जोखिम',
      'mr': 'मध्यम धोका',
      'en': 'Medium Risk',
    },
    'week_prefix': {
      'hi': 'सप्ताह',
      'mr': 'आठवडा',
      'en': 'Week',
    },
    'delivery_date': {
      'hi': 'प्रसव तिथि:',
      'mr': 'प्रसूतीची तारीख:',
      'en': 'Delivery Date:',
    },
    'days_left': {
      'hi': 'दिन बाकी',
      'mr': 'दिवस शिल्लक',
      'en': 'days left',
    },
    'patient_name_optional': {
      'hi': 'मरीज़ का नाम (वैकल्पिक)',
      'mr': 'रुग्णाचे नाव (पर्यायी)',
      'en': 'Patient name (optional)',
    },
    'age': {
      'hi': 'उम्र',
      'mr': 'वय',
      'en': 'Age',
    },
    'lmp_date_label': {
      'hi': 'आखिरी माहवारी की तारीख',
      'mr': 'शेवटची पाळी तारीख',
      'en': 'Last Menstrual Period',
    },
    'select_date': {
      'hi': 'तारीख चुनें',
      'mr': 'तारीख निवडा',
      'en': 'Select Date',
    },
    'create_profile': {
      'hi': 'प्रोफाइल बनाएं',
      'mr': 'प्रोफाइल तयार करा',
      'en': 'Create Profile',
    },
    'danger_signs': {
      'hi': 'खतरे के संकेत',
      'mr': 'धोक्याची चिन्हे',
      'en': 'Danger Signs',
    },
    'notes_optional': {
      'hi': 'Notes (Optional)',
      'mr': 'नोंदी (पर्यायी)',
      'en': 'Notes (Optional)',
    },
    'record_visit': {
      'hi': 'विज़िट दर्ज करें',
      'mr': 'भेट नोंदवा',
      'en': 'Record Visit',
    },

    // ── Followup Tracker Screen ────────────────────────────────────────
    'followup': {
      'hi': 'फॉलो-अप',
      'mr': 'पाठपुरावा',
      'en': 'Follow-up',
    },
    'referred': {
      'hi': 'रेफर',
      'mr': 'संदर्भित',
      'en': 'Referred',
    },
    'reached': {
      'hi': 'पहुंचे',
      'mr': 'पोहोचले',
      'en': 'Reached',
    },
    'treated': {
      'hi': 'इलाज',
      'mr': 'उपचार',
      'en': 'Treated',
    },
    'returned': {
      'hi': 'वापसी',
      'mr': 'परतले',
      'en': 'Returned',
    },
    'pending': {
      'hi': 'पेंडिंग',
      'mr': 'प्रलंबित',
      'en': 'Pending',
    },
    'all': {
      'hi': 'सभी',
      'mr': 'सर्व',
      'en': 'All',
    },
    'all_followups_complete': {
      'hi': 'सभी फॉलो-अप पूरे हैं',
      'mr': 'सर्व पाठपुरावा पूर्ण',
      'en': 'All follow-ups complete',
    },
    'followup_complete_check': {
      'hi': '✓ फॉलो-अप पूरा',
      'mr': '✓ पाठपुरावा पूर्ण',
      'en': '✓ Follow-up Complete',
    },
    'reached_hospital_q': {
      'hi': '🏥  अस्पताल पहुंचे?',
      'mr': '🏥  रुग्णालयात पोहोचले?',
      'en': '🏥  Reached Hospital?',
    },
    'treatment_received_q': {
      'hi': '💊  इलाज हुआ?',
      'mr': '💊  उपचार मिळाले?',
      'en': '💊  Treatment Received?',
    },
    'returned_home_q': {
      'hi': '🏠  घर वापसी?',
      'mr': '🏠  घरी परतले?',
      'en': '🏠  Returned Home?',
    },

    // ── QR Sync Screen ─────────────────────────────────────────────────
    'qr_sync': {
      'hi': 'QR सिंक',
      'mr': 'QR सिंक',
      'en': 'QR Sync',
    },
    'share_data': {
      'hi': 'डेटा भेजें',
      'mr': 'डेटा पाठवा',
      'en': 'Share Data',
    },
    'receive_data': {
      'hi': 'डेटा पाएं',
      'mr': 'डेटा मिळवा',
      'en': 'Receive Data',
    },
    'which_period': {
      'hi': 'किस अवधि का डेटा?',
      'mr': 'कोणत्या कालावधीचा डेटा?',
      'en': 'Which period?',
    },
    'show_qr_to_anm': {
      'hi': 'ANM को यह QR दिखाएं',
      'mr': 'ANM ला हा QR दाखवा',
      'en': 'Show this QR to ANM',
    },
    'valid_30_mins': {
      'hi': 'QR 30 मिनट के लिए मान्य है',
      'mr': 'QR 30 मिनिटांसाठी वैध आहे',
      'en': 'Valid for 30 mins',
    },
    'scan_qr': {
      'hi': '📷 स्कैन करें',
      'mr': '📷 स्कॅन करा',
      'en': '📷 Scan QR',
    },
    'data_received': {
      'hi': '✓ डेटा प्राप्त हुआ',
      'mr': '✓ डेटा प्राप्त झाला',
      'en': '✓ Data Received',
    },
    'save_report': {
      'hi': '📄  रिपोर्ट सेव करें',
      'mr': '📄  अहवाल जतन करा',
      'en': '📄  Save Report',
    },
    'scan_again': {
      'hi': '🔄  दोबारा स्कैन करें',
      'mr': '🔄  पुन्हा स्कॅन करा',
      'en': '🔄  Scan Again',
    },
    'invalid_qr': {
      'hi': '❌ अमान्य QR',
      'mr': '❌ अवैध QR',
      'en': '❌ Invalid QR Code',
    },
  };
}
