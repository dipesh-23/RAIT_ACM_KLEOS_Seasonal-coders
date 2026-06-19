import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

class WhisperService {
  static final WhisperService instance = WhisperService._internal();
  WhisperService._internal();

  Whisper? _whisper;
  bool _isInitialized = false;

  Future<void> initModel() async {
    if (_isInitialized) return;
    try {
      // 1. Copy model from assets to app directory
      final dir = await getApplicationDocumentsDirectory();
      final modelPath = '${dir.path}/ggml-base.bin';
      
      if (!File(modelPath).existsSync()) {
        final byteData = await rootBundle.load('assets/model/ggml-base.bin');
        final file = File(modelPath);
        await file.writeAsBytes(byteData.buffer.asUint8List());
      }

      // 2. Initialize Whisper
      _whisper = Whisper(model: WhisperModel.base);
      _isInitialized = true;
    } catch (e) {
      print("Error initializing Whisper: $e");
    }
  }

  /// Transcribes the WAV file at [audioPath]. 
  /// Returns a map with 'text' and 'language'.
  Future<Map<String, String>?> transcribe(String audioPath, {String? expectedLanguage}) async {
    if (!_isInitialized) await initModel();
    if (_whisper == null) return null;

    try {
      // Typically Whisper models expect a language code (e.g., 'hi', 'te', 'mr') or 'auto'.
      final String lang = expectedLanguage?.split('-').first ?? 'auto';
      
      // Transcribe
      final transcriptionResponse = await _whisper!.transcribe(
        transcribeRequest: TranscribeRequest(
          audio: audioPath,
          isTranslate: false,
          language: lang,
        ),
        modelPath: '${(await getApplicationDocumentsDirectory()).path}/ggml-base.bin',
      );

      // Return result
      return {
        'language': lang == 'auto' ? 'detected' : lang,
        'text': transcriptionResponse.text,
      };
    } catch (e) {
      print("Error transcribing audio: $e");
      return null;
    }
  }
}
