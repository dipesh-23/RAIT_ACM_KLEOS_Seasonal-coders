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

  String get audioFile {
    switch (category) {
      case TriageCategory.red:    return 'assets/audio/red_hindi.mp3';
      case TriageCategory.yellow: return 'assets/audio/yellow_hindi.mp3';
      case TriageCategory.green:  return 'assets/audio/green_hindi.mp3';
    }
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
