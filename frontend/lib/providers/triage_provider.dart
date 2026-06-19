import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/session_model.dart';
import '../models/triage_result.dart';
import '../models/detected_concept.dart';
import '../services/database_service.dart';
import '../services/triage_engine.dart';
import '../utils/app_strings.dart';
import '../screens/result_screen.dart';

class TriageProvider extends ChangeNotifier {
  SessionModel? _currentSession;
  TriageResult? _currentResult;
  String _transcribedText = '';
  bool _isRecording = false;
  bool _isProcessing = false;
  String _selectedLanguage = 'hi';
  String currentTranscript = '';
  bool _servicesReady = false;

  bool get servicesReady => _servicesReady;

  set servicesReady(bool value) {
    _servicesReady = value;
    notifyListeners();
  }

  String? initError;
  void setInitError(String error) {
    initError = error;
    notifyListeners();
  }

  bool isAnalyzing = false;
  bool safetyNetTriggered = false;

  
  // Dynamic Confirmation state
  List<DetectedConcept> detectedConcepts = [];
  int _currentConfirmationStep = 0;
  final List<bool?> _confirmationAnswers = [];

  SessionModel? get currentSession    => _currentSession;
  TriageResult? get currentResult     => _currentResult;
  String        get transcribedText   => _transcribedText;
  bool          get isRecording       => _isRecording;
  bool          get isProcessing      => _isProcessing;
  int           get confirmationStep  => _currentConfirmationStep;
  List<bool?>   get confirmationAnswers => _confirmationAnswers;
  String        get selectedLanguage  => _selectedLanguage;

  void setLanguage(String lang) {
    _selectedLanguage = lang;
    notifyListeners();
  }

  void setTranscript(String text) {
    currentTranscript = text;
    notifyListeners();
    analyzeTranscript();
  }

  List<String> get confirmationQuestions {
    final questions = detectedConcepts.map((c) => c.getQuestionForLang(_selectedLanguage)).toList();
    questions.add(AppStrings.get('safety_net_q', _selectedLanguage)); // Mandatory safety net
    return questions;
  }

  void startSession(SessionModel session) {
    _currentSession = session;
    _transcribedText = '';
    _currentResult = null;
    detectedConcepts = [];
    _currentConfirmationStep = 0;
    _confirmationAnswers.clear();
    DatabaseService.instance.insertSession(session);
    notifyListeners();
  }

  void updateTranscription(String text) {
    _transcribedText = text;
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(transcribedText: text);
    }
    notifyListeners();
  }

  void setRecording(bool value) {
    _isRecording = value;
    notifyListeners();
  }

  void setProcessing(bool value) {
    _isProcessing = value;
    notifyListeners();
  }

  Future<void> analyzeTranscript() async {
    isAnalyzing = true;
    _currentResult = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500)); // allow UI to paint

    final ageGroup = _currentSession?.patientAgeGroup?.name ?? 'ADULT';
    final duration = _currentSession?.symptomDuration?.name ?? 'TODAY';

    try {
      detectedConcepts = TriageEngine.instance.analyzeText(
        currentTranscript,
        ageGroup,
        duration,
      );
    } catch (e) {
      debugPrint('Error analyzing text: $e');
      detectedConcepts = [];
    }

    _currentConfirmationStep = 0;
    _confirmationAnswers.clear();
    for (int i = 0; i < confirmationQuestions.length; i++) {
      _confirmationAnswers.add(null);
    }

    isAnalyzing = false;
    notifyListeners();
  }

  Future<void> analyzeTranscription() async {
    _isProcessing = true;
    notifyListeners();
    
    // Simulate some delay for NLP UX
    await Future.delayed(const Duration(milliseconds: 500));
    
    try {
      detectedConcepts = TriageEngine.instance.analyzeText(
        _transcribedText,
        _currentSession?.patientAgeGroup?.name ?? 'ADULT',
        _currentSession?.symptomDuration?.name ?? 'TODAY',
      );
    } catch (e) {
      debugPrint('Error analyzing text: $e');
      detectedConcepts = [];
    }
    
    _currentConfirmationStep = 0;
    _confirmationAnswers.clear();
    for (int i = 0; i < confirmationQuestions.length; i++) {
      _confirmationAnswers.add(null);
    }
    
    _isProcessing = false;
    notifyListeners();
  }

  String get currentQuestion => confirmationQuestions[_currentConfirmationStep];
  bool get isLastQuestion => _currentConfirmationStep == confirmationQuestions.length - 1;

  void answerConfirmation(bool answer) {
    _confirmationAnswers[_currentConfirmationStep] = answer;
    
    // Also update the underlying concept, unless it's the safety net question
    if (detectedConcepts.isNotEmpty && _currentConfirmationStep < detectedConcepts.length) {
      detectedConcepts[_currentConfirmationStep].confirmed = answer;
    }
    
    notifyListeners();
  }

  bool nextConfirmationStep() {
    if (_currentConfirmationStep < confirmationQuestions.length - 1) {
      _currentConfirmationStep++;
      notifyListeners();
      return false;
    }
    return true; // Done
  }

  void setTriageResult(TriageResult result) {
    _currentResult = result;
    DatabaseService.instance.insertTriageResult(result);
    notifyListeners();
  }

  Future<void> scoreAndNavigate() async {
    final result = TriageEngine.instance.scoreTriage(
      concepts: detectedConcepts,
      safetyNetTriggered: safetyNetTriggered,
      sessionId: _currentSession?.id ?? 'unknown',
      transcribedText: currentTranscript,
      ageGroup: _currentSession?.patientAgeGroup?.name ?? 'ADULT',
      duration: _currentSession?.symptomDuration?.name ?? 'TODAY',
    );
    
    setTriageResult(result);

    final confirmedLabels = detectedConcepts.where((c) => c.confirmed).map((c) => c.hindiLabel).toList();
    final confirmedJson = jsonEncode(confirmedLabels);
    final sessionCode = _currentSession?.sessionCode ?? result.sessionId;
    
    await DatabaseService.instance.saveSession(
      id: _currentSession?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      sessionCode: sessionCode,
      workerName: _currentSession?.ashaWorkerName ?? 'Unknown',
      patientAgeGroup: _currentSession?.patientAgeGroup?.name ?? 'ADULT',
      symptomDuration: _currentSession?.symptomDuration?.name ?? 'TODAY',
      rawTranscription: currentTranscript,
      confirmedConcepts: confirmedJson,
      triageLevel: result.category.name,
      timestamp: DateTime.now().toIso8601String(),
      referralGenerated: 0,
    );

    print('SESSION SAVED $sessionCode');
  }

  void markReferralGenerated() {
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(referralGenerated: true);
      DatabaseService.instance.updateSession(_currentSession!);
      notifyListeners();
    }
  }

  void reset() {
    _currentSession = null;
    _currentResult  = null;
    _transcribedText = '';
    _isRecording = false;
    _isProcessing = false;
    detectedConcepts = [];
    _currentConfirmationStep = 0;
    _confirmationAnswers.clear();
    notifyListeners();
  }
}
