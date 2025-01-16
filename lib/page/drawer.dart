import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:bigchanllger/constants/theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor, size: 20),
      title: Text(title, style: AppTheme.getTitleStyle(isDark)),
      onTap: onTap,
    );
  }

  Widget _buildCreditsSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Credits',
                style: TextStyle(
                  color:
                      isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.smallBorderRadius),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/buy-credits');
                },
                child: Text(
                  'Buy',
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.darkTextColor
                        : AppTheme.lightTextColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.smallSpacing),
          Text(
            '¢ 0',
            style: TextStyle(
              color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Follow us',
            style: AppTheme.getSubtitleStyle(isDark),
          ),
          const SizedBox(height: AppTheme.spacing),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.discord),
                color:
                    isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.facebook),
                color:
                    isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Drawer(
      backgroundColor:
          isDark ? AppTheme.darkBackgroundColor : AppTheme.lightBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            _buildCreditsSection(context),
            Divider(color: AppTheme.darkSecondaryTextColor, height: 1),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMenuItem(
                    context: context,
                    icon: CupertinoIcons.time,
                    title: 'More Histories',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: CupertinoIcons.person_2,
                    title: 'Characters',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: CupertinoIcons.pencil,
                    title: 'My Creations',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: CupertinoIcons.sparkles,
                    title: 'Discover',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: CupertinoIcons.paintbrush,
                    title: 'Creative',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: CupertinoIcons.settings,
                    title: 'Setting',
                    onTap: () {
                      Navigator.pop(context); // 先关闭抽屉
                      context.push('/settings'); // 跳转到设置页面
                    },
                  ),
                ],
              ),
            ),
            Divider(color: AppTheme.darkSecondaryTextColor, height: 1),
            _buildSocialSection(context),
          ],
        ),
      ),
    );
  }
}
