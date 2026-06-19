import 'dart:math';
import 'database_service.dart';

class PregnancyService {
  static const Map<String, List<String>> DANGER_SIGNS_HINDI = {
    '1': ["बहुत ज्यादा उल्टी", "तेज पेट दर्द", "योनि से खून", "बेहोशी"],
    '2': ["सूजन चेहरे पर", "तेज सिरदर्द", "धुंधला दिखना", "कम हलचल शिशु"],
    '3': ["सूजन पैरों में", "उच्च रक्तचाप", "पानी आना", "10 से कम हलचल दिन में", "तेज पेट दर्द"]
  };

  static const Map<String, List<String>> DANGER_SIGNS_ENGLISH = {
    '1': ["Severe vomiting", "Severe abdominal pain", "Vaginal bleeding", "Fainting"],
    '2': ["Face swelling", "Severe headache", "Blurred vision", "Reduced fetal movement"],
    '3': ["Leg swelling", "High blood pressure", "Water breaking", "Less than 10 movements/day", "Severe abdominal pain"]
  };

  String generateProfileCode() {
    final random = Random();
    final code = random.nextInt(90000000) + 10000000;
    return "P$code";
  }

  int calculateGestationalWeek(String lmpDateISO) {
    final lmp = DateTime.parse(lmpDateISO);
    final now = DateTime.now();
    final diff = now.difference(lmp);
    return diff.inDays ~/ 7;
  }

  String calculateTrimester(int weeks) {
    if (weeks <= 12) return "पहली तिमाही / First Trimester";
    if (weeks <= 27) return "दूसरी तिमाही / Second Trimester";
    return "तीसरी तिमाही / Third Trimester";
  }

  DateTime calculateEDD(String lmpDateISO) {
    final lmp = DateTime.parse(lmpDateISO);
    return lmp.add(const Duration(days: 280));
  }

  int calculateDaysToEDD(String lmpDateISO) {
    final edd = calculateEDD(lmpDateISO);
    final now = DateTime.now();
    return edd.difference(now).inDays;
  }

  String assessRisk(List<String> dangerSignsPresent, int gestationalWeek) {
    if (dangerSignsPresent.isNotEmpty) return 'HIGH';
    if (gestationalWeek > 36) return 'HIGH';
    if (gestationalWeek > 28) return 'MEDIUM';
    return 'LOW';
  }

  Future<String> createProfile(
    String workerName,
    String patientName,
    String lmpDate,
    int ageYears,
  ) async {
    final profileCode = generateProfileCode();
    await DatabaseService.instance.insertPregnancyProfile({
      'profile_code': profileCode,
      'worker_name': workerName,
      'patient_name': patientName,
      'lmp_date': lmpDate,
      'age_years': ageYears,
      'visit_count': 0,
      'last_visit_date': null,
      'risk_level': 'LOW',
      'notes': '',
      'created_at': DateTime.now().toIso8601String(),
      'is_active': 1,
    });
    return profileCode;
  }

  Future<void> recordVisit(
    String profileCode,
    List<String> dangerSigns,
    String notes,
    String? triageSessionCode,
    int gestationalWeek,
  ) async {
    final visitDate = DateTime.now().toIso8601String();
    await DatabaseService.instance.addPregnancyVisit({
      'profile_code': profileCode,
      'visit_date': visitDate,
      'gestational_week': gestationalWeek,
      'triage_session_code': triageSessionCode,
      'danger_signs_present': dangerSigns.join('|'),
      'visit_notes': notes,
      'referred': dangerSigns.isNotEmpty ? 1 : 0,
    });

    final risk = assessRisk(dangerSigns, gestationalWeek);
    await DatabaseService.instance.updatePregnancyRisk(profileCode, risk);
  }

  Future<List<Map<String, dynamic>>> getActiveProfiles(String workerName) async {
    return await DatabaseService.instance.getActivePregnancyProfiles(workerName);
  }
}
