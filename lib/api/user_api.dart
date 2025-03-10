import 'package:ai_video/api/api_client.dart';
import 'package:flutter/foundation.dart';

class UserApi {
  static const String baseUrl = 'https://chat.bigchallenger.com';
  final ApiClient _apiClient;

  UserApi({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(baseUrl: baseUrl);

  /// 查询用户余额
  Future<int> getCoins({
    required String uuid,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/customer/my_coins',
        queryParameters: {'uuid': uuid},
      );

      if (response['response']['success'] == '1') {
        // 尝试从响应中获取余额
        final coins = int.tryParse(
              response['coin']?.toString() ?? '0',
            ) ??
            0;
        return coins;
      } else {
        debugPrint(
          'Failed to get coins: ${response['response']['description']}',
        );
        return 0;
      }
    } catch (e) {
      debugPrint('Error getting balance: $e');
      return 0;
    }
  }

  // 判断用户是否订阅
  Future<bool> isSubscribe({
    required String uuid,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/customer/my_coins',
        queryParameters: {'uuid': uuid},
      );

      if (response['response']['success'] == '1') {
        // 尝试从响应中获取余额
        // {response: {success: 1, description: success, errorcode: 0000}, coin: 8700, is_subscribe: false}
        final isSubscribe = response['is_subscribe'] == true;
        return isSubscribe;
      } else {
        debugPrint(
          'Failed to get isSubscribe: ${response['response']['description']}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error getting isSubscribe: $e');
      return false;
    }
  }
}
