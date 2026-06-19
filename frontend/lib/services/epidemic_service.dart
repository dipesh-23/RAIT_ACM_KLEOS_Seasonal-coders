import 'dart:convert';
import 'database_service.dart';

class EpidemicAlert {
  final String alertType;
  final int caseCount;
  final String timeWindow;
  final String dominantConcept;
  final String hindiMessage;
  final String englishMessage;
  final DateTime detectedAt;
  final bool requiresAction;

  EpidemicAlert({
    required this.alertType,
    required this.caseCount,
    required this.timeWindow,
    required this.dominantConcept,
    required this.hindiMessage,
    required this.englishMessage,
    required this.detectedAt,
    required this.requiresAction,
  });

  Map<String, dynamic> toMap() {
    return {
      'alertType': alertType,
      'caseCount': caseCount,
      'timeWindow': timeWindow,
      'dominantConcept': dominantConcept,
      'hindiMessage': hindiMessage,
      'englishMessage': englishMessage,
      'detectedAt': detectedAt.toIso8601String(),
      'requiresAction': requiresAction,
    };
  }
}

class EpidemicService {
  static const int RED_THRESHOLD = 3;
  static const int CONCEPT_CLUSTER_THRESHOLD = 3;

  Future<EpidemicAlert?> checkForAlerts(String workerName) async {
    final sessions = await DatabaseService.instance.getSessionsLast48Hours(workerName);
    
    int redCount = 0;
    int yellowCount = 0;
    int greenCount = 0;
    Map<String, int> conceptFreqs = {};

    for (var s in sessions) {
      if (s.triageLevel == 'RED') redCount++;
      if (s.triageLevel == 'YELLOW') yellowCount++;
      if (s.triageLevel == 'GREEN') greenCount++;

      if (s.confirmedConcepts.isNotEmpty) {
        for (var concept in s.confirmedConcepts) {
          conceptFreqs[concept] = (conceptFreqs[concept] ?? 0) + 1;
        }
      }
    }

    String topConcept = '';
    int maxFreq = 0;
    for (var key in conceptFreqs.keys) {
      if (conceptFreqs[key]! > maxFreq) {
        maxFreq = conceptFreqs[key]!;
        topConcept = key;
      }
    }

    EpidemicAlert? alert;
    
    if (redCount >= RED_THRESHOLD) {
      alert = EpidemicAlert(
        alertType: 'RED_CLUSTER',
        caseCount: redCount,
        timeWindow: 'पिछले 48 घंटे',
        dominantConcept: topConcept,
        hindiMessage: buildHindiMessage('RED_CLUSTER', redCount, topConcept),
        englishMessage: buildEnglishMessage('RED_CLUSTER', redCount),
        detectedAt: DateTime.now(),
        requiresAction: true,
      );
    } else if (maxFreq >= CONCEPT_CLUSTER_THRESHOLD) {
      alert = EpidemicAlert(
        alertType: 'CONCEPT_CLUSTER',
        caseCount: maxFreq,
        timeWindow: 'पिछले 48 घंटे',
        dominantConcept: topConcept,
        hindiMessage: buildHindiMessage('CONCEPT_CLUSTER', maxFreq, topConcept),
        englishMessage: buildEnglishMessage('CONCEPT_CLUSTER', maxFreq),
        detectedAt: DateTime.now(),
        requiresAction: true,
      );
    }

    // Save snapshot
    await DatabaseService.instance.insertEpidemicSnapshot({
      'snapshot_date': DateTime.now().toIso8601String(),
      'red_count': redCount,
      'yellow_count': yellowCount,
      'green_count': greenCount,
      'alert_triggered': alert != null ? 1 : 0,
      'dominant_concepts': topConcept,
      'worker_name': workerName,
    });

    return alert;
  }

  Future<List<EpidemicAlert>> getAlertHistory(String workerName, int days) async {
    // We would parse from snapshots or local storage. The prompt requires us to show alert history list
    // In actual implementation, we might save actual alerts somewhere. Since table only stores snapshot,
    // we return empty here or construct from snapshots where alert_triggered = 1.
    final snapshots = await DatabaseService.instance.getRecentSnapshots(workerName, days);
    List<EpidemicAlert> history = [];
    for (var s in snapshots) {
      if (s['alert_triggered'] == 1) {
        final red = s['red_count'] as int;
        final conceptCount = 0; // approximate
        final dom = s['dominant_concepts'] as String;
        
        final type = red >= RED_THRESHOLD ? 'RED_CLUSTER' : 'CONCEPT_CLUSTER';
        final count = red >= RED_THRESHOLD ? red : CONCEPT_CLUSTER_THRESHOLD;
        
        history.add(EpidemicAlert(
          alertType: type,
          caseCount: count,
          timeWindow: 'पिछले 48 घंटे',
          dominantConcept: dom,
          hindiMessage: buildHindiMessage(type, count, dom),
          englishMessage: buildEnglishMessage(type, count),
          detectedAt: DateTime.parse(s['snapshot_date']),
          requiresAction: false,
        ));
      }
    }
    return history;
  }

  String buildHindiMessage(String alertType, int count, String concept) {
    if (alertType == 'RED_CLUSTER') {
      return "⚠ चेतावनी: पिछले 48 घंटों में $count गंभीर मरीज़ देखे गए। ANM को तुरंत सूचित करें।";
    }
    if (alertType == 'CONCEPT_CLUSTER') {
      return "⚠ चेतावनी: कई मरीज़ों में एक जैसे लक्षण दिखे। ANM को सूचित करें।";
    }
    return "";
  }

  String buildEnglishMessage(String alertType, int count) {
    if (alertType == 'RED_CLUSTER') {
      return "⚠ Alert: $count critical cases in last 48 hours. Inform ANM immediately.";
    }
    if (alertType == 'CONCEPT_CLUSTER') {
      return "⚠ Alert: Multiple patients with similar symptoms. Inform ANM.";
    }
    return "";
  }
}
