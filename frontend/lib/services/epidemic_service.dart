import 'database_service.dart';
import 'dashboard_service.dart';
import '../models/session_model.dart';

class EpidemicService {
  static final EpidemicService instance = EpidemicService._();
  EpidemicService._();

  Future<Map<String, dynamic>> checkEpidemicAlerts() async {
    final sessions = await DatabaseService.instance.getSessionsLast48Hours();

    int redCount = 0;
    int yellowCount = 0;
    int greenCount = 0;
    final Map<String, int> conceptCounts = {};

    for (var session in sessions) {
      if (session.triageLevel == 'RED') {
        redCount++;
      } else if (session.triageLevel == 'YELLOW') {
        yellowCount++;
      } else if (session.triageLevel == 'GREEN') {
        greenCount++;
      }

      if (session.confirmedConcepts != null) {
        for (var concept in session.confirmedConcepts!) {
          conceptCounts[concept] = (conceptCounts[concept] ?? 0) + 1;
        }
      }
    }

    bool hasRedAlert = redCount >= 3;
    bool hasConceptAlert = false;
    String alertConcept = '';

    conceptCounts.forEach((concept, count) {
      if (count >= 3) {
        hasConceptAlert = true;
        alertConcept = concept;
      }
    });

    bool triggerAlert = hasRedAlert || hasConceptAlert;

    String alertMessageHindi = '';
    String alertMessageEnglish = '';

    if (triggerAlert) {
      if (hasRedAlert && hasConceptAlert) {
        final labelHi = DashboardService.symptomTranslationsLocalized[alertConcept]?['hi'] ?? alertConcept;
        final labelEn = DashboardService.symptomTranslationsLocalized[alertConcept]?['en'] ?? alertConcept;
        alertMessageHindi = 'चेतावनी: क्षेत्र में अत्यधिक गंभीर मामले और असामान्य प्रसार संकेत ($labelHi)';
        alertMessageEnglish = 'Warning: Multiple critical cases and unusual pattern detected ($labelEn)';
      } else if (hasRedAlert) {
        alertMessageHindi = 'चेतावनी: पिछले 48 घंटों में गंभीर मामलों की संख्या 3 या अधिक है';
        alertMessageEnglish = 'Warning: 3 or more critical cases detected in the last 48 hours';
      } else {
        final labelHi = DashboardService.symptomTranslationsLocalized[alertConcept]?['hi'] ?? alertConcept;
        final labelEn = DashboardService.symptomTranslationsLocalized[alertConcept]?['en'] ?? alertConcept;
        alertMessageHindi = 'चेतावनी: समान लक्षणों का संकेंद्रण संकेत ($labelHi)';
        alertMessageEnglish = 'Warning: High concentration of matching symptom concepts ($labelEn)';
      }

      await DatabaseService.instance.insertEpidemicSnapshot({
        'snapshot_date': DateTime.now().toIso8601String(),
        'red_count': redCount,
        'yellow_count': yellowCount,
        'green_count': greenCount,
        'alert_triggered': 1,
        'dominant_concepts': alertConcept,
        'worker_name': sessions.isNotEmpty ? sessions.first.ashaWorkerName : 'ASHA Worker',
      });
    }

    return {
      'alert_triggered': triggerAlert,
      'alert_message_hi': alertMessageHindi,
      'alert_message_en': alertMessageEnglish,
      'red_count': redCount,
      'yellow_count': yellowCount,
      'green_count': greenCount,
      'concept_counts': conceptCounts,
    };
  }
}
