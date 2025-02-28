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
  Map<String, String> _productUuidMap = {}; // 商品id和uuid的映射
  bool _isInitialized = false;

  // 添加支付状态跟踪
  final StreamController<bool> _loadingController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _purchaseSuccessController =
      StreamController<bool>.broadcast();
  Stream<bool> get loadingStream => _loadingController.stream;
  Stream<bool> get purchaseSuccessStream => _purchaseSuccessController.stream;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

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
      debugPrint('Purchase status: ${purchaseDetails.status}');
      debugPrint('Product ID: ${purchaseDetails.productID}');

      try {
        switch (purchaseDetails.status) {
          case PurchaseStatus.pending:
            debugPrint('Purchase pending...');
            continue;
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            final valid = await _verifyPurchase(purchaseDetails);
            if (valid) {
              await _deliverProduct(purchaseDetails);
              debugPrint('Purchase completed successfully');
              _isLoading = false;
              _loadingController.add(false);
              _purchaseSuccessController.add(true);
            } else {
              throw Exception('Purchase verification failed');
            }
            break;
          case PurchaseStatus.error:
            _isLoading = false;
            _loadingController.add(false);
            throw Exception(
                purchaseDetails.error?.message ?? 'Purchase failed');
          case PurchaseStatus.canceled:
            debugPrint('Purchase canceled');
            _isLoading = false;
            _loadingController.add(false);
            break;
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      } catch (e) {
        debugPrint('Error handling purchase: $e');
        _isLoading = false;
        _loadingController.add(false);
        rethrow;
      }
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    try {
      debugPrint(
          'purchaseDetails: ${purchaseDetails.productID}, ${purchaseDetails.purchaseID}, ${purchaseDetails.verificationData.serverVerificationData}');

      final (success, message, user) = await _authService.getCurrentUser();
      if (!success || user == null) {
        throw Exception('Failed to verify purchase: user not found');
      }

      final ok = await PayApi().verifyPurchase(
        uuid: user.uuid,
        productId: purchaseDetails.productID,
        transactionId: purchaseDetails.purchaseID ?? '',
        receipt: purchaseDetails.verificationData.serverVerificationData,
      );

      return ok;
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

  void dispose() {
    _subscription?.cancel();
    _loadingController.close();
    _purchaseSuccessController.close();
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

      // 构建商品id和uuid的映射
      _productUuidMap = Map.fromEntries(
        allPackages.map((e) => MapEntry(e.description, e.uuid)),
      );

      // 处理订阅产品
      _subscribeProducts = allPackages
          .where((e) => e.isSubscription)
          .map((e) => ProductDetails(
                id: e.description,
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
                id: e.description,
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

    return response['original_transaction_id'] as String;
  }

  // 购买金币
  Future<void> purchaseCoins(String productId) async {
    if (!_isInitialized) await fetchAllProducts();

    try {
      // 找到产品的uuid
      final product =
          _coinsProducts.firstWhere((p) => p.description == productId);
      final orderId =
          await prepayOrder(productUuid: _productUuidMap[productId] ?? '');

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
      _isLoading = true;
      _loadingController.add(true);

      if (_subscribeProducts.isEmpty) {
        throw Exception('No subscription products available');
      }

      final product = _subscribeProducts.first;
      final orderId =
          await prepayOrder(productUuid: _productUuidMap[product.id] ?? '');

      final purchaseParam = PurchaseParam(
        productDetails: product,
        applicationUserName: orderId,
      );

      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('Error purchasing subscription: $e');
      _isLoading = false;
      _loadingController.add(false);
      rethrow;
    }
  }
}
