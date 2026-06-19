import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;

import 'embedding_service.dart';
import '../models/triage_result.dart';
import '../models/detected_concept.dart';

/// On-device triage engine.
///
/// Loads clinical anchor phrases from `assets/anchors/clinical_anchors.json`,
/// pre-computes their embeddings once at start-up via [EmbeddingService],
/// and then scores any patient transcript against those anchors using cosine
/// similarity to produce a [TriageResult].
class TriageEngine {
  // ── Singleton ────────────────────────────────────────────────────────────────
  TriageEngine._();
  static final TriageEngine instance = TriageEngine._();

  // ── Private state ────────────────────────────────────────────────────────────

  /// Pre-computed embedding for each anchor phrase. Key = phrase string.
  final Map<String, List<double>> _anchorEmbeddings = {};

  /// Flat list of all anchor entries. Each map contains:
  ///   'key'      → String
  ///   'phrase'   → String
  ///   'category' → String ("RED" | "YELLOW" | "GREEN")
  ///   'weight'   → int
  ///   'hindi'    → String
  final List<Map<String, dynamic>> _anchors = [];
  final List<Map<String, dynamic>> _combinationRules = [];
  Map<String, dynamic> _negationPatterns = {};

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // ── Confirmation questions ───────────────────────────────────────────────────

  /// Maps every concept key (phrase) from clinical_anchors.json to a
  /// Hindi yes/no confirmation question for the ASHA worker.
  static const Map<String, String> confirmationQuestions = {
    // ── RED ──────────────────────────────────────────────────────────────────
    'breathing difficulty':
        'क्या मरीज को सांस लेने में तकलीफ है?',
    'unconscious unresponsive':
        'क्या मरीज बेहोश है या जवाब नहीं दे रहा?',
    'seizure convulsion':
        'क्या मरीज को दौरा या ऐंठन हो रही है?',
    'severe bleeding':
        'क्या मरीज को बहुत तेज खून बह रहा है?',
    'chest pain':
        'क्या मरीज के सीने में दर्द हो रहा है?',
    'newborn emergency':
        'क्या नवजात शिशु को कोई आपातकालीन समस्या है?',
    'labor delivery complication':
        'क्या प्रसव या डिलीवरी में कोई जटिलता है?',
    'not eating not drinking':
        'क्या मरीज खाना-पीना पूरी तरह बंद कर चुका है?',

    // ── YELLOW ───────────────────────────────────────────────────────────────
    'high fever many days':
        'क्या मरीज को कई दिनों से तेज बुखार है?',
    'repeated vomiting':
        'क्या मरीज को बार-बार उल्टी हो रही है?',
    'severe diarrhea':
        'क्या मरीज को बहुत ज्यादा दस्त हो रहे हैं?',
    'severe headache':
        'क्या मरीज के सिर में बहुत तेज दर्द है?',
    'pregnancy problem':
        'क्या गर्भावस्था में कोई समस्या आ रही है?',
    'child not active lethargic':
        'क्या बच्चा सुस्त है और सामान्य से कम सक्रिय है?',
    'swelling body':
        'क्या मरीज के शरीर में सूजन है?',

    // ── GREEN ────────────────────────────────────────────────────────────────
    'mild fever':
        'क्या मरीज को हल्का बुखार है?',
    'common cold cough':
        'क्या मरीज को सामान्य सर्दी या खांसी है?',
    'minor body ache':
        'क्या मरीज के शरीर में हल्का दर्द है?',
    'minor stomach ache':
        'क्या मरीज के पेट में हल्का दर्द है?',

    // ── Fallback ─────────────────────────────────────────────────────────────
    '__unknown__':
        'क्या मरीज को यह समस्या हो रही है?',
  };

  // ── Initialisation ───────────────────────────────────────────────────────────

