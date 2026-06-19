import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/triage_result.dart';

class TtsService {
  static final TtsService instance = TtsService._internal();
  TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _player = AudioPlayer();
  bool _isInitialized = false;

  Future<void> initialize() async {
    try {
      await _tts.setLanguage('hi-IN');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _isInitialized = true;
    } catch (_) {
      _isInitialized = false;
    }
  }

  Future<void> speakResult(TriageLevel level) async {
    final assetPath = _audioPath(level);
    try {
      await _player.stop();
      await _player.play(AssetSource(assetPath));
    } catch (_) {
      // Fallback to TTS if audio file is placeholder or missing
      await speakText(_levelText(level));
    }
  }

  Future<void> speakText(String hindiText) async {
    if (!_isInitialized) await initialize();
    try {
      await _tts.speak(hindiText);
    } catch (_) {
      // Silently fail — speech output is supplementary
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
      await _tts.stop();
    } catch (_) {}
  }

  String _audioPath(TriageLevel level) {
    switch (level) {
      case TriageLevel.red:
        return 'audio/red_hindi.mp3';
      case TriageLevel.yellow:
        return 'audio/yellow_hindi.mp3';
      case TriageLevel.green:
        return 'audio/green_hindi.mp3';
    }
  }

  String _levelText(TriageLevel level) {
    switch (level) {
      case TriageLevel.red:
        return 'मरीज को तुरंत रेफर करें। यह गंभीर स्थिति है।';
      case TriageLevel.yellow:
        return 'मरीज को आज रेफर करें। स्थिति पर नज़र रखें।';
      case TriageLevel.green:
        return 'मरीज को स्थानीय उपचार दिया जा सकता है।';
    }
  }
}
