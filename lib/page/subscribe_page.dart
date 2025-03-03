import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // 导入 Cupertino 库
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:ai_video/service/apple_payment_service.dart';
import 'buy_coins_page.dart'; // 导入新页面
import 'package:video_player/video_player.dart';
import 'package:ai_video/utils/dialog_utils.dart';

class SubscribePage extends StatefulWidget {
  const SubscribePage({super.key});

  @override
  State<SubscribePage> createState() => _SubscribePageState();
}

class _SubscribePageState extends State<SubscribePage> {
  final ApplePaymentService _applePaymentService = ApplePaymentService();
  bool _isLoading = false;
  bool _hasShownSuccessDialog = false;
  ProductDetails? _subscribeProduct;
  late VideoPlayerController _controller;

  static const Color _backgroundColor = Colors.black;
  static const Color _buttonColor = Color(0xFF4A4A4A);
  static const Color _gradientStartColor = Color(0xFFD7905F);
  static const Color _gradientEndColor = Color(0xFFC060C3);

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
    _loadProducts();
    // 监听支付状态
    _applePaymentService.loadingStream.listen((isLoading) {
      if (mounted) {
        setState(() => _isLoading = isLoading);
      }
    });
    // 监听支付成功
    _applePaymentService.purchaseSuccessStream.listen((_) {
      if (mounted) {
        // 只弹窗一次
        if (!_hasShownSuccessDialog) {
          _showSuccessDialog();
          _hasShownSuccessDialog = true;
        }
      }
    });
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final _products = _applePaymentService.subscribeProducts;
      if (_products.isNotEmpty) {
        _subscribeProduct = _products.first;
      } else {
        // 更新订阅产品
        await _applePaymentService.fetchAllProducts();
        final _products = _applePaymentService.subscribeProducts;
        if (_products.isNotEmpty) {
          _subscribeProduct = _products.first;
        }
      }
    } catch (e) {
      debugPrint('加载商品失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _initializeVideoPlayer() {
    _controller = VideoPlayerController.asset('assets/videos/background.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
      });
  }

  @override
  void dispose() {
    _applePaymentService.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSubscription() async {
    try {
      // 调用订阅接口
      await _applePaymentService.purchaseSubscription();
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showSuccessDialog() {
    DialogUtils.showSuccess(
      context: context,
      content: 'Your subscription has been activated successfully.',
    );
  }

  void _showErrorDialog(String error) {
    DialogUtils.showError(
      context: context,
      content: 'An error occurred: $error',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [_buildBuyCoinsButton()],
      ),
      body: Stack(
        children: [
          if (_controller.value.isInitialized) _buildVideoBackground(),
          Column(
            children: [
              Expanded(child: _buildContent()),
              _buildBottomSection(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBuyCoinsButton() {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _buttonColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BuyCoinsPage()),
        ),
        child: Row(
          children: const [
            Icon(Icons.monetization_on, color: Colors.amber, size: 20),
            SizedBox(width: 4),
            Text('Buy Coins', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoBackground() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: MediaQuery.of(context).size.height / 2,
      child: Opacity(
        opacity: 0.5,
        child: VideoPlayer(_controller),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        const Spacer(),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [_gradientStartColor, _gradientEndColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'Get MagaVideo Pro',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFeatureItem('1200 Coins Refresh Weekly'),
              _buildFeatureItem('Up to 5 tasks in queue'),
              _buildFeatureItem('Pro Quality Videos'),
              _buildFeatureItem('Fast-track Generation'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String text) {
    return SizedBox(
      width: 280,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.pink.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.pink, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildWeeklyRenewalCard(),
          const SizedBox(height: 16),
          Text(
            _subscribeProduct != null
                ? '\$${_subscribeProduct!.price} / week'
                : '\$8.99 / week',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 4),
          const Text(
            'Renews automatically, cancel anytime.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          _buildContinueButton(),
          const SizedBox(height: 16),
          _buildFooterLinks(),
        ],
      ),
    );
  }

  Widget _buildWeeklyRenewalCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Weekly Renewal',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _subscribeProduct?.price ?? '8.99',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_gradientStartColor, _gradientEndColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: ElevatedButton(
        onPressed: _handleSubscription,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator()
            : const Text(
                'Continue',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildFooterLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTextButton('Terms'),
        const Text(' • ', style: TextStyle(color: Colors.grey)),
        _buildTextButton('Privacy'),
        const Text(' • ', style: TextStyle(color: Colors.grey)),
        _buildTextButton('Restore Purchase'),
        const Text(' • ', style: TextStyle(color: Colors.grey)),
        _buildTextButton('What are Coins?'),
      ],
    );
  }

  Widget _buildTextButton(String text) {
    return TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
