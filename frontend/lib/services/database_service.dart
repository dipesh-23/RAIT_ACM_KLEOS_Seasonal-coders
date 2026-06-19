import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/session_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'asha_triage.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_code TEXT NOT NULL,
            worker_name TEXT,
            patient_age_group TEXT,
            symptom_duration TEXT,
            raw_transcription TEXT,
            confirmed_concepts TEXT,
            triage_level TEXT,
            timestamp TEXT,
            referral_generated INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }

  Future<void> initDatabase() async {
    await database;
  }

  Future<int> insertSession(SessionModel session) async {
    final db = await database;
    return db.insert('sessions', session.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<SessionModel>> getAllSessions() async {
    final db = await database;
    final maps = await db.query('sessions', orderBy: 'id DESC');
    return maps.map((m) => SessionModel.fromMap(m)).toList();
  }

  Future<SessionModel?> getSessionByCode(String code) async {
    final db = await database;
    final maps = await db.query(
      'sessions',
      where: 'session_code = ?',
      whereArgs: [code],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return SessionModel.fromMap(maps.first);
  }

  Future<void> markReferralGenerated(String sessionCode) async {
    final db = await database;
    await db.update(
      'sessions',
      {'referral_generated': 1},
      where: 'session_code = ?',
      whereArgs: [sessionCode],
    );
  }
}
