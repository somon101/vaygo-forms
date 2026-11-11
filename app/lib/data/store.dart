import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'form_record.dart';

const _uuid = Uuid();
String newId() => _uuid.v4();

/// Локальное хранилище анкет (SQLite на телефоне). Удаление «мягкое».
class FormStore extends ChangeNotifier {
  FormStore._();
  static final instance = FormStore._();

  late Database _db;

  Future<void> open() async {
    final path = p.join(await getDatabasesPath(), 'forms.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE forms(
          id TEXT PRIMARY KEY,
          type TEXT,
          title TEXT,
          data TEXT,
          status TEXT,
          pdf_path TEXT,
          created_at INTEGER,
          updated_at INTEGER,
          deleted INTEGER DEFAULT 0
        )'''),
    );
  }

  Future<List<FormRecord>> forms() async {
    final rows = await _db.query('forms',
        where: 'deleted = 0', orderBy: 'updated_at DESC');
    return rows.map(FormRecord.fromMap).toList();
  }

  Future<FormRecord?> formById(String id) async {
    final rows = await _db.query('forms',
        where: 'id = ? AND deleted = 0', whereArgs: [id]);
    return rows.isEmpty ? null : FormRecord.fromMap(rows.first);
  }

  Future<void> saveForm(FormRecord f) async {
    f.updatedAt = DateTime.now();
    await _db.insert('forms', f.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    notifyListeners();
  }

  Future<void> deleteForm(String id) async {
    await _db.update(
      'forms',
      {'deleted': 1, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners();
  }
}
