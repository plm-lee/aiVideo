import 'package:flutter/foundation.dart';
import 'package:ai_video/api/user_api.dart';
import 'package:flutter/material.dart';

class UserService extends ChangeNotifier {
  final UserApi _userApi;
  int _coins = 0;
  String? _uuid;
  bool _isLoading = false;

  UserService({UserApi? userApi}) : _userApi = userApi ?? UserApi();

  /// 获取当前金币数量
  int get coins => _coins;

  /// 是否正在加载
  bool get isLoading => _isLoading;

  /// 设置用户 UUID
  void setUuid(String uuid) {
    _uuid = uuid;
    // 设置 UUID 后自动刷新金币数量
    refreshCoins();
  }

  /// 刷新金币数量
  Future<void> refreshCoins() async {
    if (_uuid == null) {
      debugPrint('Cannot refresh coins: UUID is not set');
      return;
    }

    if (_isLoading) return;

    try {
      _isLoading = true;
      notifyListeners();

      final coins = await _userApi.getCoins(uuid: _uuid!);

      if (_coins != coins) {
        _coins = coins;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing coins: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 更新金币数量（本地更新，不调用API）
  void updateCoins(int newCoins) {
    if (_coins != newCoins) {
      _coins = newCoins;
      notifyListeners();
    }
  }

  /// 增加金币数量（本地更新，不调用API）
  void addCoins(int amount) {
    if (amount != 0) {
      _coins += amount;
      notifyListeners();
    }
  }

  /// 扣减金币数量（本地更新，不调用API）
  bool deductCoins(int amount) {
    if (amount <= 0) return false;
    if (_coins < amount) return false;

    _coins -= amount;
    notifyListeners();
    return true;
  }
}
