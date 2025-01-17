import 'package:flutter/material.dart';
import 'package:bigchanllger/service/database_service.dart';
import 'package:bigchanllger/models/user_config.dart';
import 'package:bigchanllger/service/auth_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final user = _authService.currentUser;
    final config = await _databaseService.getConfig(
      'theme_mode',
      userId: user?.id,
    );

    if (config != null) {
      _themeMode = _parseThemeMode(config.value);
      debugPrint('加载用户主题: ${_themeMode}');
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      final user = _authService.currentUser;

      await _databaseService.saveConfig(
        UserConfig(
          key: 'theme_mode',
          value: _themeModeToString(mode),
          userId: user?.id,
        ),
      );

      debugPrint('保存用户主题: ${_themeMode}');
      notifyListeners();
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'system';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
    }
  }

  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
