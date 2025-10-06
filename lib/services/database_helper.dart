import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:developer';

class DatabaseHelper {
  static final instance = DatabaseHelper._init();
  static Database? _db;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB('checkme.db');
    return _db!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(path, version: 2, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users(
        email TEXT PRIMARY KEY,
        password TEXT NOT NULL,
        name TEXT,
        avatarUrl TEXT
      )
    ''');

    // Todos table
    await db.execute('''
      CREATE TABLE todos(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        isDone INTEGER NOT NULL,
        creationDate TEXT NOT NULL,
        dueDate TEXT,
        category TEXT NOT NULL,
        userEmail TEXT NOT NULL
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE users ADD COLUMN name TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN avatarUrl TEXT');
    }
  }


  // Authentication
  Future<bool> login(String email, String password) async {
    final db = await database;
    final res = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    final isValid = res.isNotEmpty;
    log('DB_HELPER: Login attempt for $email. Valid: $isValid');
    return isValid;
  }

  // New: Method to update user password
  Future<bool> updateUserPassword(String email, String oldPassword, String newPassword) async {
    final db = await database;

    // 1. Verify old password first
    final res = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, oldPassword],
    );

    if (res.isEmpty) {
      log('DB_HELPER: Failed password update for $email. Invalid old password.');
      return false;
    }

    // 2. Update with new password
    final count = await db.update(
      'users',
      {'password': newPassword},
      where: 'email = ?',
      whereArgs: [email],
    );

    log('DB_HELPER: Password update for $email success: ${count > 0}');
    return count > 0;
  }


  // User CRUD
  Future<Map<String, dynamic>?> getUser(String email) async {
    final db = await database;
    final res = await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (res.isNotEmpty) {
      return res.first;
    }
    return null;
  }

  Future<void> updateUser(Map<String, dynamic> user) async {
    final db = await database;
    await db.update('users', user, where: 'email = ?', whereArgs: [user['email']]);
  }


  // Todos CRUD
  Future<List<Map<String,Object?>>> fetchTodos(String userEmail) async {
    final db = await database;
    return db.query(
      'todos',
      where: 'userEmail = ?',
      whereArgs: [userEmail],
      orderBy: 'creationDate DESC',
    );
  }

  Future<void> deleteAllTodos(String userEmail) async {
    final db = await database;
    await db.delete(
      'todos',
      where: 'userEmail = ?',
      whereArgs: [userEmail],
    );
  }

  Future<bool> insertUser(String email, String password) async {
    final db = await database;
    try {
      await db.insert('users', {'email': email, 'password': password, 'name': 'New User'});
      log('DB_HELPER: User $email successfully registered.');
      return true;
    } catch (e) {
      // likely a UNIQUE constraint failure for existing email
      log('DB_HELPER: Registration failed for $email. Error: $e');
      return false;
    }
  }

  Future<void> insertTodo(Map<String,Object?> todo) async {
    final db = await database;
    await db.insert('todos', todo);
  }
  Future<void> updateTodo(Map<String,Object?> todo) async {
    final db = await database;
    await db.update('todos', todo, where: 'id = ?', whereArgs: [todo['id']]);
  }
  Future<void> deleteTodo(String id) async {
    final db = await database;
    await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }
}
