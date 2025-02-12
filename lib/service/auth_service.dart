import 'package:flutter/foundation.dart';
import 'package:ai_video/models/user.dart';
import 'package:ai_video/service/database_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  final DatabaseService _databaseService = DatabaseService();

  User? get currentUser => _currentUser;

  Future<void> checkAuth() async {
    _currentUser = await _databaseService.getLastLoggedInUser();
    if (_currentUser != null) {
      debugPrint('加载用户: ${_currentUser!.email}');
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      // TODO: 实现实际的登录API调用
      // 模拟登录成功
      final user = User(
        email: email,
        token: 'dummy_token_${DateTime.now().millisecondsSinceEpoch}',
        loginTime: DateTime.now(),
      );

      await _databaseService.saveUser(user);
      _currentUser = user;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    if (_currentUser?.id != null) {
      await _databaseService.clearUserData(_currentUser!.id!);
      await _databaseService.clearUserConfigs();
    }
    _currentUser = null;
    notifyListeners();
  }
}
