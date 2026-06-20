import 'package:uuid/uuid.dart';

enum TriageCategory { red, yellow, green }

class TriageResult {
  final String id;
  final String sessionId;
  final TriageCategory category;
  final String transcribedText;
  final double confidenceScore;
  final List<String> matchedSymptoms;
  final String recommendation;
  final String recommendationHindi;
  final DateTime createdAt;
  final bool requiresReferral;

  TriageResult({
    String? id,
    required this.sessionId,
    required this.category,
    required this.transcribedText,
    required this.confidenceScore,
    required this.matchedSymptoms,
    required this.recommendation,
    required this.recommendationHindi,
    DateTime? createdAt,
    this.requiresReferral = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  String get categoryLabel {
    switch (category) {
      case TriageCategory.red:    return 'गंभीर (Red)';
      case TriageCategory.yellow: return 'सतर्क (Yellow)';
      case TriageCategory.green:  return 'सामान्य (Green)';
    }
  }

  String categoryLabelForLang(String lang) {
    if (lang == 'hi') return categoryLabel;
    if (lang == 'mr') {
      switch (category) {
        case TriageCategory.red:    return 'गंभीर (Red)';
        case TriageCategory.yellow: return 'सतर्क (Yellow)';
        case TriageCategory.green:  return 'सामान्य (Green)';
      }
    }
    switch (category) {
      case TriageCategory.red:    return 'Critical (Red)';
      case TriageCategory.yellow: return 'Caution (Yellow)';
      case TriageCategory.green:  return 'Normal (Green)';
    }
  }

  String getRecommendationForLang(String lang) {
    if (lang == 'hi') return recommendationHindi;
    if (lang == 'mr') {
      switch (category) {
        case TriageCategory.red:    return 'त्वरित रुग्णालयात पाठवा — हे गंभीर प्रकरण आहे.';
        case TriageCategory.yellow: return 'उद्या PHC मध्ये घेऊन जा — तपासणी आवश्यक आहे.';
        case TriageCategory.green:  return 'घरी विश्रांती घ्या — २ दिवस लक्ष ठेवा.';
      }
    }
    return recommendation;
  }

  String audioFileForLang(String lang) {
    final prefix = category.name;
    if (lang == 'mr') return 'assets/audio/mr/${prefix}.mp3';
    if (lang == 'en') return 'assets/audio/en/${prefix}.mp3';
    return 'assets/audio/hi/${prefix}.mp3';
  }

  String get audioFile {
    switch (category) {
      case TriageCategory.red:    return 'assets/audio/red_hindi.mp3';
      case TriageCategory.yellow: return 'assets/audio/yellow_hindi.mp3';
      case TriageCategory.green:  return 'assets/audio/green_hindi.mp3';
    }
  }

  TriageResult copyWith({
    String? id,
    String? sessionId,
    TriageCategory? category,
    String? transcribedText,
    double? confidenceScore,
    List<String>? matchedSymptoms,
    String? recommendation,
    String? recommendationHindi,
    DateTime? createdAt,
    bool? requiresReferral,
  }) {
    return TriageResult(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      category: category ?? this.category,
      transcribedText: transcribedText ?? this.transcribedText,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      matchedSymptoms: matchedSymptoms ?? List.from(this.matchedSymptoms),
      recommendation: recommendation ?? this.recommendation,
      recommendationHindi: recommendationHindi ?? this.recommendationHindi,
      createdAt: createdAt ?? this.createdAt,
      requiresReferral: requiresReferral ?? this.requiresReferral,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'session_id': sessionId,
    'category': category.name,
    'transcribed_text': transcribedText,
    'confidence_score': confidenceScore,
    'matched_symptoms': matchedSymptoms.join('|'),
    'recommendation': recommendation,
    'recommendation_hindi': recommendationHindi,
    'created_at': createdAt.toIso8601String(),
    'requires_referral': requiresReferral ? 1 : 0,
  };

  factory TriageResult.fromMap(Map<String, dynamic> map) => TriageResult(
    id: map['id'],
    sessionId: map['session_id'],
    category: TriageCategory.values.firstWhere((e) => e.name == map['category']),
    transcribedText: map['transcribed_text'],
    confidenceScore: map['confidence_score'],
    matchedSymptoms: (map['matched_symptoms'] as String).split('|'),
    recommendation: map['recommendation'],
    recommendationHindi: map['recommendation_hindi'],
    createdAt: DateTime.parse(map['created_at']),
    requiresReferral: map['requires_referral'] == 1,
  );
}