  /// Loads anchors from JSON and pre-computes all embeddings.
  ///
  /// Must be awaited once before calling [score]. Safe to call multiple times
  /// (subsequent calls are no-ops).
  Future<void> initialize() async {
    if (_isInitialized) return;

    final rawJson = await rootBundle.loadString('assets/anchors/clinical_anchors.json');
    final Map<String, dynamic> data = jsonDecode(rawJson) as Map<String, dynamic>;

    final anchorsList = data['anchors'] as List<dynamic>;
    for (final entry in anchorsList) {
      final concept = entry as Map<String, dynamic>;
      _anchors.add({
        'key':      concept['key'] as String,
        'phrase':   concept['concept']  as String,
        'category': concept['category'] as String,
        'weight':   (concept['weight'] as num).toInt(),
        'hindi':    concept['hindi_question'] as String,
      });
    }

    final rulesList = data['combination_rules'] as List<dynamic>;
    for (final rule in rulesList) {
      _combinationRules.add(rule as Map<String, dynamic>);
    }

    _negationPatterns = data['negation_patterns'] as Map<String, dynamic>;
    _isInitialized = true;
  }

  // Helper dictionary for keyword matching (English & Hindi)
  static const Map<String, List<String>> _keywordDictionary = {
    'breathing difficulty': ['breath', 'सांस', 'साँस', 'दम', 'asthma'],
    'unconscious unresponsive': ['unconscious', 'faint', 'बेहोश', 'गिर'],
    'seizure convulsion': ['seizure', 'दौरा', 'दौरे', 'ऐंठन', 'चक्कर'],
    'severe bleeding': ['bleed', 'blood', 'खून', 'रक्त'],
    'chest pain': ['chest', 'heart', 'सीने', 'सीना', 'छाती', 'दर्द'],
    'newborn emergency': ['newborn', 'नवजात', 'पैदा'],
    'labor delivery complication': ['labor', 'delivery', 'प्रसव', 'डिलीवरी'],
    'not eating not drinking': ['eat', 'drink', 'खाना', 'पीना'],
    'high fever many days': ['fever', 'बुखार', 'ताप'],
    'repeated vomiting': ['vomit', 'उल्टी', 'उल्टियां'],
    'severe diarrhea': ['diarrhea', 'दस्त', 'जुलाब'],
    'severe headache': ['headache', 'head', 'सिर', 'सर', 'दर्द'],
    'pregnancy problem': ['pregnancy', 'pregnant', 'गर्भवती', 'गर्भावस्था'],
    'child not active lethargic': ['lethargic', 'सुस्त', 'कमजोर'],
    'swelling body': ['swelling', 'सूजन', 'सूज'],
    'mild fever': ['fever', 'बुखार', 'ताप'],
    'common cold cough': ['cold', 'cough', 'सर्दी', 'खांसी', 'ज़ुकाम'],
    'minor body ache': ['ache', 'pain', 'दर्द', 'बदन', 'शरीर'],
    'minor stomach ache': ['stomach', 'पेट', 'दर्द'],
  };

  /// Keyword-based chunk detection
  List<DetectedConcept> analyzeText(
    String transcript,
    String ageGroup,
    String duration,
  ) {
    if (!_isInitialized) {
      throw StateError('TriageEngine is not initialised.');
    }

    final lowerText = transcript.toLowerCase();
    final detected = <DetectedConcept>[];

    for (final anchor in _anchors) {
      final key = anchor['key'] as String;
      final category = anchor['category'] as String;
      final weight = anchor['weight'] as int;
      final hindi = anchor['hindi'] as String;

      final keywords = _keywordDictionary[key] ?? [key.toLowerCase()];
      bool isMatch = false;
      for (final kw in keywords) {
        if (lowerText.contains(kw)) {
          isMatch = true;
          break;
        }
      }

      if (isMatch) {
        double baseScore = 0.60; 
        final penalizedScore = _applyNegationPenalty(transcript, key, baseScore);
        final adjusted = applyModifiers(penalizedScore, ageGroup: ageGroup, duration: duration);

        if (adjusted >= 0.50) {
          detected.add(DetectedConcept(
            conceptKey: key,
            category: category,
            similarity: adjusted,
            weight: weight,
            hindiLabel: hindi,
            confirmationQuestion: hindi,
          ));
        }
      }
    }

    // Deduplicate fever
    final feverKeys = ['fever_mild', 'fever_high', 'fever_with_seizure'];
    final feverConcepts = detected.where((c) => feverKeys.contains(c.conceptKey)).toList();
    if (feverConcepts.length > 1) {
      feverConcepts.sort((a, b) => b.similarity.compareTo(a.similarity));
      for (int i = 1; i < feverConcepts.length; i++) {
        detected.remove(feverConcepts[i]);
      }
    }

    const categoryOrder = {'RED': 0, 'YELLOW': 1, 'GREEN': 2};
    detected.sort((a, b) {
      final catCmp = (categoryOrder[a.category] ?? 3).compareTo(categoryOrder[b.category] ?? 3);
      if (catCmp != 0) return catCmp;
      return b.similarity.compareTo(a.similarity);
    });

    return detected.take(3).toList();
  }

