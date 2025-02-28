import 'package:ai_video/api/api_client.dart';
import 'package:flutter/material.dart';

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

  Future<Map<String, dynamic>> prepayOrder({
    required String uuid,
    required String productUuid,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/ios_in_app_purchase/subscribe',
        {
          'uuid': uuid,
          'product_uuid': productUuid,
        },
      );

      debugPrint("uuid: $uuid, productUuid: $productUuid, response: $response");

      if (response['response']['success'] == '1') {
        return response;
      } else {
        throw Exception(
          'Failed to create prepay order: ${response['response']['description']}',
        );
      }
    } catch (e) {
      throw Exception('Error creating prepay order: $e');
    }
  }

  Future<bool> verifyPurchase({
    required String uuid,
    required String productId,
    required String transactionId,
    required String receipt,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/ios_in_app_purchase/verify_receipt_with_apple',
        {
          'uuid': uuid,
          'product_id': productId,
          'original_transaction_id': transactionId,
          'receipt_data': receipt,
        },
      );

      debugPrint('verifyPurchase response: $response');
      return response['response']['success'] == '1';
    } catch (e) {
      debugPrint('Error verifying purchase: $e');
      return false;
    }
  }
}
