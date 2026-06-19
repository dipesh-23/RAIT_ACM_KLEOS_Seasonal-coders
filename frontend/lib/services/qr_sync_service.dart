import 'dashboard_service.dart';

class SyncPayload {
  final String workerName;
  final String periodStart;
  final String periodEnd;
  final int totalSessions;
  final int redCount;
  final int yellowCount;
  final int greenCount;
  final int referralCount;
  final int followupComplete;
  final int pregnancyProfiles;
  final int epidemicAlerts;
  final String appVersion;
  final String generatedAt;

  SyncPayload({
    required this.workerName,
    required this.periodStart,
    required this.periodEnd,
    required this.totalSessions,
    required this.redCount,
    required this.yellowCount,
    required this.greenCount,
    required this.referralCount,
    required this.followupComplete,
    required this.pregnancyProfiles,
    required this.epidemicAlerts,
    required this.appVersion,
    required this.generatedAt,
  });

  String toQrString() {
    return "ASHA|$workerName|$periodStart|$periodEnd|$totalSessions|$redCount|$yellowCount|$greenCount|$referralCount|$followupComplete|$pregnancyProfiles|$epidemicAlerts|$appVersion|$generatedAt";
  }

  static SyncPayload? fromQrString(String qrString) {
    if (!qrString.startsWith("ASHA|")) return null;
    final parts = qrString.split('|');
    if (parts.length < 14) return null;
    
    try {
      return SyncPayload(
        workerName: parts[1],
        periodStart: parts[2],
        periodEnd: parts[3],
        totalSessions: int.parse(parts[4]),
        redCount: int.parse(parts[5]),
        yellowCount: int.parse(parts[6]),
        greenCount: int.parse(parts[7]),
        referralCount: int.parse(parts[8]),
        followupComplete: int.parse(parts[9]),
        pregnancyProfiles: int.parse(parts[10]),
        epidemicAlerts: int.parse(parts[11]),
        appVersion: parts[12],
        generatedAt: parts[13],
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toReadableMap() {
    return {
      'Worker Name': workerName,
      'Period Start': periodStart,
      'Period End': periodEnd,
      'Total Sessions': totalSessions,
      'RED Referrals': redCount,
      'YELLOW Referrals': yellowCount,
      'GREEN Treatments': greenCount,
      'Referral Slips': referralCount,
      'Followups Complete': followupComplete,
      'Pregnancy Profiles': pregnancyProfiles,
      'Epidemic Alerts': epidemicAlerts,
    };
  }
}

class QrSyncService {
  Future<SyncPayload> generatePayload(
    String workerName,
    DateTime periodStart,
    DateTime periodEnd,
  ) async {
    final ds = DashboardService();
    final stats = await ds.getStatsForPeriod(workerName, periodStart, periodEnd);
    
    // Simplification for the payload constraints:
    return SyncPayload(
      workerName: workerName,
      periodStart: periodStart.toIso8601String(),
      periodEnd: periodEnd.toIso8601String(),
      totalSessions: stats.totalSessions,
      redCount: stats.redCount,
      yellowCount: stats.yellowCount,
      greenCount: stats.greenCount,
      referralCount: stats.referralCount,
      followupComplete: 0, // Placeholder
      pregnancyProfiles: 0, // Placeholder
      epidemicAlerts: 0, // Placeholder
      appVersion: "1.0.0",
      generatedAt: DateTime.now().toIso8601String(),
    );
  }

  Future<String> generateQrData(SyncPayload payload) async {
    return payload.toQrString();
  }

  SyncPayload? parseScannedQr(String qrData) {
    return SyncPayload.fromQrString(qrData);
  }
}
