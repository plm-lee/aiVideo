import 'package:flutter/material.dart';
import 'package:bigchanllger/service/database_service.dart';
import 'package:bigchanllger/models/user_config.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // 默认跟随系统
  final DatabaseService _databaseService = DatabaseService();

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final config = await _databaseService.getConfig('theme_mode');
    if (config != null) {
      _themeMode = _parseThemeMode(config.value);

      // 日志
      debugPrint('初始化主题: ${_themeMode}');
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      await _databaseService.saveConfig(
        UserConfig(
          key: 'theme_mode',
          value: _themeModeToString(mode),
        ),
      );
      debugPrint('设置主题: ${_themeMode}');
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
