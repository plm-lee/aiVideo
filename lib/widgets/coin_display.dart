import 'package:flutter/material.dart';

class CoinDisplay extends StatelessWidget {
  final int coins;
  final double iconSize;
  final double fontSize;
  final bool showCoinsText;

  // 金币渐变色
  static const List<Color> _coinGradient = [
    Color(0xFFD7905F),
    Color(0xFFC060C3),
  ];

  const CoinDisplay({
    super.key,
    required this.coins,
    this.iconSize = 16,
    this.fontSize = 14,
    this.showCoinsText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.monetization_on,
          color: Colors.amber,
          size: iconSize,
        ),
        const SizedBox(width: 4),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: _coinGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            showCoinsText ? '$coins Coins' : coins.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
