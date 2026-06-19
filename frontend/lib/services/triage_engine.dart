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
  ///   'phrase'   → String
  ///   'category' → String ("RED" | "YELLOW" | "GREEN")
  ///   'weight'   → int
  ///   'hindi'    → String
  final List<Map<String, dynamic>> _anchors = [];

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

    // ── 1. Load and parse clinical_anchors.json ──────────────────────────────
    final rawJson = await rootBundle
        .loadString('assets/anchors/clinical_anchors.json');
    final Map<String, dynamic> data =
        jsonDecode(rawJson) as Map<String, dynamic>;

    // ── 2. Flatten all three categories into _anchors ────────────────────────
    for (final category in ['RED', 'YELLOW', 'GREEN']) {
      final entries = data[category] as List<dynamic>;
      for (final entry in entries) {
        final concept = entry as Map<String, dynamic>;
        _anchors.add({
          'phrase':   concept['phrase']  as String,
          'category': category,
          'weight':   concept['weight']  as int,
          'hindi':    concept['hindi']   as String,
        });
      }
    }

    // ── 3. Pre-compute embeddings for every anchor phrase ────────────────────
    for (final anchor in _anchors) {
      final phrase = anchor['phrase'] as String;
      _anchorEmbeddings[phrase] =
          EmbeddingService.instance.getEmbedding(phrase);
    }

    _isInitialized = true;
  }

  // ── Utility methods ──────────────────────────────────────────────────────────

  /// Computes the cosine similarity between two vectors [a] and [b].
  ///
  /// Unlike a dot-product shortcut, this divides by the product of both L2
  /// norms so it works correctly with non-normalised vectors too.
  /// Returns 0.0 if either vector has a zero norm (avoids division by zero).
  double cosine(List<double> a, List<double> b) {
    double dot   = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dot   += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    normA = math.sqrt(normA);
    normB = math.sqrt(normB);

    if (normA == 0.0 || normB == 0.0) return 0.0;

    // Clamp to [-1, 1] to guard against floating-point drift
    return (dot / (normA * normB)).clamp(-1.0, 1.0);
  }

  /// Splits [transcript] into overlapping evaluation chunks.
  ///
  /// Splitting boundaries: commas, Hindi danda (।), Hindi double-danda (॥),
  /// full stops, exclamation marks, and question marks.
  ///
  /// Post-processing:
  ///   - Trims and discards chunks whose word count is fewer than 2.
  ///   - Deduplicates while preserving order.
  ///   - Always appends the full original [transcript] as the last element so
  ///     concepts that span multiple sub-clauses are still caught.
  List<String> splitIntoChunks(String transcript) {
    final raw = transcript.trim();

    // Split on sentence/clause boundaries
    final parts = raw.split(RegExp(r'[,।॥.!?]+'));

    final chunks = <String>{}; // LinkedHashSet preserves insertion order
    for (final part in parts) {
      final chunk = part.trim();
      // Keep only chunks that contain at least 2 whitespace-separated words
      if (chunk.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length >= 2) {
        chunks.add(chunk);
      }
    }

    final result = chunks.toList();

    // Always append the full transcript last so cross-clause concepts are caught
    if (result.isEmpty || result.last != raw) {
      result.add(raw);
    }

    return result;
  }

  /// Scores [transcript] against all anchors and returns a [TriageResult].
  ///
  /// For each anchor whose cosine similarity exceeds [threshold] a
  /// [DetectedConcept] is created (unconfirmed). The final triage level is
  /// determined by the highest-weight confirmed concept after the ASHA worker
  /// responds to confirmation questions.
  ///
  /// Throws [StateError] if [initialize] has not been called first.
  List<DetectedConcept> detectConcepts(
    String transcript, {
    double threshold = 0.40,
  }) {
    if (!_isInitialized) {
      throw StateError(
        'TriageEngine is not initialised. '
        'Await TriageEngine.instance.initialize() before calling detectConcepts().',
      );
    }

    final transcriptEmbedding =
        EmbeddingService.instance.getEmbedding(transcript);

    final detected = <DetectedConcept>[];

    for (final anchor in _anchors) {
      final phrase    = anchor['phrase']   as String;
      final category  = anchor['category'] as String;
      final weight    = anchor['weight']   as int;
      final hindi     = anchor['hindi']    as String;

      final anchorEmb = _anchorEmbeddings[phrase]!;
      final similarity = cosine(transcriptEmbedding, anchorEmb);

      if (similarity >= threshold) {
        detected.add(DetectedConcept(
          conceptKey:           phrase,
          category:             category,
          similarity:           similarity,
          weight:               weight,
          hindiLabel:           hindi,
          confirmationQuestion: confirmationQuestions[phrase] ??
              confirmationQuestions['__unknown__']!,
        ));
      }
    }

    // Return highest-similarity concepts first
    detected.sort((a, b) => b.similarity.compareTo(a.similarity));
    return detected;
  }

  /// Derives the final triage level from a list of worker-confirmed concepts.
  ///
  /// Priority: RED > YELLOW > GREEN. Ties broken by highest weight.
  /// Returns "GREEN" if [confirmed] is empty.
  static String resolveLevel(List<DetectedConcept> confirmed) {
    if (confirmed.isEmpty) return 'GREEN';
    if (confirmed.any((c) => c.category == 'RED'))    return 'RED';
    if (confirmed.any((c) => c.category == 'YELLOW')) return 'YELLOW';
    return 'GREEN';
  }

  // ── Context modifiers ─────────────────────────────────────────────────────────

  /// Adjusts a raw cosine [similarity] score upward based on patient context.
  ///
  /// Rules (additive, capped at 1.0):
  /// | ageGroup          | boost  | Rationale                              |
  /// |-------------------|--------|----------------------------------------|
  /// | "newborn"/"infant"| +0.08  | Neonates deteriorate faster            |
  /// | "elderly"         | +0.05  | Higher baseline risk                   |
  /// | "child"           | +0.03  | Paediatric reserve lower than adults   |
  ///
  /// | duration          | boost  | Rationale                              |
  /// |-------------------|--------|----------------------------------------|
  /// | contains "week"   | +0.07  | Prolonged symptoms raise urgency       |
  /// | contains "day"    | +0.04  | Multi-day illness more serious         |
  /// | contains "hour"   | +0.02  | Acute onset, slight boost              |
  double applyModifiers(
    double similarity, {
    required String ageGroup,
    required String duration,
  }) {
    double boost = 0.0;

    // ── Age-group modifier ───────────────────────────────────────────────────
    final age = ageGroup.toLowerCase().trim();
    if (age == 'newborn' || age == 'infant') {
      boost += 0.08;
    } else if (age == 'elderly') {
      boost += 0.05;
    } else if (age == 'child') {
      boost += 0.03;
    }

    // ── Duration modifier ────────────────────────────────────────────────────
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

  // ── Public analysis API ───────────────────────────────────────────────────────

  /// Analyses [transcript] in context of [ageGroup] and [duration] and
  /// returns the top-3 most clinically relevant [DetectedConcept]s.
  ///
  /// Algorithm:
  ///   1. Splits [transcript] into overlapping chunks via [splitIntoChunks].
  ///   2. Embeds every chunk with [EmbeddingService.instance.getEmbedding].
  ///   3. For each anchor, takes the **maximum** cosine similarity across
  ///      all chunk embeddings (best-match semantics).
  ///   4. Applies [applyModifiers] to that maximum score.
  ///   5. Keeps only concepts whose adjusted score is ≥ 0.50.
  ///   6. Sorts: RED before YELLOW before GREEN; within each band,
  ///      descending by adjusted similarity.
  ///   7. Returns at most the top 3 results.
  ///
  /// Throws [StateError] if [initialize] has not been called first.
  List<DetectedConcept> analyzeText(
    String transcript,
    String ageGroup,
    String duration,
  ) {
    if (!_isInitialized) {
      throw StateError(
        'TriageEngine is not initialised. '
        'Await TriageEngine.instance.initialize() before calling analyzeText().',
      );
    }

    // ── 1. Split transcript into evaluation chunks ───────────────────────────
    final chunks = splitIntoChunks(transcript);

    // ── 2. Embed every chunk (full transcript is always the last chunk) ───────
    final chunkEmbeddings = chunks
        .map(EmbeddingService.instance.getEmbedding)
        .toList();

    // ── 3-5. Score every anchor against all chunks ───────────────────────────
    const double threshold = 0.50;
    final detected = <DetectedConcept>[];

    for (final anchor in _anchors) {
      final phrase   = anchor['phrase']   as String;
      final category = anchor['category'] as String;
      final weight   = anchor['weight']   as int;
      final hindi    = anchor['hindi']    as String;

      final anchorEmb = _anchorEmbeddings[phrase]!;

      // Maximum cosine similarity across all chunk embeddings
      double maxSimilarity = 0.0;
      for (final chunkEmb in chunkEmbeddings) {
        final sim = cosine(chunkEmb, anchorEmb);
        if (sim > maxSimilarity) maxSimilarity = sim;
      }

      // Apply age/duration context modifiers
      final adjusted = applyModifiers(
        maxSimilarity,
        ageGroup: ageGroup,
        duration: duration,
      );

      if (adjusted >= threshold) {
        detected.add(DetectedConcept(
          conceptKey:           phrase,
          category:             category,
          similarity:           adjusted,
          weight:               weight,
          hindiLabel:           hindi,
          confirmationQuestion: confirmationQuestions[phrase] ??
              confirmationQuestions['__unknown__']!,
        ));
      }
    }

    // ── 6. Sort: RED > YELLOW > GREEN, then by similarity descending ──────────
    const _categoryOrder = {'RED': 0, 'YELLOW': 1, 'GREEN': 2};
    detected.sort((a, b) {
      final catCmp = (_categoryOrder[a.category] ?? 3)
          .compareTo(_categoryOrder[b.category] ?? 3);
      if (catCmp != 0) return catCmp;
      return b.similarity.compareTo(a.similarity); // within band: highest first
    });

    // ── 7. Return top 3 ───────────────────────────────────────────────────────
    return detected.take(3).toList();
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

  // ── Helpers ───────────────────────────────────────────────────────────────────

  /// Generates a random 6-digit alphanumeric session code (uppercase + digits).
  String _generateSessionCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng   = math.Random();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
