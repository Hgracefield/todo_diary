import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'package:my_todo_list_app/model/category.dart';
import 'package:my_todo_list_app/model/diary.dart';
import 'package:my_todo_list_app/model/memo.dart';

class DatabaseHandler {
  static final DatabaseHandler _instance = DatabaseHandler._internal();
  factory DatabaseHandler() => _instance;
  DatabaseHandler._internal();

  static Database? _db;

  // ---------------- DATABASE INIT ----------------
  Future<void> forceResetDB() async {
    if (_db != null) {
      await _db!.close(); // ✅ 열려 있던 DB 닫기
      _db = null; // ✅ 캐시 제거
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'my_todo_app2.db');

    await deleteDatabase(path);
    print('🔥 DB FILE DELETED AND RESET');
  }

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'my_todo_app2.db');

    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // CATEGORY
    await db.execute('''
      CREATE TABLE category (
        categoryId INTEGER PRIMARY KEY AUTOINCREMENT,
        categoryName TEXT NOT NULL,
        categoryColor TEXT NOT NULL
      )
    ''');

    // DIARY
    await db.execute('''
      CREATE TABLE diary (
        diaryId INTEGER PRIMARY KEY AUTOINCREMENT,
        diaryDate TEXT NOT NULL,
        textContent TEXT NOT NULL,
        image BLOB NOT NULL
      )
    ''');

    // MEMO (Calendar / Todo용)
    await db.execute('''
      CREATE TABLE memo (
       memoId INTEGER PRIMARY KEY AUTOINCREMENT,
       date TEXT,
       content TEXT,
       categoryId INTEGER,
       isDone INTEGER DEFAULT 0,
       FOREIGN KEY (categoryId) REFERENCES category(categoryId)
      )
    ''');
  }

  // ================= CATEGORY =================

  Future<int> insertCategory(Category category) async {
    final db = await database;
    return db.insert('category', {
      'categoryName': category.categoryName,
      'categoryColor': category.categoryColor,
    });
  }

  Future<List<Category>> getCategoryList() async {
    final db = await database;
    final result = await db.query('category');
    return result.map((e) => Category.fromMap(e)).toList();
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return db.delete('category', where: 'categoryId = ?', whereArgs: [id]);
  }

  // ================= DIARY =================

  Future<int> insertDiary(Diary diary) async {
    final db = await database;
    return db.insert('diary', {
      'diaryDate': diary.diaryDate,
      'textContent': diary.textContent,
      'image': diary.image,
    });
  }

  Future<List<Diary>> getDiaryList() async {
    final db = await database;
    final result = await db.query('diary', orderBy: 'diaryDate DESC');
    return result.map((e) => Diary.fromMap(e)).toList();
  }

  Future<int> deleteDiary(int id) async {
    final db = await database;
    return db.delete('diary', where: 'diaryId = ?', whereArgs: [id]);
  }

  Future<int> updateDiaryText(int id, String text) async {
    final db = await database;
    return db.update(
      'diary',
      {'textContent': text},
      where: 'diaryId = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateDiaryImage(int id, Uint8List image) async {
    final db = await database;
    return db.update(
      'diary',
      {'image': image},
      where: 'diaryId = ?',
      whereArgs: [id],
    );
  }

  // ================= MEMO (Calendar / Todo) =================

  Future<int> insertMemo(String content, String date, int categoryId) async {
    final db = await database;
    return db.insert('memo', {
      'content': content,
      'date': date,
      'categoryId': categoryId,
      'isDone': 0,
    });
  }

  Future<int> updateMemo(int id, String content, int categoryId) async {
    final db = await database;
    return db.update(
      'memo',
      {'content': content, 'categoryId': categoryId},
      where: 'memoId = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateMemoDone(int memoId, bool isDone) async {
    final db = await database;
    return db.update(
      'memo',
      {'isDone': isDone ? 1 : 0},
      where: 'memoId = ?',
      whereArgs: [memoId],
    );
  }

  Future<List<Memo>> getMemosByDate(String date) async {
    final db = await database;
    final result = await db.query('memo', where: 'date = ?', whereArgs: [date]);
    return result.map((e) => Memo.fromMap(e)).toList();
  }

  Future<List<Memo>> getAllMemos() async {
    final db = await database;
    final result = await db.query('memo', orderBy: 'date DESC');
    return result.map((e) => Memo.fromMap(e)).toList();
  }

  Future<int> deleteMemo(int id) async {
    final db = await database;
    return db.delete('memo', where: 'memoId = ?', whereArgs: [id]);
  }
}
