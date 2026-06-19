import 'dart:convert';
import 'database_service.dart';
import '../models/session_model.dart';

class DailyCount {
  final DateTime date;
  final int red;
  final int yellow;
  final int green;

  DailyCount({required this.date, required this.red, required this.yellow, required this.green});
}

class DashboardStats {
  final int totalSessions;
  final int redCount;
  final int yellowCount;
  final int greenCount;
  final int referralCount;
  final double avgDecisionTimeSeconds;
  final List<DailyCount> dailyCounts;
  final String topConcept;
  final int pendingFollowups;

  DashboardStats({
    required this.totalSessions,
    required this.redCount,
    required this.yellowCount,
    required this.greenCount,
    required this.referralCount,
    required this.avgDecisionTimeSeconds,
    required this.dailyCounts,
    required this.topConcept,
    required this.pendingFollowups,
  });
}

class DashboardService {
  Future<DashboardStats> getStatsForPeriod(
    String workerName,
    DateTime start,
    DateTime end,
  ) async {
    final sessions = await DatabaseService.instance.getSessionsInDateRange(workerName, start, end);
    final counts = await DatabaseService.instance.getTriageLevelCounts(workerName, start, end);
    final pendingFollowups = await DatabaseService.instance.getPendingFollowups(workerName);

    int referralCount = 0;
    for (var s in sessions) {
      if (s.referralGenerated == true) referralCount++;
    }

    // Build daily counts for last 7 days ending at 'end'
    List<DailyCount> dailyCounts = [];
    for (int i = 6; i >= 0; i--) {
      final day = end.subtract(Duration(days: i));
      int red = 0, yellow = 0, green = 0;
      for (var s in sessions) {
        final sDate = s.startedAt;
        if (sDate.year == day.year && sDate.month == day.month && sDate.day == day.day) {
          if (s.triageLevel == 'RED') red++;
          if (s.triageLevel == 'YELLOW') yellow++;
          if (s.triageLevel == 'GREEN') green++;
        }
      }
      dailyCounts.add(DailyCount(date: day, red: red, yellow: yellow, green: green));
    }

    final topConcept = await getMostCommonConcept(workerName);

    return DashboardStats(
      totalSessions: sessions.length,
      redCount: counts['RED'] ?? 0,
      yellowCount: counts['YELLOW'] ?? 0,
      greenCount: counts['GREEN'] ?? 0,
      referralCount: referralCount,
      avgDecisionTimeSeconds: 0.0,
      dailyCounts: dailyCounts,
      topConcept: topConcept,
      pendingFollowups: pendingFollowups.length,
    );
  }

  Future<DashboardStats> getStatsForToday(String workerName) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return getStatsForPeriod(workerName, start, end);
  }

  Future<DashboardStats> getStatsForThisWeek(String workerName) {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 7));
    return getStatsForPeriod(workerName, start, now);
  }

  Future<DashboardStats> getStatsForThisMonth(String workerName) {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 30));
    return getStatsForPeriod(workerName, start, now);
  }

  Future<String> getMostCommonConcept(String workerName) async {
    final sessions = await DatabaseService.instance.getSessionsByWorker(workerName);
    if (sessions.isEmpty) return 'कोई नहीं';

    Map<String, int> frequencies = {};
    Map<String, String> hindiLabels = {};

    for (var session in sessions) {
      if (session.confirmedConcepts.isNotEmpty) {
        for (var concept in session.confirmedConcepts) {
          frequencies[concept] = (frequencies[concept] ?? 0) + 1;
        }
      }
    }

    if (frequencies.isEmpty) return 'कोई नहीं';

    String topKey = frequencies.keys.first;
    int maxFreq = frequencies[topKey]!;
    for (var key in frequencies.keys) {
      if (frequencies[key]! > maxFreq) {
        maxFreq = frequencies[key]!;
        topKey = key;
      }
    }

    return hindiLabels[topKey] ?? topKey;
  }
}
