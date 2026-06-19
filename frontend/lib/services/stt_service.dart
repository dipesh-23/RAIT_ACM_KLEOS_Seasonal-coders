import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:vosk_flutter/vosk_flutter.dart';
import 'noise_suppressor.dart';

class SttService {
  static final SttService instance = SttService._();
  SttService._();

  final VoskFlutterPlugin _vosk = VoskFlutterPlugin.instance();
  final Map<String, Model> _loadedModels = {};
  Model? _activeModel;
  String? _activeLocale;

  Recognizer? _recognizer;

  // AudioRecorder from the `record` package (v5.0.4).
  // Provides a Stream<Uint8List> of raw PCM-16 mono audio that we feed
  // manually into the Vosk recognizer via acceptWaveformBytes().
  final AudioRecorder _audioRecorder = AudioRecorder();

  // Subscription held when audio is being captured so we can cancel it cleanly.
  StreamSubscription<Uint8List>? _audioStreamSubscription;

  // Noise suppressor — reset at the start of every session.
  final NoiseSuppressor _noiseSuppressor = NoiseSuppressor();

  // Exposes the calibration state so the UI can show a calibration banner.
  final ValueNotifier<bool> isCalibratedNotifier = ValueNotifier<bool>(false);

  // Guards against concurrent chunk processing — if Vosk is still handling
  // the previous chunk when a new one arrives, drop the new one rather than
  // letting async calls pile up (which causes stale, delayed transcription).
  bool _processingChunk = false;

  bool _isListening = false;
  bool _isStarting = false; // Guard against concurrent startListening calls

  final StreamController<String> _transcriptController =
      StreamController<String>.broadcast();
  final ValueNotifier<bool> isListeningNotifier = ValueNotifier<bool>(false);

  Stream<String> get transcriptStream => _transcriptController.stream;
  bool get isListening => _isListening;

  bool _isInitialized = false;

  Function(String)? _currentOnError;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  Future<bool> initialize({String locale = 'hi-IN'}) async {
    String assetPath;
    String modelKey;
    if (locale.startsWith('en')) {
      assetPath = 'assets/vosk/vosk-model-small-en-us-0.15.zip';
      modelKey = 'en-US';
    } else {
      assetPath = 'assets/vosk/vosk-model-small-hi-0.22.zip';
      modelKey = 'hi-IN';
    }

    if (_loadedModels.containsKey(modelKey)) {
      _activeModel = _loadedModels[modelKey];
      _activeLocale = modelKey;
      _isInitialized = true;
      return true;
    }

    try {
      debugPrint('[VOSK] Extracting $modelKey model from assets...');
      final modelLoader = ModelLoader();
      final modelPath = await modelLoader.loadFromAssets(assetPath);
      debugPrint('[VOSK] Model extracted to: $modelPath');

      final newModel = await _vosk.createModel(modelPath);
      _loadedModels[modelKey] = newModel;
      _activeModel = newModel;
      _activeLocale = modelKey;
      debugPrint('[VOSK] Model $modelKey created successfully!');

      _isInitialized = true;
    } catch (e) {
      debugPrint('[VOSK] Initialization failed: $e');
      _isInitialized = false;
      _currentOnError?.call('Vosk Init Error ($modelKey): $e');
    }
    return _isInitialized;
  }

  // ---------------------------------------------------------------------------
  // Listening lifecycle
  // ---------------------------------------------------------------------------

  Future<void> startListening({
    String locale = 'hi-IN',
    Function(String)? onError,
    void Function(String activeLocale)? onLocaleResolved,
  }) async {
    if (_isStarting) {
      debugPrint('[VOSK] startListening already in progress, skipping.');
      return;
    }
    _isStarting = true;
    _currentOnError = onError;

    // Prompt 9: reset noise suppressor so each session re-calibrates.
    _noiseSuppressor.reset();
    isCalibratedNotifier.value = false;

    try {
      await initialize(locale: locale);

      if (!_isInitialized || _activeModel == null) {
        debugPrint('[VOSK] Not initialized, aborting startListening.');
        return;
      }

      if (_isListening) {
        debugPrint('[VOSK] Already listening — stopping before restart.');
        await stopListening();
      }

      await _cleanupRecognizer();

      debugPrint(
          '[VOSK] Starting listener for locale: $locale (model: $_activeLocale)');

      // Create Vosk recognizer — bytes are fed manually via AudioRecorder stream.
      _recognizer = await _vosk.createRecognizer(
        model: _activeModel!,
        sampleRate: 16000,
      );

      onLocaleResolved?.call(_activeLocale ?? 'hi-IN');

      // Start raw PCM stream.
      final audioStream = await startAudioCapture();

      _audioStreamSubscription = audioStream.listen((rawBytes) async {
        if (_recognizer == null) return;
        // Drop this chunk if Vosk is still processing the previous one.
        if (_processingChunk) return;
        _processingChunk = true;

        // Pipe through noise suppressor (speech frames pass unchanged).
        final Uint8List cleanedBytes = _noiseSuppressor.process(rawBytes);

        // Update calibration banner.
        if (_noiseSuppressor.isCalibrated && !isCalibratedNotifier.value) {
          isCalibratedNotifier.value = true;
        }

        try {
          final bool isFinal =
              await _recognizer!.acceptWaveformBytes(cleanedBytes);

          if (isFinal) {
            final text = parseFinal(await _recognizer!.getFinalResult());
            if (text.isNotEmpty) pushTranscript(text);
          } else {
            final partial =
                parsePartial(await _recognizer!.getPartialResult());
            if (partial.isNotEmpty) pushTranscript(partial);
          }
        } catch (e) {
          debugPrint('[VOSK] chunk processing error: $e');
        } finally {
          _processingChunk = false;
        }
      }, onError: (e) {
        debugPrint('[VOSK] Audio stream error: $e');
        onError?.call('Audio stream error: $e');
      });

      _isListening = true;
      isListeningNotifier.value = true;
      debugPrint('[VOSK] Listening started (noise-suppressed PCM feed mode).');
    } catch (e) {
      debugPrint('[VOSK] startListening failed: $e');
      onError?.call('Failed to start microphone: $e');
      _isListening = false;
      isListeningNotifier.value = false;
      await _cleanupRecognizer();
    } finally {
      _isStarting = false;
    }
  }

