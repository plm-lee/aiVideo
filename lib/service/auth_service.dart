import 'package:flutter/foundation.dart';
import 'package:ai_video/models/user.dart';
import 'package:ai_video/service/database_service.dart';
import 'package:ai_video/api/auth_api.dart';

// 添加一个注册结果类
class RegisterResult {
  final bool success;
  final String? message;

  RegisterResult(this.success, this.message);
}

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  final DatabaseService _databaseService = DatabaseService();
  final AuthApi _authApi = AuthApi();

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

  Future<bool> sendVerificationCode(String email) async {
    try {
      final response = await _authApi.sendVerificationCode(email);

      // {"response":{"success":"1","description":"success","errorcode":"0000"}}
      // 检查响应状态
      if (response['response']['success'] == '1') {
        debugPrint('验证码发送成功: ${response['response']['description']}');
        return true;
      } else {
        debugPrint('验证码发送失败: ${response['response']['description']}');
        return false;
      }
    } catch (e) {
      debugPrint('发送验证码错误: $e');
      return false;
    }
  }

  Future<RegisterResult> register({
    required String email,
    required String verificationCode,
    required String password,
  }) async {
    try {
      final response = await _authApi.register(
        email: email,
        verificationCode: verificationCode,
        password: password,
      );

      if (response['response']['success'] == '1') {
        // 注册成功后自动登录
        final user = User(
          email: email,
          token: response['response']['token'] ?? 'dummy_token',
          loginTime: DateTime.now(),
        );

        await _databaseService.saveUser(user);
        _currentUser = user;
        notifyListeners();

        return RegisterResult(true, null);
      } else {
        return RegisterResult(false, response['response']['description']);
      }
    } catch (e) {
      debugPrint('注册错误: $e');
      return RegisterResult(false, '注册失败，请稍后重试');
    }
  }
}
