import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // 导入 Cupertino 库
import 'package:go_router/go_router.dart';
import 'package:ai_video/service/apple_payment_service.dart';
import 'buy_coins_page.dart'; // 导入新页面
import 'package:video_player/video_player.dart';

class BuyCreditsPage extends StatefulWidget {
  const BuyCreditsPage({super.key});

  @override
  State<BuyCreditsPage> createState() => _BuyCreditsPageState();
}

class _BuyCreditsPageState extends State<BuyCreditsPage> {
  int? _selectedIndex;
  static const List<int> _hotDealIndexes = [1, 2];
  final ApplePaymentService _applePaymentService = ApplePaymentService();
  bool _isLoading = false;
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    if (_hotDealIndexes.isNotEmpty) {
      _selectedIndex = _hotDealIndexes[0];
    }
    _applePaymentService.initialize();
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
    setState(() {
      _isLoading = true;
    });

    try {
      await _applePaymentService.buySubscription('weekly');
      _showSuccessDialog();
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Subscription Successful'),
          content:
              const Text('Your subscription has been activated successfully.'),
          actions: <Widget>[
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String error) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text('An error occurred: $error'),
          actions: <Widget>[
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF4A4A4A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BuyCoinsPage()),
                );
              },
              child: Row(
                children: [
                  const Icon(Icons.monetization_on,
                      color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  const Text(
                    'Buy Coins',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_controller.value.isInitialized)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height / 2,
              child: Opacity(
                opacity: 0.5,
                child: VideoPlayer(_controller),
              ),
            ),
          Column(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Spacer(), // 添加 Spacer 留出上方空白
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [Color(0xFFD7905F), Color(0xFFC060C3)],
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
                ),
              ),
              _buildBottomSection(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return SizedBox(
      width: 280, // 设置固定宽度以保持一致性
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
              child: const Icon(
                Icons.check,
                color: Colors.pink,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
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
          const Text(
            '\$8.99 / week',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 4),
          const Text(
            'Renews automatically, cancel anytime.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFD7905F), Color(0xFFC060C3)],
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
          children: const [
            Text(
              'Weekly Renewal',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '\$8.99',
              style: TextStyle(
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
