import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;

import '../models/note.dart';
import '../models/todo.dart';

class LocalNotesService {
  Database? _db;
  List<Note> _notes = [];
  List<Todo> _todos = [];

  static final LocalNotesService _shared = LocalNotesService._sharedInstance();
  LocalNotesService._sharedInstance() {
    _notesStreamController = StreamController<List<Note>>.broadcast(
      onListen: () {
        _notesStreamController.sink.add(_notes);
      },
    );
    _todosStreamController = StreamController<List<Todo>>.broadcast(
      onListen: () {
        _todosStreamController.sink.add(_todos);
      },
    );
  }
  factory LocalNotesService() => _shared;

  late final StreamController<List<Note>> _notesStreamController;
  late final StreamController<List<Todo>> _todosStreamController;

  Stream<List<Note>> get allNotes => _notesStreamController.stream;
  Stream<List<Todo>> get allTodos => _todosStreamController.stream;

  Future<void> _cacheNotes() async {
    final allNotes = await _getAllNotes();
    _notes = allNotes.toList();
    _notesStreamController.add(_notes);
  }

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

  Future<Iterable<Note>> _getAllNotes() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(_noteTable, orderBy: 'created_at DESC');
    return notes.map((noteRow) => Note.fromRow(noteRow));
  }

  Future<Note> createNote() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    final now = DateTime.now();
    final noteId = await db.insert(_noteTable, {
      'text': '',
      'created_at': now.millisecondsSinceEpoch,
    });

    final note = Note(
      id: noteId,
      text: '',
      createdAt: now,
    );

    _notes.insert(0, note);
    _notesStreamController.add(_notes);

    return note;
  }

  Future<Note> getNote({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(
      _noteTable,
      limit: 1,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (notes.isEmpty) {
      throw Exception('Could not find note');
    } else {
      return Note.fromRow(notes.first);
    }
  }

  Future<Note> updateNote({
    required int id,
    required String text,
  }) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    final updatesCount = await db.update(
      _noteTable,
      {'text': text},
      where: 'id = ?',
      whereArgs: [id],
    );

    if (updatesCount == 0) {
      throw Exception('Could not update note');
    }

    final updatedNote = await getNote(id: id);
    _notes.removeWhere((note) => note.id == id);
    _notes.insert(0, updatedNote);
    _notesStreamController.add(_notes);
    return updatedNote;
  }

  Future<void> deleteNote({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      _noteTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (deletedCount == 0) {
      throw Exception('Could not delete note');
    } else {
      _notes.removeWhere((note) => note.id == id);
      _notesStreamController.add(_notes);
    }
  }

  Future<int> deleteAllNotes() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final numberOfDeletions = await db.delete(_noteTable);
    _notes = [];
    _notesStreamController.add(_notes);
    return numberOfDeletions;
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
      await db.execute(_createNoteTable);
      await db.execute(_createTodoTable);
      await _cacheNotes();
      await _cacheTodos();
    } catch (e) {
      throw Exception('Unable to open database: $e');
    }
  }

  static const _dbName = 'notes.db';
  static const _noteTable = 'note';
  static const _todoTable = 'todo';
  static const _createNoteTable = '''
    CREATE TABLE IF NOT EXISTS "note" (
      "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      "text" TEXT NOT NULL DEFAULT '',
      "created_at" INTEGER NOT NULL
    );
  ''';
  static const _createTodoTable = '''
    CREATE TABLE IF NOT EXISTS "todo" (
      "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      "title" TEXT NOT NULL DEFAULT '',
      "is_completed" INTEGER NOT NULL DEFAULT 0,
      "created_at" INTEGER NOT NULL
    );
  ''';
}
