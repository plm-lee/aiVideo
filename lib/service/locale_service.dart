import 'package:flutter/material.dart';
import 'package:ai_video/service/database_service.dart';
import 'package:ai_video/models/user_config.dart';
import 'package:ai_video/l10n/app_en.dart';
import 'package:ai_video/l10n/app_zh.dart';

class LocaleService extends ChangeNotifier {
  static final LocaleService _instance = LocaleService._internal();
  factory LocaleService() => _instance;
  LocaleService._internal();

  Locale _locale = const Locale('zh', 'CN');
  final DatabaseService _databaseService = DatabaseService();

  Locale get locale => _locale;

  Future<void> setLocale(Locale newLocale) async {
    if (_locale != newLocale) {
      _locale = newLocale;
      await _databaseService.saveConfig(
        UserConfig(
          key: 'app_locale',
          value: '${newLocale.languageCode}_${newLocale.countryCode}',
        ),
      );
      notifyListeners();
    }
  }

  Future<void> loadLocale() async {
    final config = await _databaseService.getConfig('app_locale');
    if (config != null) {
      final parts = config.value.split('_');
      _locale = Locale(parts[0], parts[1]);
    }
    notifyListeners();
  }

  String translate(String key) {
    final translations = _locale.languageCode == 'zh' ? zhCN : enUS;
    return translations[key] ?? key;
  }
}
