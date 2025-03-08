import 'package:flutter/foundation.dart';
import 'package:ai_video/models/user.dart';
import 'package:ai_video/service/database_service.dart';
import 'package:ai_video/api/auth_api.dart';
import 'package:ai_video/service/credits_service.dart';

// 添加一个注册结果类
class RegisterResult {
  final bool success;
  final String? message;

  const RegisterResult(this.success, this.message);
}

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  final DatabaseService _databaseService = DatabaseService();
  final AuthApi _authApi = AuthApi();
  final CreditsService _creditsService = CreditsService();

  User? get currentUser => _currentUser;

  Future<void> checkAuth() async {
    try {
      _currentUser = await _databaseService.getLastLoggedInUser();
      if (_currentUser != null) {
        debugPrint('加载用户: ${_currentUser!.email}');
        // 设置用户 UUID 到 CreditsService
        _creditsService.setUuid(_currentUser!.uuid);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('检查认证状态错误: $e');
    }
  }

  Future<void> logout() async {
    try {
      if (_currentUser?.id != null) {
        await _databaseService.clearUserData(_currentUser!.id!);
        await _databaseService.clearUserConfigs();
        // 删除保存db的视频
        await _databaseService.deleteAllSavedVideos();
      }
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint('登出错误: $e');
    }
  }

  Future<bool> sendVerificationCode(String email) async {
    try {
      final response = await _authApi.sendVerificationCode(email);
      final responseData = response['response'];

      if (responseData['success'] == '1') {
        debugPrint('验证码发送成功: ${responseData['description']}');
        return true;
      } else {
        debugPrint('验证码发送失败: ${responseData['description']}');
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
      final responseData = response['response'];

      if (responseData['success'] == '1') {
        return const RegisterResult(true, null);
      } else {
        return RegisterResult(false, responseData['description']);
      }
    } catch (e) {
      debugPrint('注册错误: $e');
      return const RegisterResult(false, '注册失败，请稍后重试');
    }
  }

  Future<(bool success, String? message)> login(
      String email, String password) async {
    try {
      final response = await _authApi.login(
        email: email,
        password: password,
      );
      final responseData = response['response'];
      final uuid = response['uuid'];

      if (responseData['success'] == '1') {
        final user = User(
          email: email,
          token: responseData['token'] ?? '',
          uuid: uuid ?? '',
          loginTime: DateTime.now(),
        );

        await _databaseService.saveUser(user);
        _currentUser = user;

        // 设置用户 UUID 到 CreditsService
        _creditsService.setUuid(user.uuid);

        notifyListeners();
        debugPrint('登录用户uuid: ${user.uuid}');
        return (true, null);
      } else {
        debugPrint('登录失败: ${responseData['description']}');
        return (false, responseData['description']?.toString());
      }
    } catch (e) {
      debugPrint('登录错误: $e');
      return (false, '登录失败，请稍后重试');
    }
  }

  // 获取当前用户信息
  Future<(bool success, String? message, User? user)> getCurrentUser() async {
    try {
      _currentUser ??= await _databaseService.getLastLoggedInUser();

      if (_currentUser == null) {
        return (false, '用户未登录', null);
      }

      debugPrint('当前用户: ${_currentUser!.email}');
      return (true, null, _currentUser);
    } catch (e) {
      debugPrint('获取用户信息错误: $e');
      return (false, '获取用户信息失败，请重新登录', null);
    }
  }
}
