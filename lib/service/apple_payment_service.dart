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
    try {
      final (success, message, user) = await _authService.getCurrentUser();
      if (!success || user == null) {
        throw Exception('Failed to fetch products: user not found');
      }

      final response = await PayApi().fetchPurchasePackages(uuid: user.uuid);
      if (response['response']['success'] != '1') {
        throw Exception(
            'Failed to fetch products: ${response['response']['description']}');
      }

      final List<SubscriptionPackage> allPackages =
          (response['products'] as List)
              .map((e) => SubscriptionPackage.fromJson(e))
              .toList();

      debugPrint('allPackages: $allPackages');

      // 处理订阅产品
      _subscribeProducts = allPackages
          .where((e) => e.isSubscription)
          .map((e) => ProductDetails(
                id: e.uuid,
                title: e.name,
                description: e.description,
                price: (e.price / 100).toStringAsFixed(2),
                rawPrice: e.price / 100,
                currencyCode: 'USD',
                currencySymbol: '\$',
              ))
          .toList();

      // 处理金币产品
      _coinsProducts = allPackages
          .where((e) => !e.isSubscription)
          .map((e) => ProductDetails(
                id: e.uuid,
                title: e.name,
                description: e.description,
                price: (e.price / 100).toStringAsFixed(2),
                rawPrice: e.price / 100,
                currencyCode: 'USD',
                currencySymbol: '\$',
              ))
          .toList();

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error fetching products: $e');
      rethrow;
    }
  }

  // 预支付获取订单号逻辑
  Future<String> prepayOrder({required String productUuid}) async {
    final (success, message, user) = await _authService.getCurrentUser();
    if (!success || user == null) {
      throw Exception('预支付失败: 用户未登录');
    }

    final response = await PayApi().prepayOrder(
      uuid: user.uuid,
      productUuid: productUuid,
    );
    // 打印response
    debugPrint('response: $response');

    if (response['response']['success'] != '1') {
      throw Exception(
        '预支付失败: ${response['response']['description']}',
      );
    }

    return response['response']['original_transaction_id'] as String;
  }

  // 购买金币
  Future<void> purchaseCoins(String productId) async {
    if (!_isInitialized) await fetchAllProducts();

    try {
      // 找到产品的uuid
      final product =
          _coinsProducts.firstWhere((p) => p.description == productId);
      final orderId = await prepayOrder(productUuid: product.id);

      final purchaseParam = PurchaseParam(
        productDetails: product,
        applicationUserName: orderId,
      );

      await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('Error purchasing coins: $e');
      rethrow;
    }
  }

  // 购买订阅
  Future<void> purchaseSubscription() async {
    if (!_isInitialized) await fetchAllProducts();

    try {
      if (_subscribeProducts.isEmpty) {
        throw Exception('No subscription products available');
      }

      final product = _subscribeProducts.first;
      final orderId = await prepayOrder(productUuid: product.id);

      final purchaseParam = PurchaseParam(
        productDetails: product,
        applicationUserName: orderId,
      );

      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('Error purchasing subscription: $e');
      rethrow;
    }
  }
}
