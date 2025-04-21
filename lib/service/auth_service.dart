import 'package:flutter/foundation.dart';
import 'package:ai_video/models/user.dart';
import 'package:ai_video/service/database_service.dart';
import 'package:ai_video/api/auth_api.dart';
import 'package:ai_video/service/user_service.dart';

// Add a registration result class
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
  final UserService _userService = UserService();

  User? get currentUser => _currentUser;

  Future<void> checkAuth() async {
    try {
      _currentUser = await _databaseService.getLastLoggedInUser();
      if (_currentUser != null) {
        debugPrint('Loading user: ${_currentUser!.email}');
        // Set user UUID to CreditsService
        _userService.setUuid(_currentUser!.uuid);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error checking authentication status: $e');
    }
  }

  Future<void> logout() async {
    try {
      if (_currentUser?.id != null) {
        await _databaseService.clearDatabase();
      }
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  Future<void> deleteAccount() async {
    try {
      if (_currentUser?.id != null) {
        await _authApi.deleteAccount(_currentUser!.uuid);
        // Clear local database
        await _databaseService.clearDatabase();
      }
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Account deletion error: $e');
      rethrow; // Rethrow the exception for the caller to handle
    }
  }

  Future<bool> sendVerificationCode(String email) async {
    try {
      final response = await _authApi.sendVerificationCode(email);
      final responseData = response['response'];

      if (responseData['success'] == '1') {
        debugPrint(
            'Verification code sent successfully: ${responseData['description']}');
        return true;
      } else {
        debugPrint(
            'Failed to send verification code: ${responseData['description']}');
        return false;
      }
    } catch (e) {
      debugPrint('Error sending verification code: $e');
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
      debugPrint('Registration error: $e');
      return const RegisterResult(
          false, 'Registration failed, please try again later');
    }
  }

  Future<(bool success, String? message)> login(
      String email, String password) async {
    try {
      final response = await _authApi.login(
        email: email,
        password: password,
      );

      debugPrint('Login request: $email, $password, response: $response');
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

        // Set user UUID to CreditsService
        _userService.setUuid(user.uuid);

        notifyListeners();
        debugPrint('Logged in user UUID: ${user.uuid}');
        return (true, null);
      } else {
        debugPrint('Login failed: ${responseData['description']}');
        return (false, responseData['description']?.toString());
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return (false, 'Login failed, please try again later');
    }
  }

  // Get current user information
  Future<(bool success, String? message, User? user)> getCurrentUser() async {
    try {
      _currentUser ??= await _databaseService.getLastLoggedInUser();

      if (_currentUser == null) {
        return (false, 'User not logged in', null);
      }

      debugPrint('Current user: ${_currentUser!.email}');
      return (true, null, _currentUser);
    } catch (e) {
      debugPrint('Error getting user information: $e');
      return (
        false,
        'Failed to get user information, please log in again',
        null
      );
    }
  }
}
