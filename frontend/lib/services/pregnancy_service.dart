class PregnancyService {
  static final PregnancyService instance = PregnancyService._();
  PregnancyService._();

  static const List<String> dangerSigns = [
    'severe_bleeding',
    'severe_headache',
    'swelling',
    'blurred_vision',
    'abdominal_pain',
    'convulsions',
    'high_fever',
    'water_breaking',
    'decreased_movement',
  ];

  static const Map<String, Map<String, String>> dangerSignsLocalized = {
    'severe_bleeding': {
      'hi': 'अत्यधिक रक्तस्राव',
      'en': 'Severe Bleeding',
    },
    'severe_headache': {
      'hi': 'तेज सिरदर्द और चक्कर',
      'en': 'Severe Headache and Dizziness',
    },
    'swelling': {
      'hi': 'हाथ-पैर और चेहरे पर सूजन',
      'en': 'Swelling of Face and Limbs',
    },
    'blurred_vision': {
      'hi': 'धुंधली दिखाई देना',
      'en': 'Blurred Vision',
    },
    'abdominal_pain': {
      'hi': 'तेज पेट दर्द',
      'en': 'Severe Abdominal Pain',
    },
    'convulsions': {
      'hi': 'अकड़न या झटके',
      'en': 'Convulsions or Stiffness',
    },
    'high_fever': {
      'hi': 'तेज बुखार',
      'en': 'High Body Temperature',
    },
    'water_breaking': {
      'hi': 'पानी का जल्दी छूटना',
      'en': 'Water Breaking Early',
    },
    'decreased_movement': {
      'hi': 'शिशु की हलचल कम होना',
      'en': 'Decreased Fetal Movement',
    },
  };

  Map<String, dynamic> calculateGestationalMetrics(String lmpIsoString) {
    try {
      final lmp = DateTime.parse(lmpIsoString);
      final today = DateTime.now();

      final difference = today.difference(lmp).inDays;
      final gestationalWeek = difference ~/ 7;

      final edd = lmp.add(const Duration(days: 280));

      String trimester = 'FIRST';
      if (gestationalWeek >= 28) {
        trimester = 'THIRD';
      } else if (gestationalWeek >= 13) {
        trimester = 'SECOND';
      }

      return {
        'week': gestationalWeek,
        'trimester': trimester,
        'edd': edd,
        'days_remaining': edd.difference(today).inDays,
      };
    } catch (e) {
      return {
        'week': 0,
        'trimester': 'FIRST',
        'edd': DateTime.now(),
        'days_remaining': 0,
      };
    }
  }

  String evaluateRiskLevel({
    required int gestationalWeek,
    required List<String> selectedDangerSigns,
  }) {
    if (selectedDangerSigns.isNotEmpty || gestationalWeek > 36) {
      return 'HIGH';
    } else if (gestationalWeek >= 28 && gestationalWeek <= 36) {
      return 'MEDIUM';
    } else {
      return 'LOW';
    }
  }
}
