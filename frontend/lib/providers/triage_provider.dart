import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/triage_result.dart';
import '../models/session_model.dart';
import '../services/triage_engine.dart';
import '../services/database_service.dart';

class TriageProvider extends ChangeNotifier {
  String workerName = '';
  String ageGroup = '';
  String duration = '';
  String rawTranscript = '';
  List<DetectedConcept> detectedConcepts = [];
  List<DetectedConcept> confirmedConcepts = [];
  TriageResult? triageResult;
  bool isProcessing = false;
  String? errorMessage;
  bool safetyNetForceRed = false;

  final Random _random = Random();

  void setWorkerName(String name) {
    workerName = name;
    notifyListeners();
  }

  void setAgeGroup(String group) {
    ageGroup = group;
    notifyListeners();
  }

  void setDuration(String dur) {
    duration = dur;
    notifyListeners();
  }

  void setRawTranscript(String text) {
    rawTranscript = text;
    notifyListeners();
  }

  void setDetectedConcepts(List<DetectedConcept> concepts) {
    detectedConcepts = concepts;
    confirmedConcepts = [];
    notifyListeners();
  }

  void confirmConcept(String conceptKey, bool confirmed) {
    final idx =
        detectedConcepts.indexWhere((c) => c.conceptKey == conceptKey);
    if (idx >= 0) {
      detectedConcepts[idx] =
          detectedConcepts[idx].copyWith(confirmed: confirmed);
      if (confirmed) {
        confirmedConcepts = detectedConcepts
            .where((c) => c.confirmed)
            .toList();
      } else {
        confirmedConcepts =
            confirmedConcepts.where((c) => c.conceptKey != conceptKey).toList();
      }
      notifyListeners();
    }
  }

  void setSafetyNet(bool forced) {
    safetyNetForceRed = forced;
    notifyListeners();
  }

  Future<void> runTriage(TriageEngine engine) async {
    isProcessing = true;
    errorMessage = null;
    notifyListeners();

    try {
      final code = generateSessionCode();
      final result = engine.scoreTriage(
        confirmedConcepts,
        ageGroup,
        duration,
        code,
        forceRed: safetyNetForceRed,
      );
      triageResult = result;

      // Save session once here — not on PDF generation
      final session = SessionModel(
        sessionCode: code,
        workerName: workerName,
        ageGroup: ageGroup,
        duration: duration,
        rawTranscription: rawTranscript,
        confirmedConcepts: json.encode(
          confirmedConcepts.map((c) => c.toMap()).toList(),
        ),
        triageLevel: result.levelString,
        timestamp: result.timestamp.toIso8601String(),
        referralGenerated: 0,
      );
      await DatabaseService.instance.insertSession(session);
    } catch (e) {
      errorMessage = 'त्रुटि हुई। कृपया पुनः प्रयास करें।';
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }

  void resetSession() {
    workerName = '';
    ageGroup = '';
    duration = '';
    rawTranscript = '';
    detectedConcepts = [];
    confirmedConcepts = [];
    triageResult = null;
    isProcessing = false;
    errorMessage = null;
    safetyNetForceRed = false;
    notifyListeners();
  }

  String generateSessionCode() {
    return (_random.nextInt(900000) + 100000).toString();
  }
}
