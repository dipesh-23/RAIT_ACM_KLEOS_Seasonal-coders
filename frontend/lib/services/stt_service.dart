import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

enum OfflineModelStatus {
  available,
  offlineModelMissing,
  languagePackMissing,
  unknown
}

class SttService {
  static final SttService instance = SttService._();
  SttService._();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  final StreamController<String> _transcriptController =
      StreamController<String>.broadcast();
  final ValueNotifier<bool> isListeningNotifier = ValueNotifier<bool>(false);

  Stream<String> get transcriptStream => _transcriptController.stream;
  bool get isListening => _isListening;
  bool _isInitialized = false;

  String _currentLocale = 'hi-IN';
  Function(String)? _currentOnError;
  Function(dynamic)? _testErrorListener;
  Function(String)? _testStatusListener;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speech.initialize(
        onError: (val) {
          debugPrint('================================');
          debugPrint('[STT DEBUG ERROR LOG]:');
          debugPrint('Error Msg: ${val.errorMsg}');
          debugPrint('Permanent: ${val.permanent}');
          debugPrint('================================');
          if (_testErrorListener != null) {
            _testErrorListener!(val);
          }
          _handleGlobalError(val);
        },
        onStatus: (val) {
          debugPrint('[STT DEBUG STATUS LOG]: $val');
          if (val == 'listening') {
            isListeningNotifier.value = true;
            _isListening = true;
          } else if (val == 'notListening' || val == 'done') {
            isListeningNotifier.value = false;
            _isListening = false;
          }
          
          if (_testStatusListener != null) {
            _testStatusListener!(val);
          }
        },
      );
      debugPrint('[STT DEBUG] Service initialized: $_isInitialized');
      if (_isInitialized) {
        final locales = await _speech.locales();
        debugPrint('================================');
        debugPrint('[STT DEBUG] AVAILABLE DEVICE LOCALES:');
        for (var locale in locales) {
          if (locale.localeId.startsWith('hi') || locale.localeId.startsWith('mr') || locale.localeId.startsWith('en')) {
            debugPrint('Locale: ${locale.name} -> ID: ${locale.localeId}');
          }
        }
        debugPrint('================================');
      }
    } catch (e) {
      debugPrint('[STT] Initialization failed: $e');
      _isInitialized = false;
    }
    return _isInitialized;
  }

  void _handleGlobalError(dynamic val) {
    if (val.errorMsg == 'error_language_not_supported') {
      _isListening = false;
      final isMarathi = _currentLocale.toLowerCase().contains('mr');
      final message = isMarathi
          ? "मराठी ऑफलाइन स्पीच मॉडल नहीं मिला। सेटिंग्स में डाउनलोड करें।"
          : "हिंदी ऑफलाइन स्पीच मॉडल नहीं मिला। सेटिंग्स में डाउनलोड करें।";
      if (_currentOnError != null) {
        _currentOnError!(message);
      }
      openSpeechLanguageSettings();
    } else if (val.errorMsg == 'error_language_unavailable' || val.errorMsg == 'error_client') {
      _isListening = false;
      _speech.stop();

      String userMessage = _currentLocale.toLowerCase().contains('mr')
          ? 'ऑफलाइन मॉडल नहीं मिला。\nOffline model not found.\n\nGoogle App → Voice →\nOffline speech recognition →\nDownload Marathi (India)'
          : 'ऑफलाइन मॉडल नहीं मिला。\nOffline model not found.\n\nGoogle App → Voice →\nOffline speech recognition →\nDownload Hindi (India)';

      if (_currentOnError != null) {
        _currentOnError!(userMessage);
      }
    }
  }

  Future<OfflineModelStatus> isLocaleAvailable(String localeId) async {
    try {
      bool initialized = await initialize();
      if (!initialized) return OfflineModelStatus.unknown;

      final completer = Completer<OfflineModelStatus>();

      _testErrorListener = (error) {
        if (!completer.isCompleted) {
          if (error.errorMsg == 'error_language_not_supported') {
            completer.complete(OfflineModelStatus.languagePackMissing);
          } else if (error.errorMsg == 'error_language_unavailable' || error.errorMsg == 'error_client') {
            completer.complete(OfflineModelStatus.offlineModelMissing);
          } else {
            completer.complete(OfflineModelStatus.unknown);
          }
        }
      };

      _testStatusListener = (status) {
        if (status == 'listening' && !completer.isCompleted) {
          completer.complete(OfflineModelStatus.available);
        }
      };

      await _speech.listen(
        onDevice: false,
        localeId: localeId,
        partialResults: true,
      );

      // Wait up to 4 seconds for the engine to either start listening or throw an error
      Timer(const Duration(seconds: 4), () {
        if (!completer.isCompleted) {
          completer.complete(OfflineModelStatus.unknown);
        }
      });

      final result = await completer.future;

      await _speech.stop();

      _testErrorListener = null;
      _testStatusListener = null;

      return result;
    } catch (e) {
      debugPrint('Error testing locale $localeId: $e');
      _testErrorListener = null;
      _testStatusListener = null;
      try {
        await _speech.stop();
      } catch (_) {}
      return OfflineModelStatus.unknown;
    }
  }

  Future<void> openSpeechLanguageSettings() async {
    const channel = MethodChannel('com.asha.triage/settings');
    try {
      await channel.invokeMethod('openSpeechSettings');
    } on PlatformException catch (e) {
      debugPrint('Failed to open speech settings: $e');
    }
  }

  Future<void> openLanguageSettings() async {
    const channel = MethodChannel('com.asha.triage/settings');
    try {
      await channel.invokeMethod('openLanguageSettings');
    } on PlatformException catch (e) {
      debugPrint('[STT] Failed to open language settings: $e');
    }
  }

  Future<void> openInputMethodSettings() async {
    const channel = MethodChannel('com.asha.triage/settings');
    try {
      await channel.invokeMethod('openInputMethodSettings');
    } on PlatformException catch (e) {
      debugPrint('[STT] Failed to open input method settings: $e');
    }
  }

  Future<void> openGoogleOfflineSpeechSettings() async {
    const platform = MethodChannel('com.asha.triage/settings');
    try {
      await platform.invokeMethod('openGoogleOfflineSpeech');
    } catch (e) {
      debugPrint('[STT] Could not open settings: $e');
    }
  }

  // Resolve the best available locale: requested → hi_IN fallback.
  // Returns null if no supported locale is found.
  Future<String?> _resolveLocale(String requested) async {
    final systemLocales = await _speech.locales();
    final ids = systemLocales.map((l) => l.localeId).toSet();

    if (ids.contains(requested)) {
      debugPrint('[STT ACTIVE LOCALE] Using requested locale: $requested');
      return requested;
    }

    // Prompt 5: mr_IN fallback to hi_IN
    if (requested == 'mr_IN') {
      const fallback = 'hi_IN';
      if (ids.contains(fallback)) {
        debugPrint('[STT ACTIVE LOCALE] mr_IN not found — falling back to hi_IN');
        return fallback;
      }
    }

    // No suitable locale found
    debugPrint('[STT ACTIVE LOCALE] No matching locale found for: $requested');
    debugPrint('[STT ACTIVE LOCALE] Available locales: ${ids.where((id) => id.startsWith('hi') || id.startsWith('mr') || id.startsWith('en')).toList()}');
    return null;
  }

  Future<void> startListening({
    String locale = 'hi_IN',
    Function(String)? onError,
    void Function(String activeLocale)? onLocaleResolved,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    if (_isListening || !_isInitialized) return;

    _currentOnError = onError;
    debugPrint('================================');
    debugPrint('[STT DEBUG] Starting listen for locale: $locale');
    debugPrint('================================');

    // Prompt 4 & 5: verify hasDictation, apply fallback
    final activeLocale = await _resolveLocale(locale);
    if (activeLocale == null) {
      debugPrint('[STT] offline_pack_missing — no valid locale for $locale');
      if (onError != null) {
        final isMarathi = locale.contains('mr');
        onError(isMarathi
            ? 'मराठी ऑफलाइन स्पीच पैक नहीं मिला।\nकृपया डिवाइस भाषा सेटिंग्स से जोड़ें।'
            : 'हिंदी ऑफलाइन स्पीच पैक नहीं मिला।\nकृपया डिवाइस भाषा सेटिंग्स से जोड़ें।');
      }
      return;
    }

    _isListening = true;
    isListeningNotifier.value = true;
    _currentLocale = activeLocale;

    // Notify caller of the actual locale used (so TriageProvider can update)
    onLocaleResolved?.call(activeLocale);

    await _speech.listen(
      onResult: (val) {
        debugPrint('[STT DEBUG RESULT]: ${val.recognizedWords}');
        debugPrint('[STT DEBUG FINAL RESULT?]: ${val.finalResult}');
        if (val.recognizedWords.isNotEmpty) {
          pushTranscript(val.recognizedWords);
        }
      },
      onDevice: false,
      localeId: activeLocale,
      cancelOnError: false,
      partialResults: true,
    );
  }

  Future<String> stopListening() async {
    _isListening = false;
    isListeningNotifier.value = false;
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
