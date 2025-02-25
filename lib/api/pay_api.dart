import 'package:ai_video/api/api_client.dart';

class PayApi {
  static const String baseUrl = 'https://chat.bigchallenger.com';
  final ApiClient _apiClient;

  PayApi({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(baseUrl: baseUrl);

  Future<Map<String, dynamic>> fetchPurchasePackages({
    required String uuid,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/customer/coin_packages',
        queryParameters: {'uuid': uuid},
      );
      if (response['response']['success'] == '1') {
        return response;
      } else {
        throw Exception(
          'Failed to fetch purchase packages: ${response['response']['description']}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching purchase packages: $e');
    }
  }
}
