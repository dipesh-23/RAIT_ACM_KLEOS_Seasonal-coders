import 'package:flutter/material.dart';
import '../models/session_model.dart';
import '../models/triage_result.dart';
import '../models/detected_concept.dart';
import '../services/database_service.dart';
import '../services/triage_engine.dart';
import '../utils/app_strings.dart';

class TriageProvider extends ChangeNotifier {
  SessionModel? _currentSession;
  TriageResult? _currentResult;
  String _transcribedText = '';
  bool _isRecording = false;
  bool _isProcessing = false;
  String _selectedLanguage = 'hi';

  
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
  String        get selectedLanguage  => _selectedLanguage;

  void setLanguage(String lang) {
    _selectedLanguage = lang;
    notifyListeners();
  }

  List<String> get confirmationQuestions {
    if (_detectedConcepts.isEmpty) {
      return [AppStrings.get('safety_net_q', _selectedLanguage)];
    }
    return _detectedConcepts.map((c) => c.getQuestionForLang(_selectedLanguage)).toList();
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
    
    // Also update the underlying concept
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
    // If the safety net question was triggered (e.g. if no concepts detected, we fall back to 1 static question)
    bool safetyNet = false;
    if (_detectedConcepts.isEmpty && _confirmationAnswers.isNotEmpty) {
      safetyNet = _confirmationAnswers[0] == true;
    }
    
    final result = TriageEngine.instance.scoreTriage(
      concepts: _detectedConcepts,
      safetyNetTriggered: safetyNet,
      sessionId: _currentSession?.id ?? 'unknown',
      transcribedText: _transcribedText,
    );
    
    setTriageResult(result);
    return result;
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
