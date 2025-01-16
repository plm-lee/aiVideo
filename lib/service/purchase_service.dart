import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails>? _products;

  // 定义商品ID
  final Map<String, String> productIds = {
    '600': 'com.bigchallenger.app.credits.600',
    '1200': 'com.bigchallenger.app.credits.1200',
    '5000': 'com.bigchallenger.app.credits.5000',
    '10000': 'com.bigchallenger.app.credits.10000',
    '38000': 'com.bigchallenger.app.credits.38000',
  };

  Future<void> initialize() async {
    if (await _inAppPurchase.isAvailable()) {
      // 监听购买流
      _subscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () => _subscription?.cancel(),
        onError: (error) => debugPrint('Error: $error'),
      );

      await _loadProducts();

      if (Platform.isIOS) {
        final paymentWrapper = SKPaymentQueueWrapper();
        paymentWrapper.setDelegate(ExamplePaymentQueueDelegate());
      }
    }
  }

  Future<void> _loadProducts() async {
    try {
      final response = await _inAppPurchase.queryProductDetails(
        productIds.values.toSet(),
      );

      if (response.error != null) {
        debugPrint('Error loading products: ${response.error}');
        return;
      }

      _products = response.productDetails;

      if (_products!.isEmpty) {
        debugPrint('No products found');
      }
    } catch (e) {
      debugPrint('Error loading products: $e');
    }
  }

  Future<bool> buyProduct(String credits) async {
    try {
      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails({productIds[credits]!});

      if (response.productDetails.isEmpty) {
        debugPrint('Product not found in store');
        return false;
      }

      final purchaseParam = PurchaseParam(
        productDetails: response.productDetails.first,
      );

      return await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('Error making purchase: $e');
      return false;
    }
  }

  Future<void> _handlePurchaseUpdates(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      try {
        if (purchaseDetails.status == PurchaseStatus.pending) {
          // 显示加载指示器
          continue;
        }

        if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint('Purchase error: ${purchaseDetails.error}');
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          final valid = await _verifyPurchase(purchaseDetails);
          if (valid) {
            await _deliverProduct(purchaseDetails);
          }
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      } catch (e) {
        debugPrint('Error handling purchase update: $e');
      }
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    try {
      // TODO: 实现购买验证逻辑
      return true;
    } catch (e) {
      debugPrint('Error verifying purchase: $e');
      return false;
    }
  }

  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    try {
      // TODO: 实现商品交付逻辑
    } catch (e) {
      debugPrint('Error delivering product: $e');
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}

/// 苹果支付队列代理
class ExamplePaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
    SKPaymentTransactionWrapper transaction,
    SKStorefrontWrapper storefront,
  ) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}
