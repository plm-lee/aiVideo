import 'package:flutter/foundation.dart';
import 'package:bigchanllger/service/database_service.dart';
import 'package:bigchanllger/models/user_config.dart';

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
      notifyListeners();
    }
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
}
