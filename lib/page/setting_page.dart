import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:bigchanllger/constants/theme.dart';
import 'package:provider/provider.dart';
import 'package:bigchanllger/providers/theme_provider.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  Widget _buildSection(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: isDark
              ? AppTheme.darkSecondaryTextColor
              : AppTheme.lightSecondaryTextColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      title: Text(
        title,
        style: AppTheme.getTitleStyle(isDark),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: AppTheme.getSubtitleStyle(isDark),
            )
          : null,
      trailing: trailing ??
          Icon(
            CupertinoIcons.chevron_right,
            color: isDark
                ? AppTheme.darkSecondaryTextColor
                : AppTheme.lightSecondaryTextColor,
            size: 20,
          ),
      onTap: onTap,
    );
  }

  void _showThemeOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor:
          isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.borderRadius)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildThemeOption(
            context: context,
            title: '跟随系统',
            isSelected: themeProvider.themeMode == ThemeMode.system,
            onTap: () {
              themeProvider.setThemeMode(ThemeMode.system);
              Navigator.pop(context);
            },
          ),
          _buildThemeOption(
            context: context,
            title: '浅色',
            isSelected: themeProvider.themeMode == ThemeMode.light,
            onTap: () {
              themeProvider.setThemeMode(ThemeMode.light);
              Navigator.pop(context);
            },
          ),
          _buildThemeOption(
            context: context,
            title: '深色',
            isSelected: themeProvider.themeMode == ThemeMode.dark,
            onTap: () {
              themeProvider.setThemeMode(ThemeMode.dark);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      title: Text(title, style: AppTheme.getTitleStyle(isDark)),
      trailing: isSelected
          ? Icon(
              Icons.check,
              color: AppTheme.primaryColor,
            )
          : null,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.darkBackgroundColor : AppTheme.lightBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppTheme.darkBackgroundColor
            : AppTheme.lightBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Setting',
          style: AppTheme.getTitleStyle(isDark),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(context, 'Account Info'),
            _buildMenuItem(
              context: context,
              title: '187****5160',
              subtitle: 'Account Settings',
              onTap: () {},
            ),
            _buildMenuItem(
              context: context,
              title: 'Free Quota',
              onTap: () {},
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              'assets/images/kiss1.jpg',
                              width: 24,
                              height: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Invite Now',
                              style: AppTheme.getTitleStyle(isDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You and your friends can get 50 credits each',
                          style: AppTheme.getSubtitleStyle(isDark),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Invite',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            _buildSection(context, 'Custom'),
            _buildMenuItem(
              context: context,
              title: 'Theme',
              onTap: () => _showThemeOptions(context),
            ),
            _buildMenuItem(
              context: context,
              title: 'Language',
              onTap: () {},
            ),
            _buildSection(context, 'System'),
            _buildMenuItem(
              context: context,
              title: 'Clear Cache',
              trailing: const Icon(
                Icons.refresh,
                color: Colors.grey,
                size: 20,
              ),
              onTap: () {},
            ),
            _buildMenuItem(
              context: context,
              title: 'User Terms',
              onTap: () {},
            ),
            _buildMenuItem(
              context: context,
              title: 'Privacy Policy',
              onTap: () {},
            ),
            _buildMenuItem(
              context: context,
              title: 'About',
              onTap: () {},
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.go('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E1E1E),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Log Out',
                    style: TextStyle(
                      color: Color(0xFFFF69B4),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