  // ── Context modifiers ─────────────────────────────────────────────────────────

  double applyModifiers(
    double similarity, {
    required String ageGroup,
    required String duration,
  }) {
    double boost = 0.0;
    final age = ageGroup.toLowerCase().trim();
    if (age == 'newborn' || age == 'infant') {
      boost += 0.08;
    } else if (age == 'elderly') {
      boost += 0.05;
    } else if (age == 'child') {
      boost += 0.03;
    }

    final dur = duration.toLowerCase();
    if (dur.contains('week')) {
      boost += 0.07;
    } else if (dur.contains('day')) {
      boost += 0.04;
    } else if (dur.contains('hour')) {
      boost += 0.02;
    }

    return (similarity + boost).clamp(0.0, 1.0);
  }

  // ── Rule engines ─────────────────────────────────────────────────────────────

  double _applyNegationPenalty(
    String transcript,
    String conceptKey,
    double similarityScore,
  ) {
    if (_negationPatterns.isEmpty) return similarityScore;

    final allNegations = [
      ...(_negationPatterns['hindi'] as List).cast<String>(),
      ...(_negationPatterns['marathi'] as List).cast<String>(),
      ...(_negationPatterns['english'] as List).cast<String>(),
    ];
    final transcriptLower = transcript.toLowerCase();
    for (String negation in allNegations) {
      if (transcriptLower.contains(negation)) {
        return similarityScore - (_negationPatterns['score_reduction'] as num).toDouble();
      }
    }
    return similarityScore;
  }

  Map<String, dynamic>? _applyCombinationRules(
    List<DetectedConcept> confirmedConcepts,
    String ageGroup,
  ) {
    for (final rule in _combinationRules) {
      if (rule['condition'] == 'ageGroup == NEWBORN') {
        if (ageGroup.toUpperCase() == 'NEWBORN' || ageGroup.toUpperCase() == 'INFANT') {
          if (confirmedConcepts.any((c) => c.category == 'YELLOW')) {
            return rule;
          }
        }
      }

      if (rule['concepts'] == null) continue;
      final concepts = rule['concepts'] as List<dynamic>;
      if (concepts.contains('ANY_YELLOW')) {
        continue; // Handled by newborn rule
      }

      int matches = confirmedConcepts
          .where((c) => concepts.contains(c.conceptKey) && c.confirmed)
          .length;

      if (matches >= (rule['minimum_matches'] as num).toInt()) {
        if (rule['escalate_to'] == 'RED') {
          return rule;
        }
      }
    }
    return null;
  }

  // ── Scoring ───────────────────────────────────────────────────────────────────

