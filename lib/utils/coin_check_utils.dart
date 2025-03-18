import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ai_video/service/user_service.dart';

class CoinCheckUtils {
  /// 检查用户金币余额是否足够
  ///
  /// [context] - BuildContext 用于显示对话框和导航
  /// [requiredCoins] - 所需的金币数量
  ///
  /// 返回 true 如果金币足够，false 如果金币不足
  static Future<bool> checkCoinsBalance(
    BuildContext context, {
    required int requiredCoins,
  }) async {
    final userService = Provider.of<UserService>(context, listen: false);
    final currentCoins = userService.credits;

    if (currentCoins < requiredCoins) {
      // 显示提示对话框
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Insufficient Coins',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'You need $requiredCoins coins to generate this video. Current balance: $currentCoins coins.',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
                context.push('/buy-coins');
              },
              child: const Text(
                'Get Coins',
                style: TextStyle(
                  color: Color(0xFFD7905F),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
      return result ?? false;
    }
    return true;
  }
}
