import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;

import '../models/todo.dart';

class LocalNotesService {
  Database? _db;
  List<Todo> _todos = [];

  static final LocalNotesService _shared = LocalNotesService._sharedInstance();
  LocalNotesService._sharedInstance() {
    _todosStreamController = StreamController<List<Todo>>.broadcast(
      onListen: () {
        _todosStreamController.sink.add(_todos);
      },
    );
  }
  factory LocalNotesService() => _shared;

  late final StreamController<List<Todo>> _todosStreamController;

  Stream<List<Todo>> get allTodos => _todosStreamController.stream;

  Future<void> _cacheTodos() async {
    final allTodos = await _getAllTodos();
    _todos = allTodos.toList();
    _todosStreamController.add(_todos);
  }

  Future<Iterable<Todo>> _getAllTodos() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final todos = await db.query(_todoTable, orderBy: 'created_at DESC');
    return todos.map((todoRow) => Todo.fromRow(todoRow));
  }

  // Todo CRUD operations
  Future<Todo> createTodo({required String title}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    final now = DateTime.now();
    final todoId = await db.insert(_todoTable, {
      'title': title,
      'is_completed': 0,
      'created_at': now.millisecondsSinceEpoch,
    });

    final todo = Todo(
      id: todoId,
      title: title,
      isCompleted: false,
      createdAt: now,
    );

    _todos.insert(0, todo);
    _todosStreamController.add(_todos);

    return todo;
  }

  Future<Todo> getTodo({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final todos = await db.query(
      _todoTable,
      limit: 1,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (todos.isEmpty) {
      throw Exception('Could not find todo');
    } else {
      return Todo.fromRow(todos.first);
    }
  }

  Future<Todo> updateTodo({
    required int id,
    required String title,
    required bool isCompleted,
  }) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    final updatesCount = await db.update(
      _todoTable,
      {
        'title': title,
        'is_completed': isCompleted ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    if (updatesCount == 0) {
      throw Exception('Could not update todo');
    }

    final updatedTodo = await getTodo(id: id);
    _todos.removeWhere((todo) => todo.id == id);
    _todos.insert(0, updatedTodo);
    _todosStreamController.add(_todos);
    return updatedTodo;
  }

  Future<Todo> toggleTodoComplete({required int id}) async {
    await _ensureDbIsOpen();
    final todo = await getTodo(id: id);
    return updateTodo(
      id: id,
      title: todo.title,
      isCompleted: !todo.isCompleted,
    );
  }

  Future<void> deleteTodo({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      _todoTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (deletedCount == 0) {
      throw Exception('Could not delete todo');
    } else {
      _todos.removeWhere((todo) => todo.id == id);
      _todosStreamController.add(_todos);
    }
  }

  Future<int> deleteAllTodos() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final numberOfDeletions = await db.delete(_todoTable);
    _todos = [];
    _todosStreamController.add(_todos);
    return numberOfDeletions;
  }

  Database _getDatabaseOrThrow() {
    final db = _db;
    if (db == null) {
      throw Exception('Database is not open');
    } else {
      return db;
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw Exception('Database is not open');
    } else {
      await db.close();
      _db = null;
    }
  }

  Future<void> _ensureDbIsOpen() async {
    try {
      await open();
    } catch (_) {
      // Database already open
    }
  }

  Future<void> open() async {
    if (_db != null) {
      return;
    }
    try {
      final docsPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docsPath.path, _dbName);
      final db = await openDatabase(dbPath);
      _db = db;
      
      // Create tables if not exists
      await db.execute(_createTodoTable);
      await _cacheTodos();
    } catch (e) {
      throw Exception('Unable to open database: $e');
    }
  }

  static const _dbName = 'notes.db';
  static const _todoTable = 'todo';
  static const _createTodoTable = '''
    CREATE TABLE IF NOT EXISTS "todo" (
      "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      "title" TEXT NOT NULL DEFAULT '',
      "is_completed" INTEGER NOT NULL DEFAULT 0,
      "created_at" INTEGER NOT NULL
    );
  ''';
}
