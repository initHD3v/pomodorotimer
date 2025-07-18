import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'pomodoro_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute(
      '''
      CREATE TABLE pomodoro_sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        taskType TEXT,
        focusArea TEXT,
        durationSeconds INTEGER,
        startTime INTEGER,
        endTime INTEGER,
        status TEXT
      )
      '''
    );
  }

  Future<int> insertPomodoroSession(Map<String, dynamic> session) async {
    Database db = await _instance.database;
    try {
      return await db.insert('pomodoro_sessions', session);
    } catch (e) {
      print("Error inserting session: $e");
      return -1; // Indicate error
    }
  }

  Future<int> updatePomodoroSession(Map<String, dynamic> session) async {
    Database db = await _instance.database;
    int id = session['id'];
    try {
      return await db.update(
        'pomodoro_sessions',
        session,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print("Error updating session: $e");
      return 0; // Indicate error
    }
  }

  Future<List<Map<String, dynamic>>> getPomodoroSessions() async {
    Database db = await _instance.database;
    try {
      return await db.query('pomodoro_sessions', orderBy: 'startTime DESC');
    } catch (e) {
      print("Error getting sessions: $e");
      return []; // Return empty list on error
    }
  }
}