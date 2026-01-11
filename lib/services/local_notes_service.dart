import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;

import '../models/note.dart';

class LocalNotesService {
  Database? _db;
  List<Note> _notes = [];

  static final LocalNotesService _shared = LocalNotesService._sharedInstance();
  LocalNotesService._sharedInstance() {
    _notesStreamController = StreamController<List<Note>>.broadcast(
      onListen: () {
        _notesStreamController.sink.add(_notes);
      },
    );
  }
  factory LocalNotesService() => _shared;

  late final StreamController<List<Note>> _notesStreamController;

  Stream<List<Note>> get allNotes => _notesStreamController.stream;

  Future<void> _cacheNotes() async {
    final allNotes = await _getAllNotes();
    _notes = allNotes.toList();
    _notesStreamController.add(_notes);
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
      
      // Create notes table if not exists
      await db.execute(_createNoteTable);
      await _cacheNotes();
    } catch (e) {
      throw Exception('Unable to open database: $e');
    }
  }

  static const _dbName = 'notes.db';
  static const _noteTable = 'note';
  static const _createNoteTable = '''
    CREATE TABLE IF NOT EXISTS "note" (
      "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      "text" TEXT NOT NULL DEFAULT '',
      "created_at" INTEGER NOT NULL
    );
  ''';
}
