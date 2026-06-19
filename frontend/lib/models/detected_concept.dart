class DetectedConcept {
  final String conceptKey;
  final String category; // 'RED', 'YELLOW', 'GREEN'
  final double similarity;
  final int weight;
  final String hindiLabel;
  final String confirmationQuestion;
  bool confirmed; // mutable so worker can flip it

  DetectedConcept({
    required this.conceptKey,
    required this.category,
    required this.similarity,
    required this.weight,
    required this.hindiLabel,
    required this.confirmationQuestion,
    this.confirmed = false,
  });
}
