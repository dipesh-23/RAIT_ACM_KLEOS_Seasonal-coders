enum TriageLevel { red, yellow, green }

class DetectedConcept {
  final String conceptKey;
  final String hindiQuestion;
  final String category;
  final double similarityScore;
  final double weight;
  bool confirmed;

  DetectedConcept({
    required this.conceptKey,
    required this.hindiQuestion,
    required this.category,
    required this.similarityScore,
    required this.weight,
    this.confirmed = false,
  });

  DetectedConcept copyWith({
    String? conceptKey,
    String? hindiQuestion,
    String? category,
    double? similarityScore,
    double? weight,
    bool? confirmed,
  }) {
    return DetectedConcept(
      conceptKey: conceptKey ?? this.conceptKey,
      hindiQuestion: hindiQuestion ?? this.hindiQuestion,
      category: category ?? this.category,
      similarityScore: similarityScore ?? this.similarityScore,
      weight: weight ?? this.weight,
      confirmed: confirmed ?? this.confirmed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conceptKey': conceptKey,
      'hindiQuestion': hindiQuestion,
      'category': category,
      'similarityScore': similarityScore,
      'weight': weight,
      'confirmed': confirmed,
    };
  }

  factory DetectedConcept.fromMap(Map<String, dynamic> map) {
    return DetectedConcept(
      conceptKey: map['conceptKey'] as String,
      hindiQuestion: map['hindiQuestion'] as String,
      category: map['category'] as String,
      similarityScore: (map['similarityScore'] as num).toDouble(),
      weight: (map['weight'] as num).toDouble(),
      confirmed: map['confirmed'] as bool? ?? false,
    );
  }
}

class TriageResult {
  final TriageLevel level;
  final List<DetectedConcept> confirmedConcepts;
  final String hindiReason;
  final String sessionCode;
  final DateTime timestamp;

  TriageResult({
    required this.level,
    required this.confirmedConcepts,
    required this.hindiReason,
    required this.sessionCode,
    required this.timestamp,
  });

  String get levelString {
    switch (level) {
      case TriageLevel.red:
        return 'RED';
      case TriageLevel.yellow:
        return 'YELLOW';
      case TriageLevel.green:
        return 'GREEN';
    }
  }

  String get levelHindi {
    switch (level) {
      case TriageLevel.red:
        return 'तुरंत रेफर करें';
      case TriageLevel.yellow:
        return 'आज रेफर करें';
      case TriageLevel.green:
        return 'स्थानीय उपचार';
    }
  }
}
