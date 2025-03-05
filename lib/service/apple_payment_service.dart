import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:ai_video/api/pay_api.dart';
import 'package:ai_video/models/system.dart';
import 'package:ai_video/service/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApplePaymentService {
  static final ApplePaymentService _instance = ApplePaymentService._internal();
  factory ApplePaymentService() => _instance;
  ApplePaymentService._internal();

  static const String _prepayOrderPrefix = 'prepay_order_';
  SharedPreferences? _prefs;

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

  // 初始化 SharedPreferences
  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // 保存预支付订单号，确保重复的key会被覆盖
  Future<void> _savePrepayOrder(String productId, String orderId) async {
    try {
      await _initPrefs();
      final key = '$_prepayOrderPrefix$productId';

      // 检查是否存在旧的订单号
      final oldOrderId = _prefs?.getString(key);
      if (oldOrderId != null) {
        debugPrint('发现旧的预支付订单号: $oldOrderId，将被新订单号覆盖: $orderId');
      }

      // 强制覆盖旧值
      await _prefs?.setString(key, orderId);
    } catch (e) {
      debugPrint('保存预支付订单号失败: $e');
      rethrow;
    }
  }

  // 获取预支付订单号
  Future<String?> _getPrepayOrder(String productId) async {
    await _initPrefs();
    return _prefs?.getString('$_prepayOrderPrefix$productId');
  }

  // 删除预支付订单号
  Future<void> _removePrepayOrder(String productId) async {
    await _initPrefs();
    await _prefs?.remove('$_prepayOrderPrefix$productId');
  }

  // 初始化所有商品
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _initPrefs();

      if (!await _inAppPurchase.isAvailable()) {
        throw Exception('In-app purchases are not available');
      }

      // 设置购买监听
      _subscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () => _subscription?.cancel(),
        onError: (error) {
          debugPrint('Purchase stream error: $error');
          _subscription?.cancel();
        },
      );

      // 获取商品信息
      await fetchAllProducts();

      // 合并两种商品到 _products
      _products = [..._subscribeProducts, ..._coinsProducts];

      // 查询苹果商店的商品详情
      await _queryStoreProducts();

      // 清理未完成的交易
      await cleanupPendingTransactions();

      _isInitialized = true;
    } catch (e) {
      debugPrint('初始化支付服务失败: $e');
      rethrow;
    }
  }

  // 查询苹果商店的商品详情
  Future<void> _queryStoreProducts() async {
    try {
      final Set<String> productIds = _products.map((p) => p.id).toSet();
      if (productIds.isEmpty) {
        debugPrint('没有可查询的商品ID');
        return;
      }

      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(productIds);

      if (response.error != null) {
        throw Exception('查询商品详情失败: ${response.error}');
      }

      if (response.productDetails.isEmpty) {
        throw Exception('未找到商品信息');
      }

      // 更新商品信息
      _updateProductsWithStoreInfo(response.productDetails);
    } catch (e) {
      debugPrint('查询商品详情失败: $e');
      rethrow;
    }
  }

  // 使用苹果商店的信息更新商品详情
  void _updateProductsWithStoreInfo(List<ProductDetails> storeProducts) {
    for (var storeProduct in storeProducts) {
      // 更新订阅商品
      final subIndex =
          _subscribeProducts.indexWhere((p) => p.id == storeProduct.id);
      if (subIndex != -1) {
        _subscribeProducts[subIndex] = storeProduct;
      }

      // 更新金币商品
      final coinIndex =
          _coinsProducts.indexWhere((p) => p.id == storeProduct.id);
      if (coinIndex != -1) {
        _coinsProducts[coinIndex] = storeProduct;
      }
    }

    // 更新合并的商品列表
    _products = [..._subscribeProducts, ..._coinsProducts];
  }

  // 返回所有商品
  List<ProductDetails> get products => _products;

  // 返回订阅包
  List<ProductDetails> get subscribeProducts => _subscribeProducts;

  // 返回金币包
  List<ProductDetails> get coinsProducts => _coinsProducts;

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    try {
      final (success, message, user) = await _authService.getCurrentUser();
      if (!success || user == null) {
        throw Exception('Failed to verify purchase: user not found');
      }

      // 获取预支付订单号
      String? orderId = await _getPrepayOrder(purchaseDetails.productID);
      debugPrint('获取到的预支付订单号: $orderId');

      if (orderId == null) {
        // 如果找不到预支付订单号，尝试从 applicationUsername 获取
        orderId = purchaseDetails.purchaseID;
        debugPrint('使用 purchaseID 作为订单号: $orderId');
      }

      if (orderId == null) {
        throw Exception('无效的交易ID');
      }

      debugPrint('使用订单号验证支付: $orderId');
      final ok = await PayApi().verifyPurchase(
        uuid: user.uuid,
        productId: purchaseDetails.productID,
        transactionId: orderId,
        receipt: purchaseDetails.verificationData.serverVerificationData,
      );

      if (!ok) {
        debugPrint('服务端验证支付失败');
      }

      return true;
    } catch (e) {
      debugPrint('Error verifying purchase: $e');
      return false;
    }
  }

  Future<void> _handlePurchaseUpdates(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      debugPrint(
          '处理购买更新: ${purchaseDetails.productID}, 状态: ${purchaseDetails.status}');

      try {
        switch (purchaseDetails.status) {
          case PurchaseStatus.pending:
            _setLoading(true);
            debugPrint('购买处理中...');
            break;

          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            await _handleSuccessfulPurchase(purchaseDetails);
            break;

          case PurchaseStatus.error:
            await _handlePurchaseError(purchaseDetails);
            break;

          case PurchaseStatus.canceled:
            _handlePurchaseCancel();
            break;
        }

        if (purchaseDetails.pendingCompletePurchase) {
          debugPrint('完成待处理的购买');
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      } catch (e) {
        debugPrint('处理购买更新时出错: $e');
        _setLoading(false);
        rethrow;
      }
    }
  }

  Future<void> _handleSuccessfulPurchase(
      PurchaseDetails purchaseDetails) async {
    debugPrint('处理成功的购买');
    try {
      final valid = await _verifyPurchase(purchaseDetails);
      if (valid) {
        await _deliverProduct(purchaseDetails);
        debugPrint('购买完成并验证成功');
        _purchaseSuccessController.add(true);
      } else {
        throw Exception('购买验证失败');
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _handlePurchaseError(PurchaseDetails purchaseDetails) async {
    debugPrint('购买错误: ${purchaseDetails.error?.message ?? "未知错误"}');
    _setLoading(false);
    throw Exception(purchaseDetails.error?.message ?? '购买失败');
  }

  void _handlePurchaseCancel() {
    debugPrint('购买已取消');
    _setLoading(false);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _loadingController.add(value);
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
      debugPrint('fetchPurchasePackages response: $response');
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
    if (!_isInitialized) {
      await initialize();
    }

    try {
      _setLoading(true);

      final product = _coinsProducts.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('未找到商品: $productId'),
      );

      // 清理未完成的交易
      await cleanupPendingTransactions();

      // 获取预支付订单号
      final orderId =
          await prepayOrder(productUuid: _productUuidMap[productId] ?? '');
      await _savePrepayOrder(productId, orderId);
      debugPrint('金币预支付订单号: productId=$productId, orderId=$orderId');

      final purchaseParam = PurchaseParam(
        productDetails: product,
        applicationUserName: orderId,
      );

      final success =
          await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
      if (!success) {
        throw Exception('启动购买失败');
      }
    } catch (e) {
      debugPrint('购买金币失败: $e');
      _setLoading(false);
      rethrow;
    }
  }

  // 清理所有未完成的交易
  Future<void> cleanupPendingTransactions() async {
    try {
      debugPrint('开始清理未完成的交易...');

      if (Platform.isIOS) {
        debugPrint('iOS平台，直接清理交易队列...');
        final transactions = await SKPaymentQueueWrapper().transactions();
        debugPrint('发现 ${transactions.length} 个待处理交易');

        for (var transaction in transactions) {
          try {
            await SKPaymentQueueWrapper().finishTransaction(transaction);
            debugPrint('成功完成交易: ${transaction.transactionIdentifier}');
          } catch (e) {
            debugPrint('完成交易失败: ${transaction.transactionIdentifier}, 错误: $e');
          }
        }
      }

      // 创建一个新的 Stream 订阅来处理未完成的交易
      final completer = Completer<void>();
      StreamSubscription<List<PurchaseDetails>>? subscription;
      bool hasCompletedAnyPurchase = false;

      subscription = _inAppPurchase.purchaseStream.listen(
        (purchaseDetailsList) async {
          try {
            for (var purchase in purchaseDetailsList) {
              debugPrint(
                  '检查交易状态: ${purchase.productID}, status: ${purchase.status}');

              if (purchase.pendingCompletePurchase) {
                debugPrint('发现未完成的交易: ${purchase.productID}');
                try {
                  await _inAppPurchase.completePurchase(purchase);
                  hasCompletedAnyPurchase = true;
                  debugPrint('成功完成交易: ${purchase.productID}');
                } catch (e) {
                  debugPrint('完成交易失败: ${purchase.productID}, 错误: $e');
                }
              }
            }

            if (!hasCompletedAnyPurchase) {
              debugPrint('没有发现需要清理的待处理交易');
            }

            if (!completer.isCompleted) {
              completer.complete();
            }
          } catch (e) {
            debugPrint('处理交易时出错: $e');
            if (!completer.isCompleted) {
              completer.completeError(e);
            }
          }
        },
        onError: (error) {
          debugPrint('清理交易流监听错误: $error');
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
          subscription?.cancel();
        },
        onDone: () {
          debugPrint('清理交易流监听完成');
          if (!completer.isCompleted) {
            completer.complete();
          }
          subscription?.cancel();
        },
      );

      // 等待5秒或直到完成
      await completer.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          subscription?.cancel();
          debugPrint('清理交易超时 - 已等待2秒');
        },
      );

      debugPrint('清理交易流程完成');
    } catch (e) {
      debugPrint('清理未完成交易失败: $e');
      rethrow;
    }
  }

  // 购买订阅
  Future<void> purchaseSubscription() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      _setLoading(true);

      if (_subscribeProducts.isEmpty) {
        throw Exception('没有可用的订阅产品');
      }

      final product = _subscribeProducts.first;

      // 清理未完成的交易
      await cleanupPendingTransactions();

      // 获取预支付订单号
      final orderId =
          await prepayOrder(productUuid: _productUuidMap[product.id] ?? '');
      await _savePrepayOrder(product.id, orderId);
      debugPrint('订阅预支付订单号: productId=${product.id}, orderId=$orderId');

      final purchaseParam = PurchaseParam(
        productDetails: product,
        applicationUserName: orderId,
      );

      final success =
          await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      if (!success) {
        throw Exception('启动购买失败');
      }
    } catch (e) {
      debugPrint('购买订阅失败: $e');
      _setLoading(false);
      rethrow;
    }
  }
}
