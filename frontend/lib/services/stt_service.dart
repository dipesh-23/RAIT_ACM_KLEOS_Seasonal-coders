import 'package:speech_to_text/speech_to_text.dart';

class SttService {
  final SpeechToText _stt = SpeechToText();
  bool _isInitialized = false;

  bool get isListening => _stt.isListening;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    _isInitialized = await _stt.initialize(
      onError: (error) {},
      onStatus: (status) {},
    );
    return _isInitialized;
  }

  Future<void> startListening({
    required String localeId,
    required Function(String text) onResult,
    required Function(String text) onPartialResult,
    required Function(String error) onError,
  }) async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) {
        onError('STT initialization failed');
        return;
      }
    }

    await _stt.listen(
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
        } else {
          onPartialResult(result.recognizedWords);
        }
      },
      localeId: localeId,
      listenOptions: SpeechListenOptions(
        cancelOnError: false,
        partialResults: true,
        listenMode: ListenMode.dictation,
        onDevice: true,
      ),
      onSoundLevelChange: null,
    );
  }

  Future<void> stopListening() async {
    if (_stt.isListening) {
      await _stt.stop();
    }
  }

  Future<List<LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) await initialize();
    return _stt.locales();
  }
}
