import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:ai_video/models/user_config.dart';
import 'package:ai_video/models/generated_video.dart';
import 'package:ai_video/models/user.dart';
import 'package:ai_video/models/purchase_record.dart';
import 'package:ai_video/models/video_task.dart';

class DatabaseService {
  static final int _dbVersion = 7;
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    _printAllUserData();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'ai_video.db');
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // 初始化数据库的时候，把所有用户数据打印出来
  Future<void> _printAllUserData() async {
    final db = await database;

    // 打印用户表数据
    final List<Map<String, dynamic>> users = await db.query('users');
    print('用户表数据:');
    for (var user in users) {
      print(user);
    }

    // 打印用户配置表数据
    final List<Map<String, dynamic>> configs = await db.query('user_configs');
    print('用户配置表数据:');
    for (var config in configs) {
      print(config);
    }

    // 打印生成视频表数据
    final List<Map<String, dynamic>> videos =
        await db.query('generated_videos');
    print('生成视频表数据:');
    for (var video in videos) {
      print(video);
    }

    // 打印购买记录表数据
    final List<Map<String, dynamic>> purchases =
        await db.query('purchase_records');
    print('购买记录表数据:');
    for (var purchase in purchases) {
      print(purchase);
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL,
        token TEXT NOT NULL,
        uuid TEXT,
        loginTime TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE user_configs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT NOT NULL,
        value TEXT NOT NULL,
        userId INTEGER,
        FOREIGN KEY (userId) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE generated_videos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        filePath TEXT NOT NULL,
        style TEXT NOT NULL,
        prompt TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        type TEXT NOT NULL,
        originalImagePath TEXT,
        userId INTEGER,
        FOREIGN KEY (userId) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE purchase_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        expireAt TEXT,
        userId INTEGER,
        FOREIGN KEY (userId) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE video_tasks (
        business_id TEXT PRIMARY KEY,
        created_at TEXT NOT NULL,
        state INTEGER NOT NULL,
        prompt TEXT NOT NULL,
        origin_img TEXT,
        video_url TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db
          .execute('ALTER TABLE generated_videos ADD COLUMN userId INTEGER');
      await db.execute('ALTER TABLE user_configs ADD COLUMN userId INTEGER');
    }

    if (oldVersion < 3) {
      await db.execute(
          'ALTER TABLE generated_videos RENAME TO generated_videos_backup');
      await db
          .execute('ALTER TABLE user_configs RENAME TO user_configs_backup');

      await db.execute('''
        CREATE TABLE generated_videos(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          filePath TEXT NOT NULL,
          style TEXT NOT NULL,
          prompt TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          type TEXT NOT NULL,
          originalImagePath TEXT,
          userId INTEGER,
          FOREIGN KEY (userId) REFERENCES users(id)
        )
      ''');

      await db.execute('''
        CREATE TABLE user_configs(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          key TEXT NOT NULL,
          value TEXT NOT NULL,
          userId INTEGER,
          FOREIGN KEY (userId) REFERENCES users(id)
        )
      ''');

      await db.execute('''
        INSERT INTO generated_videos 
        SELECT * FROM generated_videos_backup
      ''');

      await db.execute('''
        INSERT INTO user_configs 
        SELECT * FROM user_configs_backup
      ''');

      await db.execute('DROP TABLE generated_videos_backup');
      await db.execute('DROP TABLE user_configs_backup');
    }

    if (oldVersion < 5) {
      await db.execute('ALTER TABLE users ADD COLUMN uuid TEXT');
    }

    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE video_tasks(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          business_id TEXT NOT NULL,
          created_at TEXT NOT NULL,
          state INTEGER NOT NULL,
          prompt TEXT NOT NULL,
          origin_img TEXT,
          userId INTEGER,
          FOREIGN KEY (userId) REFERENCES users(id)
        )
      ''');
    }

    if (oldVersion < 7) {
      await db.execute('ALTER TABLE video_tasks ADD COLUMN video_url TEXT');
    }
  }

  // User Config Methods
  Future<void> saveConfig(UserConfig config) async {
    final db = await database;
    final existingConfig = await getConfig(config.key, userId: config.userId);

    if (existingConfig != null) {
      final Map<String, dynamic> updateData = {
        'key': config.key,
        'value': config.value,
        'userId': config.userId,
      };

      await db.update(
        'user_configs',
        updateData,
        where:
            'key = ? AND userId ${config.userId == null ? 'IS NULL' : '= ?'}',
        whereArgs:
            config.userId == null ? [config.key] : [config.key, config.userId],
      );
    } else {
      await db.insert(
        'user_configs',
        config.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<UserConfig?> getConfig(String key, {int? userId}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_configs',
      where: userId == null ? 'key = ?' : 'key = ? AND userId = ?',
      whereArgs: userId == null ? [key] : [key, userId],
    );

    if (maps.isEmpty) return null;
    return UserConfig.fromMap(maps.first);
  }

  // Generated Video Methods
  Future<int> saveGeneratedVideo(GeneratedVideo video) async {
    final db = await database;
    return await db.insert('generated_videos', video.toMap());
  }

  Future<List<GeneratedVideo>> getAllVideos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('generated_videos');
    return List.generate(maps.length, (i) => GeneratedVideo.fromMap(maps[i]));
  }

  Future<void> deleteVideo(int id) async {
    final db = await database;
    await db.delete(
      'generated_videos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // User Methods
  Future<void> saveUser(User user) async {
    final db = await database;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<User?> getLastLoggedInUser() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      orderBy: 'loginTime DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<void> deleteUser(int id) async {
    final db = await database;
    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<GeneratedVideo>> getAllGeneratedVideos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('generated_videos');
    return List.generate(maps.length, (i) => GeneratedVideo.fromMap(maps[i]));
  }

  // 清理指定用户的所有数据
  Future<void> clearUserData(int userId) async {
    final db = await database;
    await db.transaction((txn) async {
      // 删除用户记录
      await txn.delete(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      // 删除用户的视频记录
      await txn.delete(
        'generated_videos',
        where: 'userId IS NULL OR userId = ?',
        whereArgs: [userId],
      );

      // 删除用户的配置
      await txn.delete(
        'user_configs',
        where: 'userId IS NULL OR userId = ?',
        whereArgs: [userId],
      );
    });
  }

  // 清理所有用户配置
  Future<void> clearUserConfigs() async {
    final db = await database;
    await db.delete('user_configs');
  }

  Future<void> deleteDatabase() async {
    final path = join(await getDatabasesPath(), 'ai_video.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  Future<List<PurchaseRecord>> getPurchaseRecords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'purchase_records',
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => PurchaseRecord.fromMap(maps[i]));
  }

  Future<void> savePurchaseRecord(PurchaseRecord record) async {
    final db = await database;
    await db.insert(
      'purchase_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveVideoTasks(List<VideoTask> tasks) async {
    final db = await database;
    await db.transaction((txn) async {
      for (var task in tasks) {
        // 检查是否已存在相同的 business_id
        final existing = await txn.query(
          'video_tasks',
          where: 'business_id = ?',
          whereArgs: [task.businessId],
        );

        if (existing.isEmpty) {
          await txn.insert(
            'video_tasks',
            {
              'business_id': task.businessId,
              'created_at': task.createdAt.toIso8601String(),
              'state': task.state,
              'prompt': task.prompt,
              'origin_img': task.originImg,
              'video_url': task.videoUrl,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } else {
          // 如果存在，更新状态、图片和视频地址
          await txn.update(
            'video_tasks',
            {
              'state': task.state,
              'video_url': task.videoUrl,
              'origin_img': task.originImg,
            },
            where: 'business_id = ?',
            whereArgs: [task.businessId],
          );
        }
      }
    });
  }

  Future<List<VideoTask>> getVideoTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'video_tasks',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => VideoTask.fromMap(maps[i]));
  }
}