  /// Converts a list of [concepts] (some worker-confirmed, some not) into a
  /// final [TriageResult].
  ///
  /// **Safety-net fast path**: if [safetyNetTriggered] is `true`, the result
  /// is immediately RED regardless of individual concept scores — used when the
  /// ASHA worker has independently flagged an emergency.
  ///
  /// **Normal scoring** (only confirmed concepts counted):
  ///
  /// | Accumulator | Source                                    |
  /// |-------------|-------------------------------------------|
  /// | `redScore`  | `similarity × weight` for every RED hit   |
  /// | `yellowScore`| `similarity × weight` for every YELLOW hit|
  ///
  /// YELLOW cluster boost: if ≥ 2 YELLOW concepts are confirmed, `yellowScore`
  /// is multiplied by **1.3** (multiple moderate symptoms together raise risk).
  ///
  /// **Level thresholds**:
  /// - `redScore ≥ 6.5`                          → **RED**
  /// - `yellowScore ≥ 5.0` OR `redScore > 0`     → **YELLOW**
  /// - otherwise                                  → **GREEN**
  TriageResult scoreTriage({
    required List<DetectedConcept> concepts,
    required bool safetyNetTriggered,
    required String sessionId,
    required String transcribedText,
    required String ageGroup,
    required String duration,
  }) {
    // ── Safety-net fast path ─────────────────────────────────────────────────
    if (safetyNetTriggered) {
      return TriageResult(
        sessionId: sessionId,
        category: TriageCategory.red,
        transcribedText: transcribedText,
        confidenceScore: 1.0,
        matchedSymptoms: ['मरीज की हालत गंभीर (Worker Flagged)'],
        recommendation: 'Immediate referral required.',
        recommendationHindi: 'तुरंत अस्पताल भेजें — यह गंभीर मामला है।',
        requiresReferral: true,
      );
    }

    // ── Accumulate scores for confirmed concepts only ─────────────────────────
    double redScore    = 0.0;
    double yellowScore = 0.0;
    int    yellowCount = 0;
    final  reasons     = <String>[];

    for (final concept in concepts) {
      if (!concept.confirmed) continue;

      final contribution = concept.similarity * concept.weight;
      reasons.add(concept.hindiLabel);

      switch (concept.category) {
        case 'RED':
          redScore += contribution;
        case 'YELLOW':
          yellowScore += contribution;
          yellowCount++;
        default:
          break; // GREEN concepts do not contribute to urgency scores
      }
    }

    // ── YELLOW cluster boost ─────────────────────────────────────────────────
    if (yellowCount >= 2) {
      yellowScore *= 1.3;
    }

    // ── Age and Duration Multipliers ─────────────────────────────────────────
    double scoreMultiplier = 1.0;
    final age = ageGroup.toLowerCase();
    if (age == 'child' || age == 'elderly') {
      scoreMultiplier += 0.2; // 20% boost for vulnerable age groups
    }

    final dur = duration.toLowerCase();
    if (dur == 'fourplus') {
      scoreMultiplier += 0.3; // 30% boost for prolonged symptoms
    } else if (dur == 'twothreedays') {
      scoreMultiplier += 0.15; // 15% boost for multi-day symptoms
    }

    redScore *= scoreMultiplier;
    yellowScore *= scoreMultiplier;

    // ── Level resolution ─────────────────────────────────────────────────────
    TriageCategory category;
    String rec = '';
    String recHi = '';
    bool reqRef = false;

    if (redScore >= 6.5) {
      category = TriageCategory.red;
      rec = 'Immediate referral required.';
      recHi = 'तुरंत अस्पताल भेजें — यह गंभीर मामला है।';
      reqRef = true;
    } else if (yellowScore >= 5.0 || redScore > 0) {
      category = TriageCategory.yellow;
      rec = 'Visit PHC within 24 hours.';
      recHi = 'कल PHC में ले जाएं — जांच जरूरी है।';
      reqRef = false;
    } else {
      category = TriageCategory.green;
      rec = 'Home care. Monitor for 2 days.';
      recHi = 'घर पर आराम करें — 2 दिन निगरानी रखें।';
      reqRef = false;
    }

    // ── Reason string ────────────────────────────────────────────────────────
    if (reasons.isEmpty) reasons.add('कोई गंभीर लक्षण नहीं मिला');

    // ── Apply Combination Rules ──────────────────────────────────────────────
    final triggeredRule = _applyCombinationRules(concepts, ageGroup);
    if (triggeredRule != null) {
      category = TriageCategory.red;
      rec = 'Immediate referral required.';
      recHi = 'तुरंत अस्पताल भेजें — यह गंभीर मामला है।';
      reqRef = true;
      final ruleReason = triggeredRule['hindi_reason'] as String;
      if (!reasons.contains(ruleReason)) {
        reasons.add(ruleReason);
      }
    }

    return TriageResult(
      sessionId: sessionId,
      category: category,
      transcribedText: transcribedText,
      confidenceScore: (redScore > yellowScore ? redScore : yellowScore).clamp(0.0, 1.0),
      matchedSymptoms: reasons,
      recommendation: rec,
      recommendationHindi: recHi,
      requiresReferral: reqRef,
    );
  }

}
