import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class ApplePaymentService {
  static final ApplePaymentService _instance = ApplePaymentService._internal();
  factory ApplePaymentService() => _instance;
  ApplePaymentService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  // 定义商品ID
  final Map<String, String> productIds = {
    'weekly': 'com.bigchallenger.magaVideo.subscription.weekly.pro',
    '1500': 'com.bigchallenger.magaVideo.consumable.coins1500',
  };

  Future<void> initialize() async {
    if (await _inAppPurchase.isAvailable()) {
      _subscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () => _subscription?.cancel(),
        onError: (error) => debugPrint('Error: $error'),
      );

      await _loadProducts();
    }
  }

  Future<void> _loadProducts() async {
    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(productIds.values.toSet());

    if (response.error != null) {
      debugPrint('Error loading products: ${response.error}');
      return;
    }

    _products = response.productDetails;
  }

  Future<void> buySubscription(String productName) async {
    try {
      final String? productId = productIds[productName];
      if (productId == null) {
        throw Exception('未找到产品: $productName');
      }

      final productDetails = _products.firstWhere(
        (product) => product.id == productId,
        orElse: () => throw Exception('未找到产品详情: $productId'),
      );

      final purchaseParam = PurchaseParam(productDetails: productDetails);
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('购买失败: $e');
      rethrow;
    }
  }

  Future<void> _handlePurchaseUpdates(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        // Handle successful purchase
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Handle error
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
