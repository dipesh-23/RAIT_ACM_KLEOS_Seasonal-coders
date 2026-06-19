import 'database_service.dart';

class DashboardService {
  static final DashboardService instance = DashboardService._();
  DashboardService._();

  static const Map<String, Map<String, String>> symptomTranslationsLocalized = {
    'fever': {
      'hi': 'तेज शरीर का तापमान',
      'en': 'High Body Temperature',
    },
    'cough': {
      'hi': 'लगातार खांसी',
      'en': 'Persistent Cough',
    },
    'breath': {
      'hi': 'सांस लेने में कठिनाई',
      'en': 'Difficulty Breathing',
    },
    'diarrhea': {
      'hi': 'बार-बार दस्त',
      'en': 'Frequent Loose Stools',
    },
    'pain': {
      'hi': 'अत्यधिक शारीरिक दर्द',
      'en': 'Extreme Body Pain',
    },
    'weakness': {
      'hi': 'गंभीर शारीरिक कमजोरी',
      'en': 'Severe Weakness',
    },
    'vomiting': {
      'hi': 'लगातार उल्टी',
      'en': 'Continuous Vomiting',
    },
    'injury': {
      'hi': 'बाहरी चोट',
      'en': 'External Injury',
    },
    'bleeding': {
      'hi': 'असामान्य रक्तस्राव',
      'en': 'Unusual Bleeding',
    },
    'fits': {
      'hi': 'दौरे या अकड़न',
      'en': 'Seizures or Stiffness',
    },
    'unconscious': {
      'hi': 'होश खोना',
      'en': 'Loss of Consciousness',
    },
    'chest_pain': {
      'hi': 'सीने में भारीपन',
      'en': 'Chest Heaviness',
    },
    'headache': {
      'hi': 'तेज सिरदर्द',
      'en': 'Severe Headache',
    },
    'swelling': {
      'hi': 'हाथ-पैर में सूजन',
      'en': 'Swelling of Limbs',
    },
    'vision': {
      'hi': 'धुंधली दृष्टि',
      'en': 'Blurred Vision',
    },
    'none': {
      'hi': 'कोई प्रमुख लक्षण नहीं',
      'en': 'No Major Concern',
    },
  };

  Future<Map<String, dynamic>> calculateMetrics(DateTime start, DateTime end) async {
    final sessions = await DatabaseService.instance.getSessionsInDateRange(start, end);
    final counts = await DatabaseService.instance.getTriageLevelCounts(start, end);

    final total = sessions.length;
    final red = counts['RED'] ?? 0;
    final yellow = counts['YELLOW'] ?? 0;
    final green = counts['GREEN'] ?? 0;

    final Map<String, int> conceptCounts = {};
    for (var session in sessions) {
      if (session.confirmedConcepts != null) {
        for (var concept in session.confirmedConcepts!) {
          conceptCounts[concept] = (conceptCounts[concept] ?? 0) + 1;
        }
      }
    }

    String dominantConcernKey = 'none';
    int maxCount = 0;
    conceptCounts.forEach((key, count) {
      if (count > maxCount) {
        maxCount = count;
        dominantConcernKey = key;
      }
    });

    return {
      'total': total,
      'red': red,
      'yellow': yellow,
      'green': green,
      'dominant_concern': dominantConcernKey,
      'concept_counts': conceptCounts,
    };
  }
}
