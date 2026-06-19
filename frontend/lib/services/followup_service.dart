import 'database_service.dart';

class FollowupService {
  Future<void> createFollowupRecord(
    String sessionCode,
    String workerName,
    String triageLevel,
    String referralDate,
  ) async {
    await DatabaseService.instance.insertFollowupRecord({
      'session_code': sessionCode,
      'worker_name': workerName,
      'triage_level': triageLevel,
      'referral_date': referralDate,
      'reached_hospital': 0,
      'treatment_received': 0,
      'returned_home': 0,
      'followup_notes': '',
      'last_updated': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateStatus(
    String sessionCode,
    bool reachedHospital,
    bool treatmentReceived,
    bool returnedHome,
  ) async {
    await DatabaseService.instance.updateFollowupStatus(
        sessionCode, reachedHospital, treatmentReceived, returnedHome);
  }

  Future<List<Map<String, dynamic>>> getPendingFollowups(String workerName) async {
    return await DatabaseService.instance.getPendingFollowups(workerName);
  }

  Future<Map<String, int>> getFollowupStats(String workerName) async {
    final followups = await DatabaseService.instance.getAllFollowups(workerName);
    int total = followups.length;
    int reached = 0;
    int treated = 0;
    int returned = 0;
    int pending = 0;

    for (var f in followups) {
      bool isReached = f['reached_hospital'] == 1;
      bool isTreated = f['treatment_received'] == 1;
      bool isReturned = f['returned_home'] == 1;
      if (isReached) reached++;
      if (isTreated) treated++;
      if (isReturned) returned++;
      if (!isReached || !isTreated || !isReturned) {
        pending++;
      }
    }

    return {
      'total_referred': total,
      'reached_hospital': reached,
      'treatment_received': treated,
      'returned_home': returned,
      'pending_count': pending,
    };
  }
}
