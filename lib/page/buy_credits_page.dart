import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:bigchanllger/service/purchase_service.dart';

class BuyCreditsPage extends StatefulWidget {
  const BuyCreditsPage({super.key});

  @override
  State<BuyCreditsPage> createState() => _BuyCreditsPageState();
}

class _BuyCreditsPageState extends State<BuyCreditsPage> {
  int? _selectedIndex;
  static const List<int> _hotDealIndexes = [1, 2];
  final _purchaseService = PurchaseService();

  @override
  void initState() {
    super.initState();
    _purchaseService.initialize();
  }

  @override
  void dispose() {
    _purchaseService.dispose();
    super.dispose();
  }

  Widget _buildCreditCard({
    required String credits,
    required String price,
    required String expiration,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    final isHot = _hotDealIndexes.contains(index);

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.transparent,
            width: 2,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¢ $credits',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$expiration天有效期',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  '\$$price',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (isHot)
              Positioned(
                right: -2,
                top: -22,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'HOT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handlePurchase() async {
    if (_selectedIndex == null) return;

    final credits = ['600', '1200', '5000', '10000', '38000'][_selectedIndex!];

    try {
      final success = await _purchaseService.buyProduct(credits);
      if (!success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('购买失败，请稍后重试')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发生错误: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Buy Credits',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                _buildCreditCard(
                  credits: '600',
                  price: '0.99',
                  expiration: '30',
                  index: 0,
                ),
                _buildCreditCard(
                  credits: '1200',
                  price: '1.99',
                  expiration: '90',
                  index: 1,
                ),
                _buildCreditCard(
                  credits: '5000',
                  price: '4.99',
                  expiration: '90',
                  index: 2,
                ),
                _buildCreditCard(
                  credits: '10000',
                  price: '9.99',
                  expiration: '180',
                  index: 3,
                ),
                _buildCreditCard(
                  credits: '38000',
                  price: '29.99',
                  expiration: '365',
                  index: 4,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '购买说明：',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                _buildBulletPoint('您购买的金币需在有效期内使用，逾期未使用即失效；'),
                _buildBulletPoint('金币不支持退款、提现或转赠他人；'),
                _buildBulletPoint(
                    '支付如遇到问题，可发邮件至 BigChallenger1986@gmail.com，我们会为您解决。'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedIndex != null ? _handlePurchase : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _selectedIndex != null
                          ? 'Create Order \$4.99'
                          : 'Please select a plan',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
