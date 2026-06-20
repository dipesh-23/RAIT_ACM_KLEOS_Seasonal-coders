import 'package:flutter/material.dart';
import '../models/session_model.dart';
import '../models/triage_result.dart';
import '../models/detected_concept.dart';
import '../services/database_service.dart';
import '../services/embedding_service.dart';
import '../services/triage_engine.dart';
import '../utils/app_strings.dart';

class TriageProvider extends ChangeNotifier {
  SessionModel? _currentSession;
  TriageResult? _currentResult;
  String _transcribedText = '';
  bool _isRecording = false;
  bool _isProcessing = false;
  String _selectedLanguage = 'hi';

  /// True once [EmbeddingService] and [TriageEngine] have finished loading.
  /// The home screen blocks on this flag before showing any triage UI.
  bool _servicesReady = false;

  
  // Dynamic Confirmation state
  List<DetectedConcept> _detectedConcepts = [];
  List<DetectedConcept> _manualBodyConcepts = [];
  List<DetectedConcept> _conceptsNeedingConfirmation = [];
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
  List<DetectedConcept> get detectedConcepts => _detectedConcepts;
  List<DetectedConcept> get manualBodyConcepts => _manualBodyConcepts;
  List<DetectedConcept> get conceptsNeedingConfirmation => _conceptsNeedingConfirmation;
  bool          get servicesReady     => _servicesReady;

  // ── Background model initialisation ──────────────────────────────────────

  /// Called from [_AppBootstrap.initState] after the first frame is rendered.
  /// Awaits [EmbeddingService] then [TriageEngine] so the splash screen is
  /// shown while models load. Sets [servicesReady] = true when both are done.
  Future<void> initializeServices() async {
    try {
      await EmbeddingService.instance.initialize();
      await TriageEngine.instance.initialize();
    } catch (e, st) {
      debugPrint('[TriageProvider] initializeServices ERROR: $e\n$st');
      // Still mark ready so the app does not hang on the splash indefinitely.
      // The triage engine will throw a StateError if called before init,
      // which will surface as an empty result rather than a crash.
    }
    _servicesReady = true;
    notifyListeners();
  }


  void setLanguage(String lang) {
    _selectedLanguage = lang;
    notifyListeners();
  }

  void addManualBodyConcepts(List<DetectedConcept> concepts) {
    _manualBodyConcepts.addAll(concepts);
    notifyListeners();
  }

  List<String> get confirmationQuestions {
    final questions = _conceptsNeedingConfirmation.map((c) => c.getQuestionForLang(_selectedLanguage)).toList();
    questions.add(AppStrings.get('safety_net_q', _selectedLanguage)); // Mandatory safety net
    return questions;
  }

  void startSession(SessionModel session) {
    _currentSession = session;
    _transcribedText = '';
    _currentResult = null;
    _detectedConcepts = [];
    _manualBodyConcepts = [];
    _conceptsNeedingConfirmation = [];
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
      
      // Merge with manual body concepts avoiding duplicates
      for (var manualConcept in _manualBodyConcepts) {
        if (!_detectedConcepts.any((c) => c.conceptKey == manualConcept.conceptKey)) {
          _detectedConcepts.add(manualConcept);
        }
      }
      
      _conceptsNeedingConfirmation = [];
      for (final concept in _detectedConcepts) {
        if (!concept.requiresConfirmation) {
          concept.confirmed = true;
        } else {
          _conceptsNeedingConfirmation.add(concept);
        }
      }
    } catch (e) {
      debugPrint('Error analyzing text: $e');
      _detectedConcepts = [];
      _conceptsNeedingConfirmation = [];
    }
    
    _currentConfirmationStep = 0;
    _confirmationAnswers.clear();
    for (int i = 0; i < confirmationQuestions.length; i++) {
      _confirmationAnswers.add(null);
    }
    
    _isProcessing = false;
    notifyListeners();
  }

  void setDetectedConcepts(List<DetectedConcept> concepts) {
    _detectedConcepts = concepts;
    _conceptsNeedingConfirmation = [];
    for (final concept in _detectedConcepts) {
      if (!concept.requiresConfirmation) {
        concept.confirmed = true;
      } else {
        _conceptsNeedingConfirmation.add(concept);
      }
    }
    _currentConfirmationStep = 0;
    _confirmationAnswers.clear();
    for (int i = 0; i < confirmationQuestions.length; i++) {
      _confirmationAnswers.add(null);
    }
    notifyListeners();
  }

  String get currentQuestion => confirmationQuestions[_currentConfirmationStep];
  bool get isLastQuestion => _currentConfirmationStep == confirmationQuestions.length - 1;

  void answerConfirmation(bool answer) {
    _confirmationAnswers[_currentConfirmationStep] = answer;
    
    // Also update the underlying concept, unless it's the safety net question
    if (_conceptsNeedingConfirmation.isNotEmpty && _currentConfirmationStep < _conceptsNeedingConfirmation.length) {
      _conceptsNeedingConfirmation[_currentConfirmationStep].confirmed = answer;
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
      final confirmedConceptsList = _detectedConcepts.where((c) => c.confirmed).map((c) => c.conceptKey).toList();
      
      _currentSession = _currentSession!.copyWith(
        isCompleted: true,
        confirmedConcepts: confirmedConceptsList,
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
  
  void escalateToRed() {
    if (_currentResult == null || _currentSession == null) return;
    
    // Update Result
    _currentResult = _currentResult!.copyWith(
      category: TriageCategory.red,
      requiresReferral: true,
      recommendation: 'Immediate referral required.',
      recommendationHindi: 'तुरंत अस्पताल भेजें — यह गंभीर मामला है।',
    );
    
    // Add "Worker Escalated" to reasons if not present
    if (!_currentResult!.matchedSymptoms.contains('मरीज की हालत गंभीर (Worker Flagged)')) {
       _currentResult!.matchedSymptoms.add('मरीज की हालत गंभीर (Worker Flagged)');
    }
    
    DatabaseService.instance.insertTriageResult(_currentResult!);
    
    // Update Session
    _currentSession = _currentSession!.copyWith(
      triageLevel: TriageCategory.red.name,
    );
    DatabaseService.instance.updateSession(_currentSession!);
    
    notifyListeners();
  }

  void updateSession(SessionModel updatedSession) {
    if (_currentSession?.id == updatedSession.id) {
      _currentSession = updatedSession;
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
    _manualBodyConcepts = [];
    _conceptsNeedingConfirmation = [];
    _currentConfirmationStep = 0;
    _confirmationAnswers.clear();
    notifyListeners();
  }
}
