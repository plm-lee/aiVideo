import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:ai_video/api/pay_api.dart';
import 'package:ai_video/models/system.dart';
import 'package:ai_video/service/auth_service.dart';

class ApplePaymentService {
  static final ApplePaymentService _instance = ApplePaymentService._internal();
  factory ApplePaymentService() => _instance;
  ApplePaymentService._internal();

  final AuthService _authService = AuthService();
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = []; // 订阅包
  List<ProductDetails> _subscribeProducts = []; // 订阅包
  List<ProductDetails> _coinsProducts = []; // 金币包
  // 定义商品ID
  final Map<String, String> productMap = {};

  // 初始化 根据传入参数判断是订阅包还是金币包
  Future<void> initialize(String type) async {
    if (await _inAppPurchase.isAvailable()) {
      _subscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () => _subscription?.cancel(),
        onError: (error) => debugPrint('Error: $error'),
      );

      await _loadProducts(type);
    }
  }

  // 返回订阅包
  List<ProductDetails> get subscribeProducts => _subscribeProducts;

  // 返回金币包
  List<ProductDetails> get coinsProducts => _coinsProducts;

  Future<void> _loadProducts(String type) async {
    // 根据type获取对应的包
    await (type == 'subscribe'
        ? fetchSubscribePackages()
        : fetchCoinsPackages());

    final products = type == 'subscribe' ? _subscribeProducts : _coinsProducts;
    final Set<String> productIds = products.map((p) => p.id).toSet();

    // 将接口中获取到的商品信息添加到productMap中
    productMap.addAll(Map.fromEntries(
      products.map((p) => MapEntry(p.title, p.id)),
    ));
    debugPrint('productMap: $productMap');

    try {
      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(productIds);
      if (response.error != null) {
        debugPrint('Error loading products: ${response.error}');
        return;
      }
      debugPrint('response: $response');

      _products = response.productDetails;

      if (_products.isEmpty) {
        debugPrint('No products found');
      }

      // 打印商品信息
      debugPrint('Products: $_products');
    } catch (e) {
      debugPrint('Error loading products: $e');
    }
  }

  Future<void> buySubscription(String productName) async {
    try {
      final String? productId = productMap[productName];
      if (productId == null) {
        throw Exception('Product not found: $productName');
      }

      final productDetails = _products.firstWhere(
        (product) => product.id == productId,
        orElse: () => throw Exception('Product details not found: $productId'),
      );

      final purchaseParam = PurchaseParam(productDetails: productDetails);
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('Error buying subscription: $e');
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

  // 获取订阅包
  Future<void> fetchSubscribePackages() async {
    final (success, message, user) = await _authService.getCurrentUser();
    if (!success || user == null) {
      throw Exception('Failed to fetch purchase packages: user not found');
    }

    final response = await PayApi().fetchPurchasePackages(uuid: user.uuid);
    if (response['response']['success'] != '1') {
      // 弹窗提醒
      throw Exception(
          'Failed to fetch purchase packages: ${response['response']['description']}');
    }

    final List<SubscriptionPackage> subscriptionPackages =
        (response['subscribe_pkg'] as List)
            .map((e) => SubscriptionPackage.fromJson(e))
            .toList();

    _subscribeProducts = subscriptionPackages
        .map((e) => ProductDetails(
              id: e.productId,
              title: e.productName,
              description: e.amount.toString(),
              price: e.amount.toString(),
              rawPrice: e.amount,
              currencyCode: 'USD',
            ))
        .toList();
  }

  // 获取金币购买包
  Future<void> fetchCoinsPackages() async {
    final (success, message, user) = await _authService.getCurrentUser();
    if (!success || user == null) {
      throw Exception('Failed to fetch purchase packages: user not found');
    }

    final response = await PayApi().fetchPurchasePackages(uuid: user.uuid);
    if (response['response']['success'] != '1') {
      throw Exception(
          'Failed to fetch purchase packages: ${response['response']['description']}');
    }

    final List<SubscriptionPackage> subscriptionPackages =
        (response['coin_pkg'] as List)
            .map((e) => SubscriptionPackage.fromJson(e))
            .toList();

    _coinsProducts = subscriptionPackages
        .map((e) => ProductDetails(
              id: e.productId,
              title: e.productName,
              description: e.amount.toString(),
              price: e.amount.toString(),
              rawPrice: e.amount,
              currencyCode: 'USD',
            ))
        .toList();
  }
}
