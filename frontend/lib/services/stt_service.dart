import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SttService {
  static final SttService instance = SttService._();
  SttService._();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  final StreamController<String> _transcriptController =
      StreamController<String>.broadcast();

  Stream<String> get transcriptStream => _transcriptController.stream;
  bool get isListening => _isListening;
  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speech.initialize(
        onError: (val) => debugPrint('[STT Error]: ${val.errorMsg}'),
        onStatus: (val) => debugPrint('[STT Status]: $val'),
      );
      debugPrint('[STT] Service initialized: $_isInitialized');
    } catch (e) {
      debugPrint('[STT] Initialization failed: $e');
      _isInitialized = false;
    }
    return _isInitialized;
  }

  Future<void> startListening({String locale = 'hi-IN'}) async {
    if (!_isInitialized) {
      await initialize();
    }
    if (_isListening || !_isInitialized) return;

    _isListening = true;
    debugPrint('[STT] Started listening...');
    
    await _speech.listen(
      onResult: (val) {
        if (val.recognizedWords.isNotEmpty) {
          pushTranscript(val.recognizedWords);
        }
      },
      localeId: locale,
      cancelOnError: false,
      partialResults: true,
    );
  }

  Future<String> stopListening() async {
    _isListening = false;
    debugPrint('[STT] Stopped listening');
    await _speech.stop();
    return '';
  }

  void pushTranscript(String text) {
    _transcriptController.add(text);
  }

  void dispose() {
    _transcriptController.close();
  }
}
