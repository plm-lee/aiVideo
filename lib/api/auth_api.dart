import 'package:ai_video/api/api_client.dart';

class AuthApi {
  static const String baseUrl = 'https://chat.bigchallenger.com/api';
  final ApiClient _apiClient;

  AuthApi({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(baseUrl: baseUrl);

  // 发送验证码
  Future<Map<String, dynamic>> sendVerificationCode(String email) async {
    return await _apiClient.post('/customer/rigister_code', {
      'email': email,
    });
  }

  // 注册
  Future<Map<String, dynamic>> register({
    required String email,
    required String verificationCode,
    required String password,
  }) async {
    return await _apiClient.post('/auth/register', {
      'email': email,
      'verificationCode': verificationCode,
      'password': password,
    });
  }

  // 登录
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return await _apiClient.post('/auth/login', {
      'email': email,
      'password': password,
    });
  }
}
