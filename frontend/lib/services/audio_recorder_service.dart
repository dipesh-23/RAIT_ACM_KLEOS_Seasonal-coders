import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioRecorderService {
  static final AudioRecorderService instance = AudioRecorderService._internal();
  AudioRecorderService._internal();

  AudioRecorder _audioRecorder = AudioRecorder();
  String? _recordingPath;

  Future<bool> initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      return false;
    }
    return true;
  }

  Future<void> startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        _recordingPath = '${dir.path}/triage_audio_${DateTime.now().millisecondsSinceEpoch}.wav';
        
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            bitRate: 16000,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: _recordingPath!,
        );
      }
    } catch (e) {
      print("Error starting record: $e");
    }
  }

  Future<String?> stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      if (path != null && File(path).existsSync()) {
        return path;
      }
      return _recordingPath;
    } catch (e) {
      print("Error stopping record: $e");
      return null;
    }
  }

  Future<bool> isRecording() async {
    return await _audioRecorder.isRecording();
  }

  void dispose() {
    _audioRecorder.dispose();
    _audioRecorder = AudioRecorder(); // Recreate for future use
  }
}
