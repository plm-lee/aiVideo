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
  List<ProductDetails> _products = [];
  List<ProductDetails> _subscribeProducts = [];
  List<ProductDetails> _coinsProducts = [];
  final Map<String, String> productMap = {};
  bool _isInitialized = false;

  // 初始化所有商品
  Future<void> initialize() async {
    if (_isInitialized) return;

    if (await _inAppPurchase.isAvailable()) {
      _subscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () => _subscription?.cancel(),
        onError: (error) => debugPrint('Error: $error'),
      );

      await fetchAllProducts();

      // 合并两种商品到 _products
      _products = [..._subscribeProducts, ..._coinsProducts];

      // 查询所有商品详情
      final Set<String> productIds = _products.map((p) => p.id).toSet();

      try {
        final ProductDetailsResponse response =
            await _inAppPurchase.queryProductDetails(productIds);

        if (response.error != null) {
          debugPrint('Error loading products: ${response.error}');
          return;
        }

        // 更新商品映射
        productMap.clear();
        productMap.addAll(Map.fromEntries(
          _products.map((p) => MapEntry(p.title, p.id)),
        ));

        debugPrint('productMap: $productMap');

        if (_products.isEmpty) {
          debugPrint('No products found');
        }
      } catch (e) {
        debugPrint('Error loading products: $e');
      }

      _isInitialized = true;
    }
  }

  // 返回所有商品
  List<ProductDetails> get products => _products;

  // 返回订阅包
  List<ProductDetails> get subscribeProducts => _subscribeProducts;

  // 返回金币包
  List<ProductDetails> get coinsProducts => _coinsProducts;

  Future<void> buySubscription(String productName,
      {required String orderId}) async {
    try {
      final String? productId = productMap[productName];
      if (productId == null) {
        throw Exception('Product not found: $productName');
      }

      final productDetails = _products.firstWhere(
        (product) => product.id == productId,
        orElse: () => throw Exception('Product details not found: $productId'),
      );

      final purchaseParam = PurchaseParam(
        productDetails: productDetails,
        applicationUserName: orderId,
      );

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

  // 获取所有商品
  Future<void> fetchAllProducts() async {
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

    final List<SubscriptionPackage> coinPackages =
        (response['coin_pkg'] as List)
            .map((e) => SubscriptionPackage.fromJson(e))
            .toList();

    _coinsProducts = coinPackages
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

  // 预支付获取订单号逻辑
  Future<String> prepayOrder({required String coinPackageId}) async {
    final (success, message, user) = await _authService.getCurrentUser();
    if (!success || user == null) {
      throw Exception('预支付失败: 用户未登录');
    }

    final response = await PayApi().prepayOrder(
      uuid: user.uuid,
      coinPackageId: coinPackageId,
    );
    // 打印response
    debugPrint('response: $response');

    if (response['response']['success'] != '1') {
      throw Exception(
        '预支付失败: ${response['response']['description']}',
      );
    }

    return response['response']['order_id'] as String;
  }
}
