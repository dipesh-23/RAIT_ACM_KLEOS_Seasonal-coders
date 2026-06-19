import 'database_service.dart';

class FollowupService {
  static final FollowupService instance = FollowupService._();
  FollowupService._();

  Future<List<Map<String, dynamic>>> getPendingFollowups() async {
    return await DatabaseService.instance.getPendingFollowups();
  }

  Future<void> updateStatus({
    required String sessionCode,
    required bool reachedHospital,
    required bool treatmentReceived,
    required bool returnedHome,
    required String notes,
  }) async {
    final now = DateTime.now().toIso8601String();
    await DatabaseService.instance.updateFollowupStatus(sessionCode, {
      'reached_hospital': reachedHospital ? 1 : 0,
      'treatment_received': treatmentReceived ? 1 : 0,
      'returned_home': returnedHome ? 1 : 0,
      'followup_notes': notes,
      'last_updated': now,
    });
  }

  Future<void> registerFollowup({
    required String sessionCode,
    required String workerName,
    required String triageLevel,
    required String referralDate,
  }) async {
    final now = DateTime.now().toIso8601String();
    await DatabaseService.instance.insertFollowupRecord({
      'session_code': sessionCode,
      'worker_name': workerName,
      'triage_level': triageLevel,
      'referral_date': referralDate,
      'reached_hospital': 0,
      'treatment_received': 0,
      'returned_home': 0,
      'followup_notes': '',
      'last_updated': now,
    });
  }
}
