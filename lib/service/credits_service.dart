import 'package:flutter/foundation.dart';
import 'package:ai_video/service/database_service.dart';
import 'package:ai_video/models/user_config.dart';
import 'package:ai_video/models/purchase_record.dart';

class CreditsService extends ChangeNotifier {
  static final CreditsService _instance = CreditsService._internal();
  factory CreditsService() => _instance;

  @visibleForTesting
  factory CreditsService.test() => CreditsService._internal();

  CreditsService._internal();

  int _credits = 0;
  DatabaseService _databaseService = DatabaseService();

  @visibleForTesting
  set credits(int value) {
    _credits = value;
  }

  set databaseService(DatabaseService service) {
    _databaseService = service;
  }

  int get credits => _credits;

  Future<void> loadCredits() async {
    final config = await _databaseService.getConfig('user_credits');
    if (config != null) {
      _credits = int.parse(config.value);
    } else {
      _credits = 0;
    }

    debugPrint('加载金币: ${_credits}');

    // 金币为0，给用户增加100金币
    if (_credits == 0) {
      await addCredits(100);

      // 写一条购买记录，为注册赠送100金币
      await _databaseService.savePurchaseRecord(PurchaseRecord(
        id: 1,
        title: '注册赠送50金币',
        amount: 500,
        createdAt: DateTime.now().toIso8601String(),
        userId: 1,
      ));

      await _databaseService.savePurchaseRecord(PurchaseRecord(
        id: 2,
        title: '新用户登录赠送50金币',
        amount: 50,
        createdAt: DateTime.now().toIso8601String(),
        userId: 1,
      ));
    }

    notifyListeners();
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
