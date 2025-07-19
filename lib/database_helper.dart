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
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Add onUpgrade for schema changes
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute(
      '''
      CREATE TABLE pomodoro_sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        startTime INTEGER,
        endTime INTEGER,
        totalWorkDurationSeconds INTEGER,
        status TEXT
      )
      '''
    );
    await db.execute(
      '''
      CREATE TABLE session_tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER,
        taskType TEXT,
        taskDurationSeconds INTEGER,
        actualDurationSeconds INTEGER,
        taskStartTime INTEGER,
        taskEndTime INTEGER,
        taskOrder INTEGER,
        taskStatus TEXT,
        FOREIGN KEY (session_id) REFERENCES pomodoro_sessions (id) ON DELETE CASCADE
      )
      '''
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Drop existing tables if they exist to recreate with new schema
      await db.execute('DROP TABLE IF EXISTS pomodoro_sessions');
      await db.execute('DROP TABLE IF EXISTS session_tasks');
      await _onCreate(db, newVersion);
    }
  }

  Future<int> insertPomodoroSession(Map<String, dynamic> session) async {
    Database db = await _instance.database;
    try {
      return await db.insert('pomodoro_sessions', session, conflictAlgorithm: ConflictAlgorithm.replace);
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
        conflictAlgorithm: ConflictAlgorithm.replace,
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

  Future<int> deleteAllPomodoroSessions() async {
    Database db = await _instance.database;
    try {
      await db.delete('pomodoro_sessions');
      await db.delete('session_tasks'); // Also delete tasks
      return 1;
    } catch (e) {
      print("Error deleting all sessions: $e");
      return 0; // Indicate error
    }
  }

  Future<int> deletePomodoroSession(int id) async {
    Database db = await _instance.database;
    try {
      await db.delete(
        'pomodoro_sessions',
        where: 'id = ?',
        whereArgs: [id],
      );
      await db.delete(
        'session_tasks',
        where: 'session_id = ?',
        whereArgs: [id],
      ); // Also delete associated tasks
      return 1;
    } catch (e) {
      print("Error deleting session: $e");
      return 0; // Indicate error
    }
  }

  // New CRUD operations for session_tasks
  Future<int> insertSessionTask(Map<String, dynamic> task) async {
    Database db = await _instance.database;
    try {
      return await db.insert('session_tasks', task, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      print("Error inserting session task: $e");
      return -1;
    }
  }

  Future<int> updateSessionTask(Map<String, dynamic> task) async {
    Database db = await _instance.database;
    int id = task['id'];
    try {
      return await db.update(
        'session_tasks',
        task,
        where: 'id = ?',
        whereArgs: [id],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print("Error updating session task: $e");
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getTasksForSession(int sessionId) async {
    Database db = await _instance.database;
    try {
      return await db.query(
        'session_tasks',
        where: 'session_id = ?',
        whereArgs: [sessionId],
        orderBy: 'taskOrder ASC',
      );
    } catch (e) {
      print("Error getting tasks for session: $e");
      return [];
    }
  }
}