import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const _keyOnboardingDone = 'onboarding_done';
  static const _keyWorkerName     = 'worker_name';
  static const _keyLanguage       = 'language';

  static OnboardingService? _instance;
  static OnboardingService get instance => _instance ??= OnboardingService._();
  OnboardingService._();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool get isOnboardingDone => _prefs.getBool(_keyOnboardingDone) ?? false;

  Future<void> completeOnboarding(String workerName, {String language = 'hi'}) async {
    await _prefs.setBool(_keyOnboardingDone, true);
    await _prefs.setString(_keyWorkerName, workerName);
    await _prefs.setString(_keyLanguage, language);
  }

  String get workerName => _prefs.getString(_keyWorkerName) ?? 'ASHA कार्यकर्ता';
  String get language   => _prefs.getString(_keyLanguage) ?? 'hi';

  Future<void> reset() async => _prefs.clear();
}
