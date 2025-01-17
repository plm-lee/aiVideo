import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:bigchanllger/models/user_config.dart';
import 'package:bigchanllger/models/generated_video.dart';
import 'package:bigchanllger/models/user.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'bigchallenger.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user_configs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT NOT NULL,
        value TEXT NOT NULL
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
        originalImagePath TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL,
        token TEXT NOT NULL,
        loginTime TEXT NOT NULL
      )
    ''');
  }

  // User Config Methods
  Future<void> saveConfig(UserConfig config) async {
    final db = await database;
    await db.insert(
      'user_configs',
      config.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserConfig?> getConfig(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_configs',
      where: 'key = ?',
      whereArgs: [key],
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
        where: 'userId = ?',
        whereArgs: [userId],
      );

      // 删除用户的金币记录
      await txn.delete(
        'user_configs',
        where: 'key = ?',
        whereArgs: ['user_credits_$userId'],
      );
    });
  }

  // 清理所有用户配置
  Future<void> clearUserConfigs() async {
    final db = await database;
    await db.delete('user_configs');
  }
}
