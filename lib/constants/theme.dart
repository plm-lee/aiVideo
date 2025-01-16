import 'package:flutter/material.dart';

class AppTheme {
  // 主题颜色
  static const Color primaryColor = Color(0xFFFF69B4);
  static const Color darkBackgroundColor = Colors.black;
  static const Color darkCardColor = Color(0xFF1E1E1E);
  static const Color darkTextColor = Colors.white;
  static const Color darkSecondaryTextColor = Colors.grey;

  static const Color lightBackgroundColor = Colors.white;
  static const Color lightCardColor = Color(0xFFF5F5F5);
  static const Color lightTextColor = Colors.black;
  static const Color lightSecondaryTextColor = Colors.black54;

  // 间距和圆角
  static const double spacing = 16.0;
  static const double smallSpacing = 8.0;
  static const double borderRadius = 12.0;
  static const double smallBorderRadius = 8.0;

  // 获取主题数据
  static ThemeData getDarkTheme() {
    return ThemeData.dark().copyWith(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBackgroundColor,
      cardColor: darkCardColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackgroundColor,
        elevation: 0,
      ),
    );
  }

  static ThemeData getLightTheme() {
    return ThemeData.light().copyWith(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: lightBackgroundColor,
      cardColor: lightCardColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackgroundColor,
        elevation: 0,
      ),
    );
  }

  // 获取文本样式
  static TextStyle getTitleStyle(bool isDark) {
    return TextStyle(
      color: isDark ? darkTextColor : lightTextColor,
      fontSize: 16,
    );
  }

  static TextStyle getSubtitleStyle(bool isDark) {
    return TextStyle(
      color: isDark ? darkSecondaryTextColor : lightSecondaryTextColor,
      fontSize: 14,
    );
  }

  // 获取卡片装饰
  static BoxDecoration getCardDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? darkCardColor : lightCardColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: primaryColor.withOpacity(0.3),
      ),
    );
  }
}
