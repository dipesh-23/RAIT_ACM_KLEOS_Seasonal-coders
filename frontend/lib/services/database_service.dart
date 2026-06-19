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
      version: 2,
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
}
