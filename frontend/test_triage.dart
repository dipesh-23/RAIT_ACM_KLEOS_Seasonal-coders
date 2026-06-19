import 'dart:io';
import 'package:asha_triage/services/triage_engine.dart';
import 'package:flutter/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EmbeddingService.instance.initialize();
  await TriageEngine.instance.initialize();
  
  final res = TriageEngine.instance.detectConcepts("chest pain");
  print("Results for 'chest pain':");
  for (var c in res) {
    print("${c.conceptKey} : ${c.similarity}");
  }

  final res2 = TriageEngine.instance.detectConcepts("no keyword for chest pain");
  print("\nResults for 'no keyword for chest pain':");
  for (var c in res2) {
    print("${c.conceptKey} : ${c.similarity}");
  }
}
