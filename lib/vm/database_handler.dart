import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:my_todo_list_app/model/category.dart';
import 'package:my_todo_list_app/model/diary.dart';
import 'package:my_todo_list_app/model/memo.dart';
import 'package:my_todo_list_app/model/todo_category_config.dart';

class DatabaseHandler {
  static final DatabaseHandler _instance = DatabaseHandler._internal();
  factory DatabaseHandler() => _instance;
  DatabaseHandler._internal();

  static Database? _db;

  Future<void> forceResetDB() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'my_todo_app2.db');
    await deleteDatabase(path);
  }

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'my_todo_app2.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE category (
        categoryId INTEGER PRIMARY KEY AUTOINCREMENT,
        categoryName TEXT NOT NULL,
        categoryColor TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE diary (
        diaryId INTEGER PRIMARY KEY AUTOINCREMENT,
        diaryDate TEXT NOT NULL UNIQUE,
        content TEXT NOT NULL,
        image BLOB NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE diary_image (
        diaryImageId INTEGER PRIMARY KEY AUTOINCREMENT,
        diaryId INTEGER NOT NULL,
        image BLOB NOT NULL,
        sortOrder INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (diaryId) REFERENCES diary(diaryId)
      )
    ''');

    await db.execute('''
      CREATE TABLE memo (
        memoId INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        content TEXT,
        categoryId INTEGER,
        isDone INTEGER DEFAULT 0,
        FOREIGN KEY (categoryId) REFERENCES category(categoryId)
      )
    ''');

    for (final category in todoCategoryConfigs) {
      await db.insert('category', {
        'categoryId': category.id,
        'categoryName': category.name,
        'categoryColor': category.colorName,
      });
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS diary_image (
          diaryImageId INTEGER PRIMARY KEY AUTOINCREMENT,
          diaryId INTEGER NOT NULL,
          image BLOB NOT NULL,
          sortOrder INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (diaryId) REFERENCES diary(diaryId)
        )
      ''');

      final diaries = await db.query('diary');
      for (final diary in diaries) {
        final image = diary['image'];
        if (image is Uint8List && image.isNotEmpty) {
          await db.insert('diary_image', {
            'diaryId': diary['diaryId'],
            'image': image,
            'sortOrder': 0,
          });
        }
      }
    }
  }

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

  Future<int> insertDiary(Diary diary, {List<Uint8List>? images}) async {
    final db = await database;
    return db.transaction((txn) async {
      final diaryId = await txn.insert('diary', {
        'diaryDate': diary.diaryDate,
        'content': diary.content,
        'image': diary.image,
      });

      await _replaceDiaryImagesTxn(txn, diaryId, images ?? <Uint8List>[]);
      return diaryId;
    });
  }

  Future<List<Diary>> getDiaryList() async {
    final db = await database;
    final result = await db.query('diary', orderBy: 'diaryDate DESC');
    return result.map((e) => Diary.fromMap(e)).toList();
  }

  Future<int> deleteDiary(int id) async {
    final db = await database;
    return db.transaction((txn) async {
      await txn.delete('diary_image', where: 'diaryId = ?', whereArgs: [id]);
      return txn.delete('diary', where: 'diaryId = ?', whereArgs: [id]);
    });
  }

  Future<Diary?> getDiaryByDate(String date) async {
    final db = await database;
    final result = await db.query(
      'diary',
      where: 'diaryDate = ?',
      whereArgs: [date],
    );

    if (result.isEmpty) return null;
    return Diary.fromMap(result.first);
  }

  Future<int> updateDiaryText(int id, String text) async {
    final db = await database;
    return db.update(
      'diary',
      {'content': text},
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

  Future<void> updateDiary(int id, String content, List<Uint8List> images) async {
    final db = await database;
    final coverImage = images.isEmpty ? Uint8List(0) : images.first;

    await db.transaction((txn) async {
      await txn.update(
        'diary',
        {'content': content, 'image': coverImage},
        where: 'diaryId = ?',
        whereArgs: [id],
      );
      await _replaceDiaryImagesTxn(txn, id, images);
    });
  }

  Future<List<Uint8List>> getDiaryImages(int diaryId) async {
    final db = await database;
    final result = await db.query(
      'diary_image',
      where: 'diaryId = ?',
      whereArgs: [diaryId],
      orderBy: 'sortOrder ASC, diaryImageId ASC',
    );
    return result.map((row) => row['image'] as Uint8List).toList();
  }

  Future<void> _replaceDiaryImagesTxn(
    Transaction txn,
    int diaryId,
    List<Uint8List> images,
  ) async {
    await txn.delete('diary_image', where: 'diaryId = ?', whereArgs: [diaryId]);

    for (var i = 0; i < images.length; i++) {
      await txn.insert('diary_image', {
        'diaryId': diaryId,
        'image': images[i],
        'sortOrder': i,
      });
    }
  }

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
