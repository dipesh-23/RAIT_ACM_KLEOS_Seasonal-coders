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
      version: 3,
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS sessions');
        await db.execute('DROP TABLE IF EXISTS triage_results');
        await _createTables(db);
      },
      onCreate: (db, version) async {
        await _createTables(db);
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
    await db.execute('''
      CREATE TABLE pregnancy_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profile_code TEXT NOT NULL UNIQUE,
        worker_name TEXT NOT NULL,
        mother_name TEXT NOT NULL,
        edd TEXT,
        risk_level TEXT DEFAULT 'LOW',
        visit_count INTEGER DEFAULT 0,
        last_visit_date TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE pregnancy_visits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profile_code TEXT NOT NULL,
        visit_date TEXT NOT NULL,
        gestational_week INTEGER,
        triage_session_code TEXT,
        danger_signs_present TEXT,
        visit_notes TEXT,
        referred INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE followup_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_code TEXT NOT NULL UNIQUE,
        worker_name TEXT,
        triage_level TEXT,
        referral_date TEXT,
        reached_hospital INTEGER DEFAULT 0,
        treatment_received INTEGER DEFAULT 0,
        returned_home INTEGER DEFAULT 0,
        followup_notes TEXT,
        last_updated TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE epidemic_snapshots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        snapshot_date TEXT NOT NULL,
        red_count INTEGER DEFAULT 0,
        yellow_count INTEGER DEFAULT 0,
        green_count INTEGER DEFAULT 0,
        alert_triggered INTEGER DEFAULT 0,
        dominant_concepts TEXT,
        worker_name TEXT
      )
    ''');
  }

  Future<void> insertSession(SessionModel s) async {
    final db = await database;
    await db.insert('sessions', s.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> saveSession({
    required String id,
    required String sessionCode,
    required String workerName,
    required String patientAgeGroup,
    required String symptomDuration,
    required String rawTranscription,
    required String confirmedConcepts,
    required String triageLevel,
    required String timestamp,
    required int referralGenerated,
  }) async {
    final db = await database;
    await db.insert('sessions', {
      'id': id,
      'session_code': sessionCode,
      'asha_worker_name': workerName,
      'patient_age_group': patientAgeGroup,
      'symptom_duration': symptomDuration,
      'transcribed_text': rawTranscription,
      'confirmed_concepts': confirmedConcepts,
      'triage_level': triageLevel,
      'started_at': timestamp,
      'referral_generated': referralGenerated,
      'is_completed': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
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
  }

  Future<List<SessionModel>> getRecentSessions({int limit = 10, String? workerName}) async {
    final db = await database;
    if (workerName != null) {
      final maps = await db.query('sessions',
          where: 'asha_worker_name = ?',
          whereArgs: [workerName],
          orderBy: 'started_at DESC',
          limit: limit);
      return maps.map((m) => SessionModel.fromMap(m)).toList();
    }
    final maps = await db.query('sessions', orderBy: 'started_at DESC', limit: limit);
    return maps.map((m) => SessionModel.fromMap(m)).toList();
  }

  // ── Sessions queries for dashboard ──
  
  Future<List<SessionModel>> getSessionsByWorker(String workerName) async {
    final db = await database;
    final maps = await db.query('sessions', 
        where: 'asha_worker_name = ?', 
        whereArgs: [workerName],
        orderBy: 'started_at DESC');
    return maps.map((m) => SessionModel.fromMap(m)).toList();
  }

  Future<List<SessionModel>> getSessionsInDateRange(
      String workerName, DateTime start, DateTime end) async {
    final db = await database;
    final startIso = start.toIso8601String();
    final endIso = end.toIso8601String();
    final maps = await db.query('sessions',
        where: 'asha_worker_name = ? AND started_at >= ? AND started_at <= ?',
        whereArgs: [workerName, startIso, endIso],
        orderBy: 'started_at DESC');
    return maps.map((m) => SessionModel.fromMap(m)).toList();
  }

  Future<Map<String, int>> getTriageLevelCounts(
      String workerName, DateTime start, DateTime end) async {
    final db = await database;
    final startIso = start.toIso8601String();
    final endIso = end.toIso8601String();
    final maps = await db.rawQuery('''
      SELECT triage_level, COUNT(*) as count 
      FROM sessions 
      WHERE asha_worker_name = ? AND started_at >= ? AND started_at <= ?
      GROUP BY triage_level
    ''', [workerName, startIso, endIso]);
    
    final counts = {'RED': 0, 'YELLOW': 0, 'GREEN': 0};
    for (final row in maps) {
      final level = row['triage_level'] as String?;
      if (level != null && counts.containsKey(level)) {
        counts[level] = (row['count'] as num).toInt();
      }
    }
    return counts;
  }

  // ── Pregnancy methods ──

  Future<String> insertPregnancyProfile(Map<String, dynamic> profile) async {
    final db = await database;
    await db.insert('pregnancy_profiles', profile, conflictAlgorithm: ConflictAlgorithm.replace);
    return profile['profile_code'] as String;
  }

  Future<List<Map<String, dynamic>>> getActivePregnancyProfiles(String workerName) async {
    final db = await database;
    return await db.query('pregnancy_profiles',
        where: 'worker_name = ? AND is_active = 1',
        whereArgs: [workerName],
        orderBy: 'created_at DESC');
  }

  Future<void> updatePregnancyRisk(String profileCode, String risk) async {
    final db = await database;
    await db.update('pregnancy_profiles', {'risk_level': risk},
        where: 'profile_code = ?', whereArgs: [profileCode]);
  }

  Future<void> addPregnancyVisit(Map<String, dynamic> visit) async {
    final db = await database;
    await db.insert('pregnancy_visits', visit);
    final profileCode = visit['profile_code'] as String;
    final visitDate = visit['visit_date'] as String;
    
    await db.rawUpdate('''
      UPDATE pregnancy_profiles 
      SET visit_count = visit_count + 1, last_visit_date = ? 
      WHERE profile_code = ?
    ''', [visitDate, profileCode]);
  }

  Future<List<Map<String, dynamic>>> getPregnancyVisits(String profileCode) async {
    final db = await database;
    return await db.query('pregnancy_visits',
        where: 'profile_code = ?',
        whereArgs: [profileCode],
        orderBy: 'visit_date DESC');
  }

  Future<void> incrementVisitCount(String profileCode) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE pregnancy_profiles 
      SET visit_count = visit_count + 1 
      WHERE profile_code = ?
    ''', [profileCode]);
  }

  // ── Follow-up methods ──

  Future<void> insertFollowupRecord(Map<String, dynamic> record) async {
    final db = await database;
    await db.insert('followup_records', record, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<Map<String, dynamic>>> getPendingFollowups(String workerName) async {
    final db = await database;
    return await db.query('followup_records',
        where: 'worker_name = ? AND (reached_hospital = 0 OR treatment_received = 0 OR returned_home = 0)',
        whereArgs: [workerName],
        orderBy: 'referral_date DESC');
  }

  Future<void> updateFollowupStatus(
      String sessionCode, bool reachedHospital, bool treatmentReceived, bool returnedHome) async {
    final db = await database;
    await db.update('followup_records', {
      'reached_hospital': reachedHospital ? 1 : 0,
      'treatment_received': treatmentReceived ? 1 : 0,
      'returned_home': returnedHome ? 1 : 0,
      'last_updated': DateTime.now().toIso8601String(),
    }, where: 'session_code = ?', whereArgs: [sessionCode]);
  }

  Future<List<Map<String, dynamic>>> getAllFollowups(String workerName) async {
    final db = await database;
    return await db.query('followup_records',
        where: 'worker_name = ?',
        whereArgs: [workerName],
        orderBy: 'referral_date DESC');
  }

  // ── Epidemic methods ──

  Future<List<SessionModel>> getSessionsLast48Hours(String workerName) async {
    final db = await database;
    final startIso = DateTime.now().subtract(const Duration(hours: 48)).toIso8601String();
    final maps = await db.query('sessions',
        where: 'asha_worker_name = ? AND started_at >= ?',
        whereArgs: [workerName, startIso]);
    return maps.map((m) => SessionModel.fromMap(m)).toList();
  }

  Future<void> insertEpidemicSnapshot(Map<String, dynamic> snapshot) async {
    final db = await database;
    await db.insert('epidemic_snapshots', snapshot);
  }

  Future<List<Map<String, dynamic>>> getRecentSnapshots(String workerName, int days) async {
    final db = await database;
    final startIso = DateTime.now().subtract(Duration(days: days)).toIso8601String();
    return await db.query('epidemic_snapshots',
        where: 'worker_name = ? AND snapshot_date >= ?',
        whereArgs: [workerName, startIso],
        orderBy: 'snapshot_date DESC');
  }
}

