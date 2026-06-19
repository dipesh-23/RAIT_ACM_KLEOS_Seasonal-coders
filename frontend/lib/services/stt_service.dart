import 'dart:async';
import 'package:flutter/foundation.dart';

/// STT Service stub — integrate with speech_to_text or Vosk for actual offline STT
class SttService {
  static final SttService instance = SttService._();
  SttService._();

  bool _isListening = false;
  final StreamController<String> _transcriptController =
      StreamController<String>.broadcast();

  Stream<String> get transcriptStream => _transcriptController.stream;
  bool get isListening => _isListening;

  Future<bool> initialize() async {
    // In production: initialize Vosk or speech_to_text plugin
    debugPrint('[STT] Service initialized');
    return true;
  }

  Future<void> startListening({String locale = 'hi-IN'}) async {
    if (_isListening) return;
    _isListening = true;
    debugPrint('[STT] Started listening...');
    // TODO: Hook into speech_to_text or Vosk native bridge
  }

  Future<String> stopListening() async {
    _isListening = false;
    debugPrint('[STT] Stopped listening');
    return _transcriptController.hasListener ? '' : '';
  }

  void pushTranscript(String text) {
    _transcriptController.add(text);
  }

  void dispose() {
    _transcriptController.close();
  }
}
