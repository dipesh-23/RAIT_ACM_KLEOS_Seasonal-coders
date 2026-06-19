import 'package:flutter_test/flutter_test.dart';
import 'package:asha_triage/services/embedding_service.dart';
import 'package:asha_triage/services/triage_engine.dart';
import 'package:asha_triage/models/triage_result.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await EmbeddingService.instance.initialize();
    await TriageEngine.instance.initialize();
  });

  test('full triage flow test', () {
    const transcript = 'पांच साल का बच्चा दो दिन से तेज बुखार सांस लेने में बहुत तकलीफ';
    
    final concepts = TriageEngine.instance.analyzeText(
      transcript,
      'CHILD',
      '2-3DAYS',
    );

    expect(concepts.isNotEmpty, isTrue, reason: 'Expected at least one concept to be detected');
    expect(concepts.first.category, equals('RED'), reason: 'First concept should be RED severity');

    // Set confirmed to true on all returned concepts
    for (var concept in concepts) {
      concept.confirmed = true;
    }

    final result = TriageEngine.instance.scoreTriage(
      concepts: concepts,
      safetyNetTriggered: false,
      sessionId: 'integration_test_session',
      transcribedText: transcript,
      ageGroup: 'CHILD',
      duration: '2-3DAYS',
    );

    expect(result.category, equals(TriageCategory.red), reason: 'Final triage result should be RED');

    print('INTEGRATION TEST PASSED ${result.sessionId}');
  });
}
