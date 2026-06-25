import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:my_todo_list_app/api/rest_api_service.dart';
import 'package:my_todo_list_app/model/category.dart';
import 'package:my_todo_list_app/model/diary.dart';
import 'package:my_todo_list_app/model/memo.dart';
import 'package:my_todo_list_app/model/server/diary.dart' as server;
import 'package:my_todo_list_app/model/server/schedule.dart';
import 'package:my_todo_list_app/model/todo_category_config.dart';
import 'package:my_todo_list_app/storage/session_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseHandler {
  static final DatabaseHandler _instance = DatabaseHandler._internal();
  factory DatabaseHandler() => _instance;
  DatabaseHandler._internal();

  static Database? _db;
  final RestApiService _api = RestApiService();

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
      version: 3,
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
        time TEXT NOT NULL DEFAULT '00:00',
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
    if (oldVersion < 3) {
      await db.execute(
        "ALTER TABLE memo ADD COLUMN time TEXT NOT NULL DEFAULT '00:00'",
      );
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
    final localId = await db.transaction((txn) async {
      final diaryId = await txn.insert('diary', {
        'diaryDate': diary.diaryDate,
        'content': diary.content,
        'image': diary.image,
      });

      await _replaceDiaryImagesTxn(txn, diaryId, images ?? <Uint8List>[]);
      return diaryId;
    });

    await _createOrUpdateServerDiary(diary);
    return localId;
  }

  Future<List<Diary>> getDiaryList() async {
    final db = await database;
    final result = await db.query('diary', orderBy: 'diaryDate DESC');
    final local = result.map((e) => Diary.fromMap(e)).toList();
    final byDate = {for (final diary in local) diary.diaryDate: diary};

    final userId = await SessionStorage.userId();
    if (userId == null) return local;

    try {
      final remote = await _api.getDiaries(userId: userId);
      for (final diary in remote) {
        final date = _dateOnly(diary.diaryDate);
        byDate.putIfAbsent(
          date,
          () => Diary(
            diaryId: diary.diaryId,
            diaryDate: date,
            content: diary.diaryContent ?? '',
            image: Uint8List(0),
          ),
        );
      }
      final merged = byDate.values.toList()
        ..sort((a, b) => b.diaryDate.compareTo(a.diaryDate));
      return merged;
    } catch (_) {
      return local;
    }
  }

  Future<int> deleteDiary(int id) async {
    final db = await database;
    final rows = await db.query(
      'diary',
      columns: ['diaryDate'],
      where: 'diaryId = ?',
      whereArgs: [id],
      limit: 1,
    );
    final deleted = await db.transaction((txn) async {
      await txn.delete('diary_image', where: 'diaryId = ?', whereArgs: [id]);
      return txn.delete('diary', where: 'diaryId = ?', whereArgs: [id]);
    });
    if (rows.isNotEmpty) {
      final userId = await SessionStorage.userId();
      if (userId != null) {
        try {
          final remote = await _api.getDiaryByDate(
            userId: userId,
            date: rows.first['diaryDate'] as String,
          );
          if (remote?.diaryId != null) {
            await _api.deleteDiary(remote!.diaryId!);
          }
        } catch (_) {}
      }
    }
    return deleted;
  }

  Future<Diary?> getDiaryByDate(String date) async {
    final db = await database;
    final result = await db.query(
      'diary',
      where: 'diaryDate = ?',
      whereArgs: [date],
    );

    if (result.isNotEmpty) return Diary.fromMap(result.first);

    final userId = await SessionStorage.userId();
    if (userId == null) return null;
    try {
      final remote = await _api.getDiaryByDate(userId: userId, date: date);
      if (remote == null) return null;
      return Diary(
        diaryId: remote.diaryId,
        diaryDate: _dateOnly(remote.diaryDate),
        content: remote.diaryContent ?? '',
        image: Uint8List(0),
      );
    } catch (_) {
      return null;
    }
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

  Future<void> updateDiary(
    int id,
    String content,
    List<Uint8List> images, {
    String? diaryDate,
  }) async {
    final db = await database;
    final coverImage = images.isEmpty ? Uint8List(0) : images.first;
    var savedLocalId = id;

    await db.transaction((txn) async {
      final updated = await txn.update(
        'diary',
        {'content': content, 'image': coverImage},
        where: 'diaryId = ?',
        whereArgs: [id],
      );
      var localId = id;
      if (updated == 0) {
        if (diaryDate == null || diaryDate.isEmpty) return;
        localId = await txn.insert('diary', {
          'diaryDate': diaryDate,
          'content': content,
          'image': coverImage,
        });
      }
      savedLocalId = localId;
      await _replaceDiaryImagesTxn(txn, localId, images);
    });

    final rows = await db.query(
      'diary',
      where: 'diaryId = ?',
      whereArgs: [savedLocalId],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      await _createOrUpdateServerDiary(Diary.fromMap(rows.first));
    }
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

  Future<int> insertMemo(
    String content,
    String date,
    int categoryId, {
    String time = '00:00',
  }) async {
    final userId = await SessionStorage.userId();
    if (userId != null) {
      try {
        final item = await _api.createSchedule(
          Schedule(
            userId: userId,
            scheduleTypeId: categoryId,
            scheduleTitle: content,
            scheduleContent: content,
            scheduleStartDate: '${date}T$time:00',
            scheduleEndDate: '${date}T$time:00',
          ),
        );
        return item.scheduleId!;
      } catch (_) {}
    }

    final db = await database;
    return db.insert('memo', {
      'date': date,
      'time': time,
      'content': content,
      'categoryId': categoryId,
      'isDone': 0,
    });
  }

  Future<int> updateMemo(int id, String content, int categoryId) async {
    final userId = await SessionStorage.userId();
    if (userId != null) {
      try {
        await _api.updateScheduleFields(id, {
          'scheduleTitle': content,
          'scheduleContent': content,
          'scheduleTypeId': categoryId,
        });
        return 1;
      } catch (_) {}
    }

    final db = await database;
    return db.update(
      'memo',
      {'content': content, 'categoryId': categoryId},
      where: 'memoId = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateMemoDone(int memoId, bool isDone) async {
    final userId = await SessionStorage.userId();
    if (userId != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('schedule_done_$memoId', isDone);
      return 1;
    }

    final db = await database;
    return db.update(
      'memo',
      {'isDone': isDone ? 1 : 0},
      where: 'memoId = ?',
      whereArgs: [memoId],
    );
  }

  Future<List<Memo>> getMemosByDate(String date) async {
    final userId = await SessionStorage.userId();
    if (userId != null) {
      try {
        final items = await _api.getSchedulesByDate(userId: userId, date: date);
        return _schedulesToMemos(items);
      } catch (_) {}
    }

    final db = await database;
    final result = await db.query(
      'memo',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'memoId DESC',
    );
    return result.map((e) => Memo.fromMap(e)).toList();
  }

  Future<List<Memo>> getAllMemos() async {
    final userId = await SessionStorage.userId();
    if (userId != null) {
      try {
        final items = await _api.getSchedules(userId: userId);
        return _schedulesToMemos(items);
      } catch (_) {}
    }

    final db = await database;
    final result = await db.query('memo', orderBy: 'date ASC, memoId DESC');
    return result.map((e) => Memo.fromMap(e)).toList();
  }

  Future<int> deleteMemo(int id) async {
    final userId = await SessionStorage.userId();
    if (userId != null) {
      try {
        await _api.deleteSchedule(id);
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('schedule_done_$id');
        return 1;
      } catch (_) {}
    }

    final db = await database;
    return db.delete('memo', where: 'memoId = ?', whereArgs: [id]);
  }

  Future<List<Memo>> _schedulesToMemos(List<Schedule> schedules) async {
    final prefs = await SharedPreferences.getInstance();
    return schedules
        .map(
          (item) => Memo(
            scheduleId: item.scheduleId,
            userId: item.userId,
            scheduleTypeId: item.scheduleTypeId,
            scheduleTitle: item.scheduleTitle,
            scheduleContent: item.scheduleContent,
            scheduleStartDate: item.scheduleStartDate,
            scheduleEndDate: item.scheduleEndDate,
            scheduleCreatedAt: item.scheduleCreatedAt,
            scheduleUpdatedAt: item.scheduleUpdatedAt,
            isDone: item.scheduleId == null
                ? false
                : prefs.getBool('schedule_done_${item.scheduleId}') ?? false,
          ),
        )
        .toList();
  }

  Future<void> _createOrUpdateServerDiary(Diary diary) async {
    final userId = await SessionStorage.userId();
    if (userId == null) return;
    final payload = server.ServerDiary(
      userId: userId,
      diaryDate: '${diary.diaryDate}T00:00:00',
      diaryTitle: '',
      diaryContent: diary.content,
    );
    try {
      final existing = await _api.getDiaryByDate(
        userId: userId,
        date: diary.diaryDate,
      );
      if (existing?.diaryId == null) {
        await _api.createDiary(payload);
      } else {
        await _api.updateDiary(existing!.diaryId!, payload);
      }
    } catch (_) {}
  }

  String _dateOnly(String value) {
    return value.length >= 10 ? value.substring(0, 10) : value;
  }
}
