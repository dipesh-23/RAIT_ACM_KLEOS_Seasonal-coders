import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../models/triage_result.dart';

class TtsService {
  static final TtsService instance = TtsService._();
  TtsService._();

  final AudioPlayer _player = AudioPlayer();

  Future<void> playTriageResult(TriageCategory category) async {
    try {
      await _player.stop();
      final file = category == TriageCategory.red
          ? 'audio/red_hindi.mp3'
          : category == TriageCategory.yellow
              ? 'audio/yellow_hindi.mp3'
              : 'audio/green_hindi.mp3';
      await _player.play(AssetSource(file));
      debugPrint('[TTS] Playing $file');
    } catch (e) {
      debugPrint('[TTS] Error: $e');
    }
  }

  Future<void> stop() async => _player.stop();

  void dispose() => _player.dispose();
}
