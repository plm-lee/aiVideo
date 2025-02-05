import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:bigchallenger/constants/theme.dart';
import 'package:provider/provider.dart';
import 'package:bigchallenger/providers/theme_provider.dart';
import 'package:bigchallenger/service/auth_service.dart';
import 'package:bigchallenger/service/locale_service.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  Widget _buildSection(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localeService = context.watch<LocaleService>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        localeService.translate(title.toLowerCase()),
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
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localeService = context.watch<LocaleService>();

    return ListTile(
      title: Text(
        localeService.translate(title.toLowerCase()),
        style: AppTheme.getTitleStyle(isDark),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _showThemeOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final localeService = Provider.of<LocaleService>(context, listen: false);

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
          ListTile(
            title: Text(localeService.translate('system_default'),
                style: AppTheme.getTitleStyle(isDark)),
            trailing: themeProvider.themeMode == ThemeMode.system
                ? Icon(Icons.check, color: AppTheme.primaryColor)
                : null,
            onTap: () {
              themeProvider.setThemeMode(ThemeMode.system);
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text(localeService.translate('light'),
                style: AppTheme.getTitleStyle(isDark)),
            trailing: themeProvider.themeMode == ThemeMode.light
                ? Icon(Icons.check, color: AppTheme.primaryColor)
                : null,
            onTap: () {
              themeProvider.setThemeMode(ThemeMode.light);
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text(localeService.translate('dark'),
                style: AppTheme.getTitleStyle(isDark)),
            trailing: themeProvider.themeMode == ThemeMode.dark
                ? Icon(Icons.check, color: AppTheme.primaryColor)
                : null,
            onTap: () {
              themeProvider.setThemeMode(ThemeMode.dark);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showLanguageOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localeService = Provider.of<LocaleService>(context, listen: false);

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
          ListTile(
            title: Text('中文', style: AppTheme.getTitleStyle(isDark)),
            trailing: localeService.locale.languageCode == 'zh'
                ? Icon(Icons.check, color: AppTheme.primaryColor)
                : null,
            onTap: () {
              localeService.setLocale(const Locale('zh', 'CN'));
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('English', style: AppTheme.getTitleStyle(isDark)),
            trailing: localeService.locale.languageCode == 'en'
                ? Icon(Icons.check, color: AppTheme.primaryColor)
                : null,
            onTap: () {
              localeService.setLocale(const Locale('en', 'US'));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localeService = Provider.of<LocaleService>(context, listen: false);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
        title: Text(
          localeService.translate('confirm_logout'),
          style: AppTheme.getTitleStyle(isDark),
        ),
        content: Text(
          localeService.translate('logout_message'),
          style: AppTheme.getSubtitleStyle(isDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              localeService.translate('cancel'),
              style: TextStyle(color: AppTheme.darkSecondaryTextColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              localeService.translate('confirm'),
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await AuthService().logout();
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localeService = context.watch<LocaleService>();
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
          localeService.translate('settings'),
          style: AppTheme.getTitleStyle(isDark),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(context, 'account_info'),
            _buildMenuItem(
              context: context,
              title: 'phone',
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
                              localeService.translate('invite_now'),
                              style: AppTheme.getTitleStyle(isDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          localeService.translate('invite_description'),
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
                    child: Text(
                      localeService.translate('invite'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            _buildSection(context, 'custom'),
            _buildMenuItem(
              context: context,
              title: 'theme',
              onTap: () => _showThemeOptions(context),
            ),
            _buildMenuItem(
              context: context,
              title: 'language',
              onTap: () => _showLanguageOptions(context),
            ),
            _buildSection(context, 'system'),
            _buildMenuItem(
              context: context,
              title: 'clear_cache',
              trailing: const Icon(
                Icons.refresh,
                color: Colors.grey,
                size: 20,
              ),
              onTap: () {},
            ),
            _buildMenuItem(
              context: context,
              title: 'user_terms',
              onTap: () {},
            ),
            _buildMenuItem(
              context: context,
              title: 'privacy_policy',
              onTap: () {},
            ),
            _buildMenuItem(
              context: context,
              title: 'about',
              onTap: () {},
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handleLogout(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E1E1E),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    localeService.translate('logout'),
                    style: const TextStyle(
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
