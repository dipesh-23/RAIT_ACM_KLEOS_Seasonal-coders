import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/session_model.dart';
import '../models/triage_result.dart';
import '../models/detected_concept.dart';
import '../services/database_service.dart';
import '../services/triage_engine.dart';

class TriageProvider extends ChangeNotifier {
  SessionModel? _currentSession;
  TriageResult? _currentResult;
  String _transcribedText = '';
  bool _isRecording = false;
  bool _isProcessing = false;
  
  // Dynamic Confirmation state
  List<DetectedConcept> _detectedConcepts = [];
  int _currentConfirmationStep = 0;
  final List<bool?> _confirmationAnswers = [];

  SessionModel? get currentSession    => _currentSession;
  TriageResult? get currentResult     => _currentResult;
  String        get transcribedText   => _transcribedText;
  bool          get isRecording       => _isRecording;
  bool          get isProcessing      => _isProcessing;
  int           get confirmationStep  => _currentConfirmationStep;
  List<bool?>   get confirmationAnswers => _confirmationAnswers;

  List<String> get confirmationQuestions {
    final questions = _detectedConcepts.map((c) => c.confirmationQuestion).toList();
    questions.add('क्या मरीज की हालत बहुत गंभीर लग रही है?'); // Mandatory safety net
    return questions;
  }

  void startSession(SessionModel session) {
    _currentSession = session;
    _transcribedText = '';
    _currentResult = null;
    _detectedConcepts = [];
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

  Future<void> analyzeTranscription() async {
    _isProcessing = true;
    notifyListeners();
    
    // Simulate some delay for NLP UX
    await Future.delayed(const Duration(milliseconds: 500));
    
    try {
      _detectedConcepts = TriageEngine.instance.analyzeText(
        _transcribedText,
        _currentSession?.patientAgeGroup?.name ?? 'ADULT',
        _currentSession?.symptomDuration?.name ?? 'TODAY',
      );
    } catch (e) {
      debugPrint('Error analyzing text: $e');
      _detectedConcepts = [];
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
    if (_detectedConcepts.isNotEmpty && _currentConfirmationStep < _detectedConcepts.length) {
      _detectedConcepts[_currentConfirmationStep].confirmed = answer;
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

  TriageResult computeFinalTriage() {
    // The safety net question is always the last question in the confirmationAnswers list
    bool safetyNet = false;
    if (_confirmationAnswers.isNotEmpty) {
      safetyNet = _confirmationAnswers.last == true;
    }
    
    final result = TriageEngine.instance.scoreTriage(
      concepts: _detectedConcepts,
      safetyNetTriggered: safetyNet,
      sessionId: _currentSession?.id ?? 'unknown',
      transcribedText: _transcribedText,
      ageGroup: _currentSession?.patientAgeGroup?.name ?? 'ADULT',
      duration: _currentSession?.symptomDuration?.name ?? 'TODAY',
    );
    
    setTriageResult(result);

    // Save final session state
    if (_currentSession != null) {
      final confirmedConceptsJson = jsonEncode(
        _detectedConcepts.where((c) => c.confirmed).map((c) => c.conceptKey).toList()
      );
      
      _currentSession = _currentSession!.copyWith(
        isCompleted: true,
        confirmedConcepts: confirmedConceptsJson,
        triageLevel: result.category.name,
      );
      DatabaseService.instance.updateSession(_currentSession!);
    }

    return result;
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
    _detectedConcepts = [];
    _currentConfirmationStep = 0;
    _confirmationAnswers.clear();
    notifyListeners();
  }
}
