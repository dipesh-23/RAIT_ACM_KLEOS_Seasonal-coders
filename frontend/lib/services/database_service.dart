import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/session_model.dart';
import '../models/triage_result.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();
  DatabaseService._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'asha_triage.db');
    return await openDatabase(
      path,
      version: 4,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 4) {
          await _createTablesV4(db);
        }
      },
      onCreate: (db, version) async {
        await _createTables(db);
        await _createTablesV4(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        session_code TEXT NOT NULL,
        asha_worker_name TEXT NOT NULL,
        patient_name TEXT,
        patient_gender TEXT,
        patient_contact TEXT,
        patient_age_group TEXT,
        symptom_duration TEXT,
        transcribed_text TEXT,
        confirmed_concepts TEXT,
        triage_level TEXT,
        started_at TEXT NOT NULL,
        is_completed INTEGER DEFAULT 0,
        referral_generated INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE triage_results (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        category TEXT NOT NULL,
        transcribed_text TEXT NOT NULL,
        confidence_score REAL NOT NULL,
        matched_symptoms TEXT,
        recommendation TEXT,
        recommendation_hindi TEXT,
        created_at TEXT NOT NULL,
        requires_referral INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _createTablesV4(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pregnancy_profiles (
        profile_code TEXT PRIMARY KEY,
        worker_name TEXT,
        patient_name TEXT,
        lmp_date TEXT,
        age_years INTEGER,
        visit_count INTEGER,
        last_visit_date TEXT,
        risk_level TEXT,
        notes TEXT,
        created_at TEXT,
        is_active INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pregnancy_visits (
        profile_code TEXT,
        visit_date TEXT,
        gestational_week INTEGER,
        triage_session_code TEXT,
        danger_signs_present TEXT,
        visit_notes TEXT,
        referred INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS followup_records (
        session_code TEXT PRIMARY KEY,
        worker_name TEXT,
        triage_level TEXT,
        referral_date TEXT,
        reached_hospital INTEGER,
        treatment_received INTEGER,
        returned_home INTEGER,
        followup_notes TEXT,
        last_updated TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS epidemic_snapshots (
        snapshot_date TEXT,
        red_count INTEGER,
        yellow_count INTEGER,
        green_count INTEGER,
        alert_triggered INTEGER,
        dominant_concepts TEXT,
        worker_name TEXT
      )
    ''');
  }

  Future<void> insertSession(SessionModel s) async {
    final db = await database;
    await db.insert('sessions', s.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateSession(SessionModel s) async {
    final db = await database;
    await db.update('sessions', s.toMap(), where: 'id = ?', whereArgs: [s.id]);
  }

  Future<void> insertTriageResult(TriageResult r) async {
    final db = await database;
    await db.insert('triage_results', r.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<TriageResult>> getAllResults() async {
    final db = await database;
    final maps = await db.query('triage_results', orderBy: 'created_at DESC');
    return maps.map((m) => TriageResult.fromMap(m)).toList();
  }

  Future<Map<String, int>> getWorkerStats() async {
    final db = await database;

    try {
      final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM sessions');
      final total = Sqflite.firstIntValue(totalResult) ?? 0;

      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final todayResult = await db.rawQuery(
          "SELECT COUNT(*) as count FROM sessions WHERE started_at LIKE '$todayStr%'");
      final todayCount = Sqflite.firstIntValue(todayResult) ?? 0;

      final monthStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}';
      final monthResult = await db.rawQuery(
          "SELECT COUNT(*) as count FROM sessions WHERE started_at LIKE '$monthStr%'");
      final thisMonth = Sqflite.firstIntValue(monthResult) ?? 0;

      final referralResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM sessions WHERE referral_generated = 1');
      final referrals = Sqflite.firstIntValue(referralResult) ?? 0;

      final criticalResult = await db.rawQuery(
          "SELECT COUNT(*) as count FROM sessions WHERE triage_level = 'RED'");
      final critical = Sqflite.firstIntValue(criticalResult) ?? 0;

      return {
        'total': total,
        'today': todayCount,
        'this_month': thisMonth,
        'referrals': referrals,
        'critical': critical,
      };
    } catch (e) {
      return {
        'total': 0,
        'today': 0,
        'this_month': 0,
        'referrals': 0,
        'critical': 0,
      };
    }
  }

  Future<List<SessionModel>> getRecentSessions({int limit = 10}) async {
    final db = await database;
    try {
      final maps = await db.query('sessions', orderBy: 'started_at DESC', limit: limit);
      return maps.map((m) => SessionModel.fromMap(m)).toList();
    } catch (e) {
      return [];
    }
  }

  // ===== NEW METHODS FOR FEATURES =====

  Future<List<SessionModel>> getSessionsInDateRange(DateTime start, DateTime end) async {
    final db = await database;
    try {
      final startStr = start.toIso8601String();
      final endStr = end.toIso8601String();
      final maps = await db.query(
        'sessions',
        where: 'started_at >= ? AND started_at <= ?',
        whereArgs: [startStr, endStr],
        orderBy: 'started_at DESC',
      );
      return maps.map((m) => SessionModel.fromMap(m)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, int>> getTriageLevelCounts(DateTime start, DateTime end) async {
    final db = await database;
    try {
      final startStr = start.toIso8601String();
      final endStr = end.toIso8601String();
      final results = await db.rawQuery('''
        SELECT triage_level, COUNT(*) as count 
        FROM sessions 
        WHERE started_at >= ? AND started_at <= ? 
        GROUP BY triage_level
      ''', [startStr, endStr]);

      int red = 0;
      int yellow = 0;
      int green = 0;

      for (var row in results) {
        final level = row['triage_level'] as String?;
        final count = row['count'] as int? ?? 0;
        if (level == 'RED') red = count;
        if (level == 'YELLOW') yellow = count;
        if (level == 'GREEN') green = count;
      }

      return {'RED': red, 'YELLOW': yellow, 'GREEN': green};
    } catch (e) {
      return {'RED': 0, 'YELLOW': 0, 'GREEN': 0};
    }
  }

  Future<void> insertPregnancyProfile(Map<String, dynamic> row) async {
    final db = await database;
    try {
      await db.insert('pregnancy_profiles', row, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getActivePregnancyProfiles() async {
    final db = await database;
    try {
      return await db.query('pregnancy_profiles', where: 'is_active = 1', orderBy: 'created_at DESC');
    } catch (e) {
      return [];
    }
  }

  Future<void> updatePregnancyRisk(String profileCode, String riskLevel) async {
    final db = await database;
    try {
      await db.update(
        'pregnancy_profiles',
        {'risk_level': riskLevel},
        where: 'profile_code = ?',
        whereArgs: [profileCode],
      );
    } catch (_) {}
  }

  Future<void> addPregnancyVisit(Map<String, dynamic> row) async {
    final db = await database;
    try {
      await db.transaction((txn) async {
        await txn.insert('pregnancy_visits', row, conflictAlgorithm: ConflictAlgorithm.replace);
        
        final profileCode = row['profile_code'];
        final visitDate = row['visit_date'];
        
        final profiles = await txn.query('pregnancy_profiles', where: 'profile_code = ?', whereArgs: [profileCode]);
        if (profiles.isNotEmpty) {
          final currentCount = (profiles.first['visit_count'] as int? ?? 0) + 1;
          await txn.update(
            'pregnancy_profiles',
            {
              'visit_count': currentCount,
              'last_visit_date': visitDate,
            },
            where: 'profile_code = ?',
            whereArgs: [profileCode],
          );
        }
      });
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getPregnancyVisits(String profileCode) async {
    final db = await database;
    try {
      return await db.query('pregnancy_visits', where: 'profile_code = ?', orderBy: 'visit_date DESC', whereArgs: [profileCode]);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPendingFollowups() async {
    final db = await database;
    try {
      return await db.query('followup_records', where: 'returned_home = 0', orderBy: 'referral_date DESC');
    } catch (e) {
      return [];
    }
  }

  Future<void> insertFollowupRecord(Map<String, dynamic> row) async {
    final db = await database;
    try {
      await db.insert('followup_records', row, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {}
  }

  Future<void> updateFollowupStatus(String sessionCode, Map<String, dynamic> status) async {
    final db = await database;
    try {
      await db.update(
        'followup_records',
        status,
        where: 'session_code = ?',
        whereArgs: [sessionCode],
      );
    } catch (_) {}
  }

  Future<List<SessionModel>> getSessionsLast48Hours() async {
    final db = await database;
    try {
      final cutoff = DateTime.now().subtract(const Duration(hours: 48)).toIso8601String();
      final maps = await db.query(
        'sessions',
        where: 'started_at >= ?',
        whereArgs: [cutoff],
        orderBy: 'started_at DESC',
      );
      return maps.map((m) => SessionModel.fromMap(m)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> insertEpidemicSnapshot(Map<String, dynamic> row) async {
    final db = await database;
    try {
      await db.insert('epidemic_snapshots', row);
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getEpidemicSnapshots() async {
    final db = await database;
    try {
      return await db.query('epidemic_snapshots', orderBy: 'snapshot_date DESC', limit: 30);
    } catch (e) {
      return [];
    }
  }
}
