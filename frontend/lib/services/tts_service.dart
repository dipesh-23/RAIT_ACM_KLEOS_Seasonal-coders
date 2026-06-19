import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/triage_result.dart';

class TtsService {
  static final TtsService instance = TtsService._();
  TtsService._();

  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _tts = FlutterTts();

  Future<void> playTriageResult(TriageCategory category, String lang) async {
    try {
      await _player.stop();
      await _tts.stop();

      final prefix = category.name;
      final file = 'audio/$lang/$prefix.mp3';

      try {
        await _player.play(AssetSource(file));
        debugPrint('[TTS] Playing $file');
      } catch (e) {
        debugPrint('[TTS] Audio file not found or failed, falling back to TTS: $e');
        await _fallbackTts(category, lang);
      }
    } catch (e) {
      debugPrint('[TTS] Error: $e');
    }
  }

  Future<void> _fallbackTts(TriageCategory category, String lang) async {
    String text;
    String locale;

    if (lang == 'mr') {
      locale = 'mr-IN';
      switch (category) {
        case TriageCategory.red: text = 'त्वरित रुग्णालयात पाठवा. हे गंभीर प्रकरण आहे.'; break;
        case TriageCategory.yellow: text = 'उद्या प्राथमिक आरोग्य केंद्रात घेऊन जा. तपासणी आवश्यक आहे.'; break;
        case TriageCategory.green: text = 'घरी विश्रांती घ्या. दोन दिवस लक्ष ठेवा.'; break;
      }
    } else if (lang == 'en') {
      locale = 'en-US';
      switch (category) {
        case TriageCategory.red: text = 'Immediate referral required. This is critical.'; break;
        case TriageCategory.yellow: text = 'Visit PHC within twenty four hours. Checkup required.'; break;
        case TriageCategory.green: text = 'Home care. Monitor for two days.'; break;
      }
    } else {
      locale = 'hi-IN';
      switch (category) {
        case TriageCategory.red: text = 'तुरंत अस्पताल भेजें. यह गंभीर मामला है.'; break;
        case TriageCategory.yellow: text = 'कल पी एच सी में ले जाएं. जांच जरूरी है.'; break;
        case TriageCategory.green: text = 'घर पर आराम करें. दो दिन निगरानी रखें.'; break;
      }
    }

    await _tts.setLanguage(locale);
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _player.stop();
    await _tts.stop();
  }

  void dispose() {
    _player.dispose();
  }
}
