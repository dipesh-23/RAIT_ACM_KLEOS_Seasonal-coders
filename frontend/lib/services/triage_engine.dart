import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/triage_result.dart';
import 'embedding_service.dart';

class _AnchorEntry {
  final String key;
  final String concept;
  final String hindiQuestion;
  final String category;
  final double weight;

  _AnchorEntry({
    required this.key,
    required this.concept,
    required this.hindiQuestion,
    required this.category,
    required this.weight,
  });
}

class TriageEngine {
  static final TriageEngine instance = TriageEngine._internal();
  TriageEngine._internal();

  final EmbeddingService _embeddings = EmbeddingService.instance;
  final List<_AnchorEntry> _anchors = [];
  final Map<String, List<double>> _anchorEmbeddings = {};
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    await _loadAnchors();
    await _precomputeEmbeddings();
    _isInitialized = true;
  }

  Future<void> _loadAnchors() async {
    final jsonString =
        await rootBundle.loadString('assets/anchors/clinical_anchors.json');
    final data = json.decode(jsonString) as Map<String, dynamic>;
    final anchors = data['anchors'] as List<dynamic>;

    _anchors.clear();
    for (final a in anchors) {
      _anchors.add(_AnchorEntry(
        key: a['key'] as String,
        concept: a['concept'] as String,
        hindiQuestion: a['hindi_question'] as String,
        category: a['category'] as String,
        weight: (a['weight'] as num).toDouble(),
      ));
    }
  }

  Future<void> _precomputeEmbeddings() async {
    for (final anchor in _anchors) {
      final embedding = await _embeddings.getEmbedding(anchor.concept);
      _anchorEmbeddings[anchor.key] = embedding;
    }
  }

  double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;
    double dot = 0.0, normA = 0.0, normB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    final denom = sqrt(normA) * sqrt(normB);
    if (denom == 0.0) return 0.0;
    return (dot / denom).clamp(0.0, 1.0);
  }

  /// Analyses transcript and returns top-3 detected concepts for confirmation.
  Future<List<DetectedConcept>> analyzeText(
      String transcript, String ageGroup, String duration) async {
    if (!_embeddings.isInitialized) {
      // Fallback: keyword matching when TFLite model not available
      return _keywordFallback(transcript, ageGroup, duration);
    }

    final transcriptEmbedding = await _embeddings.getEmbedding(transcript);
    final results = <DetectedConcept>[];

    for (final anchor in _anchors) {
      final anchorEmbedding = _anchorEmbeddings[anchor.key];
      if (anchorEmbedding == null) continue;

      double similarity = cosineSimilarity(transcriptEmbedding, anchorEmbedding);
      double weight = anchor.weight;

      // Apply age/duration multipliers
      if (ageGroup == 'NEWBORN' && anchor.category == 'RED') {
        weight *= 1.5;
      }
      if (ageGroup == 'ELDERLY' && anchor.key == 'chest_pain') {
        weight *= 1.3;
      }
      if (duration == 'FOUR_PLUS_DAYS' &&
          (anchor.key == 'high_fever_prolonged' ||
              anchor.key == 'mild_fever')) {
        // Escalate prolonged fever toward RED threshold
        weight *= 1.4;
      }

      if (similarity >= 0.65) {
        results.add(DetectedConcept(
          conceptKey: anchor.key,
          hindiQuestion: anchor.hindiQuestion,
          category: anchor.category,
          similarityScore: similarity,
          weight: weight,
        ));
      }
    }

    results.sort((a, b) => b.similarityScore.compareTo(a.similarityScore));
    return results.take(3).toList();
  }

  /// Keyword-based fallback when TFLite model is placeholder.
  List<DetectedConcept> _keywordFallback(
      String transcript, String ageGroup, String duration) {
    final lower = transcript.toLowerCase();
    final results = <DetectedConcept>[];

    final keywords = {
      'breathing_difficulty': ['सांस', 'breath', 'saans', 'respir'],
      'unconscious': ['बेहोश', 'behosh', 'unconscious', 'faint'],
      'seizure': ['दौरा', 'daura', 'seizure', 'convuls', 'fits'],
      'severe_bleeding': ['खून', 'khoon', 'bleed', 'blood'],
      'chest_pain': ['सीने', 'chest', 'seene', 'heart'],
      'newborn_emergency': ['नवजात', 'navjat', 'newborn', 'baby'],
      'labor_complication': ['प्रसव', 'prasav', 'labor', 'delivery'],
      'not_eating_drinking': ['खाना', 'khana', 'eating', 'drinking'],
      'high_fever_prolonged': ['बुखार', 'bukhar', 'fever', 'temperature'],
      'repeated_vomiting': ['उल्टी', 'ulti', 'vomit'],
      'severe_diarrhea': ['दस्त', 'dast', 'diarrhea', 'loose'],
      'pregnancy_concern': ['गर्भ', 'garbh', 'pregnant', 'pregnan'],
      'child_lethargic': ['सुस्त', 'sust', 'letharg', 'weak'],
      'mild_fever': ['हल्का बुखार', 'mild fever'],
      'common_cold': ['सर्दी', 'sardi', 'cold', 'cough', 'jukam'],
    };

    for (final anchor in _anchors) {
      final kws = keywords[anchor.key] ?? [];
      final matched = kws.any((kw) => lower.contains(kw));
      if (matched) {
        double weight = anchor.weight;
        if (ageGroup == 'NEWBORN' && anchor.category == 'RED') weight *= 1.5;
        if (ageGroup == 'ELDERLY' && anchor.key == 'chest_pain') weight *= 1.3;
        results.add(DetectedConcept(
          conceptKey: anchor.key,
          hindiQuestion: anchor.hindiQuestion,
          category: anchor.category,
          similarityScore: 0.75,
          weight: weight,
        ));
      }
    }

    if (results.isEmpty) {
      // Default to mild_fever as safe minimum if nothing detected
      final mild = _anchors.firstWhere((a) => a.key == 'mild_fever');
      results.add(DetectedConcept(
        conceptKey: mild.key,
        hindiQuestion: mild.hindiQuestion,
        category: mild.category,
        similarityScore: 0.5,
        weight: mild.weight,
      ));
    }

    results.sort((a, b) => b.weight.compareTo(a.weight));
    return results.take(3).toList();
  }

  /// Scores confirmed concepts and returns a TriageResult.
  TriageResult scoreTriage(
    List<DetectedConcept> confirmedConcepts,
    String ageGroup,
    String duration,
    String sessionCode, {
    bool forceRed = false,
  }) {
    if (forceRed) {
      return TriageResult(
        level: TriageLevel.red,
        confirmedConcepts: confirmedConcepts,
        hindiReason: 'मरीज की स्थिति गंभीर है। तुरंत जिला अस्पताल रेफर करें।',
        sessionCode: sessionCode,
        timestamp: DateTime.now(),
      );
    }

    double redScore = 0.0;
    double yellowScore = 0.0;

    for (final concept in confirmedConcepts) {
      if (concept.category == 'RED') {
        redScore += concept.weight;
        // Any single RED concept with weight >= 8 → immediate RED
        if (concept.weight >= 8.0) {
          return TriageResult(
            level: TriageLevel.red,
            confirmedConcepts: confirmedConcepts,
            hindiReason:
                'मरीज की स्थिति गंभीर है। तुरंत जिला अस्पताल रेफर करें।',
            sessionCode: sessionCode,
            timestamp: DateTime.now(),
          );
        }
      } else if (concept.category == 'YELLOW') {
        yellowScore += concept.weight;
      }
    }

    if (redScore >= 6.5) {
      return TriageResult(
        level: TriageLevel.red,
        confirmedConcepts: confirmedConcepts,
        hindiReason:
            'मरीज की स्थिति गंभीर है। तुरंत जिला अस्पताल रेफर करें।',
        sessionCode: sessionCode,
        timestamp: DateTime.now(),
      );
    }

    if (yellowScore >= 5.0) {
      return TriageResult(
        level: TriageLevel.yellow,
        confirmedConcepts: confirmedConcepts,
        hindiReason: 'मरीज को आज रेफर करें। स्थिति पर नज़र रखें।',
        sessionCode: sessionCode,
        timestamp: DateTime.now(),
      );
    }

    return TriageResult(
      level: TriageLevel.green,
      confirmedConcepts: confirmedConcepts,
      hindiReason: 'मरीज को स्थानीय देखभाल दी जा सकती है।',
      sessionCode: sessionCode,
      timestamp: DateTime.now(),
    );
  }
}
