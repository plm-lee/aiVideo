import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ai_video/service/user_service.dart';
import 'package:share_plus/share_plus.dart';

class ReferFriendsPage extends StatefulWidget {
  const ReferFriendsPage({super.key});

  @override
  State<ReferFriendsPage> createState() => _ReferFriendsPageState();
}

class _ReferFriendsPageState extends State<ReferFriendsPage> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _redeemCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a referral code'),
          backgroundColor: Color(0xFF2A2A2A),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: 实现兑换推荐码的逻辑
      await Future.delayed(const Duration(seconds: 2)); // 模拟网络请求

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully redeemed 100 coins!'),
            backgroundColor: Color(0xFF2A2A2A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to redeem code: $e'),
            backgroundColor: const Color(0xFF2A2A2A),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Refer friends',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          // 粉色渐变背景
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [
                  Color(0xFFD7905F), // 应用主题的橙色
                  Color(0xFFC060C3), // 应用主题的紫色
                  Colors.transparent,
                ],
                stops: [0.0, 0.3, 0.5],
              ),
            ),
          ),
          // 内容遮罩层
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black87,
                  Colors.black,
                ],
                stops: [0.0, 0.5, 0.8],
              ),
            ),
          ),
          // 内容
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Copy your referral code\nand share with',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      height: 1.3,
                    ),
                  ),
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'your friends to ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                          ),
                        ),
                        TextSpan(
                          text: 'earn rewards!',
                          style: TextStyle(
                            color: Color(0xFFD7905F),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildStepCard(
                          number: '1',
                          title: 'Copy and share your referral code',
                          child: _buildReferralCodeCard(context),
                        ),
                        _buildStepCard(
                          number: '2',
                          title: 'Referral downloads the VideoMax app',
                        ),
                        _buildStepCard(
                          number: '3',
                          title:
                              'Referral opens the VideoMax app and redeem your referral code',
                        ),
                        _buildStepCard(
                          number: '✓',
                          title: 'Both you and referral get',
                          isLast: true,
                          child: const Text(
                            '100Coins',
                            style: TextStyle(
                              color: Color(0xFFD7905F),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatsCard(
                          'Invited Referrals',
                          '0',
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildStatsCard(
                          'Coins Earned',
                          '0/600',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Enter the code here and then both you and your friend will get 100Coins.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _codeController,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    letterSpacing: 1,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 20),
                                    hintText: 'Enter the referral code',
                                    hintStyle: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                  textCapitalization:
                                      TextCapitalization.characters,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: TextButton(
                                  onPressed: _isLoading ? null : _redeemCode,
                                  style: TextButton.styleFrom(
                                    backgroundColor: const Color(0xFFD7905F),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : const Text(
                                          'Redeem',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.grey,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Noted that you should redeem the referral code within 3 days of using the app!',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required String number,
    required String title,
    Widget? child,
    bool isLast = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF2A2A2A),
                width: 2,
              ),
              color: number == '✓'
                  ? const Color(0xFFD7905F).withOpacity(0.2)
                  : null,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: number == '✓' ? const Color(0xFFD7905F) : Colors.white,
                  fontSize: 16,
                  fontWeight:
                      number == '✓' ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                if (child != null) ...[
                  const SizedBox(height: 10),
                  child,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCodeCard(BuildContext context) {
    const referralCode = 'GDZTGRCQ'; // TODO: 从用户服务获取实际的推荐码

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF3A3A3A),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            referralCode,
            style: const TextStyle(
              color: Color(0xFFD7905F),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: referralCode));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Referral code copied!',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFF2A2A2A),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  duration: const Duration(seconds: 2),
                  margin: const EdgeInsets.all(16),
                ),
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              minimumSize: const Size(80, 36),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text(
              'Copy',
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.withOpacity(0.2),
            Colors.blue.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
