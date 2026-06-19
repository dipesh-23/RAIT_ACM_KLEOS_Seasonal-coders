class DetectedConcept {
  final String conceptKey;
  final String category; // 'RED', 'YELLOW', 'GREEN'
  final double similarity;
  final int weight;
  final String hindiLabel;
  final String confirmationQuestion;
  bool confirmed; // mutable so worker can flip it

  DetectedConcept({
    required this.conceptKey,
    required this.category,
    required this.similarity,
    required this.weight,
    required this.hindiLabel,
    required this.confirmationQuestion,
    this.confirmed = false,
  });

  String getLabelForLang(String lang) {
    if (lang == 'mr') return _labelTranslationsMr[conceptKey] ?? hindiLabel;
    if (lang == 'en') return _labelTranslationsEn[conceptKey] ?? hindiLabel;
    return hindiLabel;
  }

  String getQuestionForLang(String lang) {
    if (lang == 'mr') return _questionTranslationsMr[conceptKey] ?? confirmationQuestion;
    if (lang == 'en') return _questionTranslationsEn[conceptKey] ?? confirmationQuestion;
    return confirmationQuestion;
  }

  static const Map<String, String> _labelTranslationsMr = {
    'breathing difficulty': 'श्वास घेण्यास त्रास',
    'unconscious unresponsive': 'बेशुद्ध / प्रतिसाद देत नाही',
    'seizure convulsion': 'झटके / आकडी',
    'severe bleeding': 'तीव्र रक्तस्त्राव',
    'chest pain': 'छातीत दुखणे',
    'newborn emergency': 'नवजात अर्भक आणीबाणी',
    'labor delivery complication': 'प्रसूतीतील गुंतागुंत',
    'not eating not drinking': 'काहीही खात-पीत नाही',
    'high fever many days': 'अनेक दिवस तीव्र ताप',
    'repeated vomiting': 'वारंवार उलट्या',
    'severe diarrhea': 'तीव्र जुलाब',
    'severe headache': 'तीव्र डोकेदुखी',
    'pregnancy problem': 'गर्भधारणेतील समस्या',
    'child not active lethargic': 'मूल सुस्त आहे',
    'swelling body': 'अंगावर सूज',
    'mild fever': 'सौम्य ताप',
    'common cold cough': 'सर्दी खोकला',
    'minor body ache': 'अंगदुखी',
    'minor stomach ache': 'पोटदुखी',
  };

  static const Map<String, String> _labelTranslationsEn = {
    'breathing difficulty': 'Breathing Difficulty',
    'unconscious unresponsive': 'Unconscious / Unresponsive',
    'seizure convulsion': 'Seizures / Convulsions',
    'severe bleeding': 'Severe Bleeding',
    'chest pain': 'Chest Pain',
    'newborn emergency': 'Newborn Emergency',
    'labor delivery complication': 'Labor/Delivery Complication',
    'not eating not drinking': 'Not Eating/Drinking',
    'high fever many days': 'High Fever (Many days)',
    'repeated vomiting': 'Repeated Vomiting',
    'severe diarrhea': 'Severe Diarrhea',
    'severe headache': 'Severe Headache',
    'pregnancy problem': 'Pregnancy Problem',
    'child not active lethargic': 'Child Inactive/Lethargic',
    'swelling body': 'Body Swelling',
    'mild fever': 'Mild Fever',
    'common cold cough': 'Cold and Cough',
    'minor body ache': 'Minor Body Ache',
    'minor stomach ache': 'Minor Stomach Ache',
  };

  static const Map<String, String> _questionTranslationsMr = {
    'breathing difficulty': 'रुग्णाला श्वास घेण्यास त्रास होत आहे का?',
    'unconscious unresponsive': 'रुग्ण बेशुद्ध आहे किंवा प्रतिसाद देत नाही का?',
    'seizure convulsion': 'रुग्णाला झटके किंवा आकडी येत आहे का?',
    'severe bleeding': 'रुग्णाला तीव्र रक्तस्त्राव होत आहे का?',
    'chest pain': 'रुग्णाच्या छातीत दुखत आहे का?',
    'newborn emergency': 'नवजात अर्भकाला कोणतीही आणीबाणीची समस्या आहे का?',
    'labor delivery complication': 'प्रसूतीमध्ये कोणतीही गुंतागुंत आहे का?',
    'not eating not drinking': 'रुग्णाने खाणे-पिणे पूर्णपणे बंद केले आहे का?',
    'high fever many days': 'रुग्णाला अनेक दिवसांपासून तीव्र ताप आहे का?',
    'repeated vomiting': 'रुग्णाला वारंवार उलट्या होत आहेत का?',
    'severe diarrhea': 'रुग्णाला तीव्र जुलाब होत आहेत का?',
    'severe headache': 'रुग्णाचे डोके खूप दुखत आहे का?',
    'pregnancy problem': 'गर्भधारणेमध्ये कोणतीही समस्या येत आहे का?',
    'child not active lethargic': 'मूल सुस्त आहे आणि नेहमीपेक्षा कमी सक्रिय आहे का?',
    'swelling body': 'रुग्णाच्या अंगावर सूज आहे का?',
    'mild fever': 'रुग्णाला सौम्य ताप आहे का?',
    'common cold cough': 'रुग्णाला सामान्य सर्दी किंवा खोकला आहे का?',
    'minor body ache': 'रुग्णाच्या अंगात थोडे दुखत आहे का?',
    'minor stomach ache': 'रुग्णाच्या पोटात थोडे दुखत आहे का?',
    '__unknown__': 'रुग्णाला ही समस्या होत आहे का?',
  };

  static const Map<String, String> _questionTranslationsEn = {
    'breathing difficulty': 'Is the patient having difficulty breathing?',
    'unconscious unresponsive': 'Is the patient unconscious or unresponsive?',
    'seizure convulsion': 'Is the patient having seizures or convulsions?',
    'severe bleeding': 'Is the patient experiencing severe bleeding?',
    'chest pain': 'Is the patient experiencing chest pain?',
    'newborn emergency': 'Does the newborn have any emergency condition?',
    'labor delivery complication': 'Are there any complications in labor/delivery?',
    'not eating not drinking': 'Has the patient completely stopped eating and drinking?',
    'high fever many days': 'Does the patient have a high fever for many days?',
    'repeated vomiting': 'Is the patient vomiting repeatedly?',
    'severe diarrhea': 'Is the patient having severe diarrhea?',
    'severe headache': 'Does the patient have a severe headache?',
    'pregnancy problem': 'Are there any complications in pregnancy?',
    'child not active lethargic': 'Is the child lethargic or less active than normal?',
    'swelling body': 'Is there swelling on the patient\'s body?',
    'mild fever': 'Does the patient have a mild fever?',
    'common cold cough': 'Does the patient have a common cold or cough?',
    'minor body ache': 'Does the patient have a minor body ache?',
    'minor stomach ache': 'Does the patient have a minor stomach ache?',
    '__unknown__': 'Is the patient experiencing this problem?',
  };
}
