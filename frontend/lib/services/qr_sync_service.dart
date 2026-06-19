class QrSyncService {
  static final QrSyncService instance = QrSyncService._();
  QrSyncService._();

  String serialize({
    required String workerName,
    required DateTime startDate,
    required DateTime endDate,
    required int total,
    required int red,
    required int yellow,
    required int green,
    required int referrals,
    required int followups,
    required int pregnancies,
    required int alerts,
  }) {
    final startStr = '${startDate.year}${startDate.month.toString().padLeft(2, '0')}${startDate.day.toString().padLeft(2, '0')}';
    final endStr = '${endDate.year}${endDate.month.toString().padLeft(2, '0')}${endDate.day.toString().padLeft(2, '0')}';
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    return 'ASHA|$workerName|$startStr|$endStr|$total|$red|$yellow|$green|$referrals|$followups|$pregnancies|$alerts|1.0|$timestamp';
  }

  Map<String, dynamic>? deserialize(String payload) {
    if (!payload.startsWith('ASHA|')) return null;

    final parts = payload.split('|');
    if (parts.length < 14) return null;

    try {
      return {
        'type': parts[0],
        'worker_name': parts[1],
        'start_date_raw': parts[2],
        'end_date_raw': parts[3],
        'total': int.parse(parts[4]),
        'red': int.parse(parts[5]),
        'yellow': int.parse(parts[6]),
        'green': int.parse(parts[7]),
        'referrals': int.parse(parts[8]),
        'followups': int.parse(parts[9]),
        'pregnancies': int.parse(parts[10]),
        'alerts': int.parse(parts[11]),
        'version': parts[12],
        'timestamp': int.parse(parts[13]),
      };
    } catch (_) {
      return null;
    }
  }
}
