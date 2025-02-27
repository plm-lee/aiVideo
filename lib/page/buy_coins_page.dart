import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:video_player/video_player.dart';
import 'package:ai_video/service/apple_payment_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:ai_video/utils/dialog_utils.dart';

class BuyCoinsPage extends StatefulWidget {
  const BuyCoinsPage({super.key});

  @override
  _BuyCoinsPageState createState() => _BuyCoinsPageState();
}

class _BuyCoinsPageState extends State<BuyCoinsPage> {
  late VideoPlayerController _controller;
  final ApplePaymentService _applePaymentService = ApplePaymentService();
  int? selectedPlan;
  List<ProductDetails> _products = [];
  bool _isLoading = false;
  bool _isLoadingProducts = true;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      _products = _applePaymentService.coinsProducts;
      if (_products.isNotEmpty) {
        selectedPlan = 0;
      }
    } catch (e) {
      debugPrint('加载商品失败: $e');
    } finally {
      setState(() => _isLoadingProducts = false);
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextButton.icon(
              onPressed: () {
                // TODO: 显示金币详情
              },
              icon:
                  const Icon(Icons.info_outline, color: Colors.white, size: 20),
              label: const Text(
                'Coins Details',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_controller.value.isInitialized) _buildVideoBackground(),
          Column(
            children: [
              const Spacer(),
              const Text(
                'Coins 33% OFF',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              if (_isLoadingProducts)
                const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFD7905F)),
                  ),
                )
              else if (_products.isEmpty)
                const Center(
                  child: Text(
                    '暂无可用商品',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                )
              else
                // 遍历_products并构建选项
                ..._products
                    .map((product) => _buildCoinOption(
                          coins: product.title,
                          price: product.price,
                          discount: '33%',
                          isSelected:
                              selectedPlan == _products.indexOf(product),
                          onTap: () => setState(
                              () => selectedPlan = _products.indexOf(product)),
                        ))
                    .toList(),
              _buildBottomSection(context),
            ],
          ),
        ],
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

  Widget _buildCoinOption({
    required String coins,
    required String price,
    String? discount,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [Color(0xFFD7905F), Color(0xFFC060C3)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isSelected ? null : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$coins Coins',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                if (discount != null)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.pink.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'save $discount',
                      style: const TextStyle(
                        color: Colors.pink,
                        fontSize: 12,
                      ),
                    ),
                  ),
                Text(
                  '\$$price',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePurchase() async {
    if (selectedPlan == null || selectedPlan! >= _products.length) return;

    setState(() => _isLoading = true);

    try {
      final product = _products[selectedPlan!];

      // 调用苹果支付
      await _applePaymentService.purchaseCoins(
        product.description,
      );

      // 支付成功
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    DialogUtils.showSuccess(
      context: context,
      content: 'Your coins have been added to your account.',
    );
  }

  void _showErrorDialog(String error) {
    DialogUtils.showError(
      context: context,
      content: 'An error occurred: $error',
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD7905F), Color(0xFFC060C3)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: ElevatedButton(
              onPressed: selectedPlan != null ? _handlePurchase : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    )
                  : const Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
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
          ),
        ],
      ),
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
