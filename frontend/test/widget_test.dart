import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:asha_triage/providers/triage_provider.dart';
import 'package:asha_triage/screens/session_start_screen.dart';

void main() {
  testWidgets('Session start screen renders Hindi text', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TriageProvider(),
        child: const MaterialApp(
          home: SessionStartScreen(),
        ),
      ),
    );
    expect(find.text('नया मरीज'), findsOneWidget);
  });
}
