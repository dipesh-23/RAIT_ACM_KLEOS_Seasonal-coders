import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/services.dart';

class OnboardingService {
  static const String _onboardingKey = 'onboarding_complete';
  static const MethodChannel _channel =
      MethodChannel('com.asha.asha_triage/settings');

  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  Future<bool> isHindiLanguagePackAvailable() async {
    try {
      final stt = SpeechToText();
      final available = await stt.initialize(onError: (_) {});
      if (!available) return false;
      final locales = await stt.locales();
      return locales.any((l) =>
          l.localeId.toLowerCase().contains('hi') ||
          l.localeId.toLowerCase().contains('hi_in'));
    } catch (_) {
      return false;
    }
  }

  Future<void> openLanguageSettings() async {
    try {
      await _channel.invokeMethod('openLanguageSettings');
    } on MissingPluginException {
      // Platform channel not set up yet — silently ignore on non-Android
    } catch (_) {
      // Silently ignore any other errors
    }
  }
}
