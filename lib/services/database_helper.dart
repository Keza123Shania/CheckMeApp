import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users(
        email TEXT PRIMARY KEY,
        password TEXT NOT NULL
      )
    ''');

    // Seed dummy users
    await db.insert('users', {'email':'alice@example.com','password':'wonderland'});
    await db.insert('users', {'email':'bob@riverpod.dev','password':'provider123'});

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

  // Authentication
  Future<bool> login(String email, String password) async {
    final db = await database;
    final res = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    return res.isNotEmpty;
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