  Future<String> stopListening() async {
    if (!_isListening) return '';

    _isListening = false;
    isListeningNotifier.value = false;
    debugPrint('[VOSK] Stopping listener...');

    // Flush remaining audio.
    try {
      if (_recognizer != null) {
        final text = parseFinal(await _recognizer!.getFinalResult());
        if (text.isNotEmpty) pushTranscript(text);
      }
    } catch (_) {}

    await _cleanupRecognizer();
    isCalibratedNotifier.value = false;
    return '';
  }

  // ---------------------------------------------------------------------------
  // Audio capture
  // ---------------------------------------------------------------------------

  /// Starts the [AudioRecorder] with PCM-16 mono at 16 kHz / 256 kbps and
  /// returns the raw [Uint8List] byte stream.
  Future<Stream<Uint8List>> startAudioCapture() async {
    debugPrint('[AUDIO] Starting audio capture...');
    const config = RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
      bitRate: 256000,
    );
    final stream = await _audioRecorder.startStream(config);
    debugPrint('[AUDIO] Audio capture started (PCM-16, 16 kHz, mono, 256 kbps).');
    return stream;
  }

  /// Stops the [AudioRecorder] and cancels any active stream subscription.
  Future<void> stopAudioCapture() async {
    debugPrint('[AUDIO] Stopping audio capture...');
    await _cancelAudioStream();
    debugPrint('[AUDIO] Audio capture stopped.');
  }

  // ---------------------------------------------------------------------------
  // Result parsing — Prompt 7
  // ---------------------------------------------------------------------------

  /// Extracts the `partial` field from a Vosk partial-result JSON string.
  /// Returns an empty string if the key is missing or blank.
  String parsePartial(String json) {
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return (decoded['partial'] as String? ?? '').trim();
    } catch (_) {
      return '';
    }
  }

  /// Extracts the `text` field from a Vosk final-result JSON string.
  /// Returns an empty string if the key is missing or blank.
  String parseFinal(String json) {
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return (decoded['text'] as String? ?? '').trim();
    } catch (_) {
      return '';
    }
  }

  // ---------------------------------------------------------------------------
  // Transcript
  // ---------------------------------------------------------------------------

  void pushTranscript(String text) {
    if (!_transcriptController.isClosed) {
      _transcriptController.add(text);
    }
  }

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  Future<void> _cleanupRecognizer() async {
    if (_recognizer == null && !(await _audioRecorder.isRecording())) return;

    debugPrint('[VOSK] Cleaning up recognizer and audio recorder...');
    await _cancelAudioStream();

    try {
      await _recognizer?.dispose();
    } catch (e) {
      debugPrint('[VOSK] recognizer.dispose() error (ignored): $e');
    }
    _recognizer = null;
    _processingChunk = false;

    debugPrint('[VOSK] Cleanup complete.');
  }

  /// Internal helper — cancels the subscription and stops the recorder.
  Future<void> _cancelAudioStream() async {
    try {
      await _audioStreamSubscription?.cancel();
    } catch (e) {
      debugPrint('[AUDIO] subscription cancel error (ignored): $e');
    }
    _audioStreamSubscription = null;

    try {
      await _audioRecorder.stop();
    } catch (e) {
      debugPrint('[AUDIO] audioRecorder.stop() error (ignored): $e');
    }
  }

  void dispose() {
    _transcriptController.close();
    _audioRecorder.dispose();
    _recognizer?.dispose();
    isCalibratedNotifier.dispose();
    for (final model in _loadedModels.values) {
      model.dispose();
    }
    _loadedModels.clear();
  }
}
