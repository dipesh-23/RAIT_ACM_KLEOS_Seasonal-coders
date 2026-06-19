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
    if (lang == 'en') return _labelTranslationsEn[conceptKey] ?? hindiLabel;
    return hindiLabel;
  }

  String getQuestionForLang(String lang) {
    if (lang == 'en') return _questionTranslationsEn[conceptKey] ?? confirmationQuestion;
    return confirmationQuestion;
  }

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
