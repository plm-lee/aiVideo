import 'package:flutter/foundation.dart';
import 'package:ai_video/service/database_service.dart';
import 'package:ai_video/models/user_config.dart';
import 'package:ai_video/models/purchase_record.dart';
import 'package:ai_video/api/user_api.dart';

class UserService extends ChangeNotifier {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;

  @visibleForTesting
  factory UserService.test({
    DatabaseService? databaseService,
    UserApi? userApi,
  }) =>
      UserService._internal(
        databaseService: databaseService,
        userApi: userApi,
      );

  UserService._internal({
    DatabaseService? databaseService,
    UserApi? userApi,
  })  : _databaseService = databaseService ?? DatabaseService(),
        _userApi = userApi ?? UserApi();

  int _credits = 0;
  String? _uuid;
  // 是否订阅用户
  bool _isSubscribed = false;

  final DatabaseService _databaseService;
  final UserApi _userApi;

  @visibleForTesting
  set credits(int value) {
    _credits = value;
  }

  int get credits => _credits;

  void setUuid(String uuid) {
    _uuid = uuid;
    loadCredits(); // 设置 UUID 后自动加载金币数量
  }

  bool get isSubscribed => _isSubscribed;

  // 初始化用户
  Future<void> initUser() async {
    await loadIsSubscribe();
    await loadCredits();
  }

  void setIsSubscribe(bool value) {
    debugPrint('设置是否订阅用户: $value');
    if (_isSubscribed != value) {
      _isSubscribed = value;
      notifyListeners();
    }
  }

  Future<void> loadIsSubscribe() async {
    if (_uuid == null) {
      debugPrint('UUID 未设置，无法加载是否订阅');
      return;
    }

    try {
      final isSubscribe = await _userApi.isSubscribe(uuid: _uuid!);
      debugPrint('是否订阅用户: $isSubscribe');
      setIsSubscribe(isSubscribe);
      notifyListeners();
    } catch (e) {
      debugPrint('加载是否订阅失败: $e');
    }
  }

  Future<void> loadCredits() async {
    if (_uuid == null) {
      debugPrint('UUID 未设置，无法加载金币');
      return;
    }

    try {
      // 从 API 获取金币数量
      final coins = await _userApi.getCoins(uuid: _uuid!);
      _credits = coins;

      // 保存到本地数据库作为缓存
      await _databaseService.saveConfig(
        UserConfig(
          key: 'user_credits',
          value: _credits.toString(),
        ),
      );

      notifyListeners();
      debugPrint('加载金币成功: $_credits');
    } catch (e) {
      debugPrint('加载金币失败: $e');
      // 如果 API 请求失败，尝试从本地缓存加载
      final config = await _databaseService.getConfig('user_credits');
      if (config != null) {
        _credits = int.parse(config.value);
        notifyListeners();
      }
    }
  }

  Future<void> addCredits(int amount) async {
    _credits += amount;
    await _databaseService.saveConfig(
      UserConfig(
        key: 'user_credits',
        value: _credits.toString(),
      ),
    );
    notifyListeners();
  }

  Future<bool> useCredits(int amount) async {
    if (_credits < amount) return false;

    _credits -= amount;
    await _databaseService.saveConfig(
      UserConfig(
        key: 'user_credits',
        value: _credits.toString(),
      ),
    );
    notifyListeners();
    return true;
  }

  Future<void> addCreditsToUser(int userId, int amount) async {
    final config = await _databaseService.getConfig('user_credits_$userId');
    final currentCredits = config != null ? int.parse(config.value) : 0;
    final newCredits = currentCredits + amount;

    await _databaseService.saveConfig(
      UserConfig(
        key: 'user_credits_$userId',
        value: newCredits.toString(),
      ),
    );

    // 如果是当前用户，更新内存中的金币数量
    if (_currentUserId == userId) {
      _credits = newCredits;
      notifyListeners();
    }
  }

  // 添加一个字段来跟踪当前用户ID
  int? _currentUserId;

  // 设置当前用户ID的方法
  void setCurrentUserId(int? userId) {
    _currentUserId = userId;
  }
}
