import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:ai_video/constants/theme.dart';
import 'package:provider/provider.dart';
import 'package:ai_video/providers/theme_provider.dart';
import 'package:ai_video/service/auth_service.dart';
import 'package:ai_video/service/locale_service.dart';
import 'package:ai_video/service/user_service.dart';
import 'package:ai_video/widgets/coin_display.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  void initState() {
    super.initState();
    _updateCredits();
  }

  void _updateCredits() {
    final userService = Provider.of<UserService>(context, listen: false);
    userService.loadCredits();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localeService = context.watch<LocaleService>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 0),
            child: Consumer<UserService>(
              builder: (context, userService, child) {
                return CoinDisplay(coins: userService.credits);
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pro 升级卡片
            GestureDetector(
              onTap: () => context.push('/subscribe'),
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFD7905F),
                      Color(0xFFC060C3),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD7905F).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [
                        Colors.purple.withOpacity(0.2),
                        Colors.transparent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Image.asset('assets/images/diamond.png', width: 40),
                      const SizedBox(width: 12),
                      Consumer<UserService>(
                        builder: (context, userService, child) {
                          return Text(
                            userService.isSubscribed
                                ? 'MagaVideo Pro Member'
                                : 'Get MagaVideo Pro',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 推荐好友部分
            _buildSection('Refer friends'),
            _buildSectionContainer([
              _buildMenuItem(
                icon: Icons.card_giftcard,
                title: 'Get Coins for Free',
                onTap: () {},
              ),
            ]),

            // 权限部分
            _buildSection('Permissions'),
            _buildSectionContainer([
              _buildMenuItem(
                icon: Icons.photo_library,
                title: 'Photo Permissions',
                onTap: () {},
              ),
              _buildMenuItem(
                icon: Icons.notifications,
                title: 'Notification Permissions',
                onTap: () {},
              ),
            ]),

            // 帮助部分
            _buildSection('Help'),
            _buildSectionContainer([
              _buildMenuItem(
                icon: Icons.monetization_on,
                title: 'Coins Details',
                onTap: () {},
              ),
              _buildMenuItem(
                icon: Icons.restore,
                title: 'Restore Purchase',
                onTap: () {},
              ),
              _buildMenuItem(
                icon: Icons.star_border,
                title: 'Rate Us',
                onTap: () {},
              ),
              _buildMenuItem(
                icon: Icons.share,
                title: 'Share VideoMax',
                onTap: () {},
              ),
              _buildMenuItem(
                icon: Icons.logout,
                title: 'Logout',
                onTap: () {
                  AuthService().logout();
                  context.go('/login');
                },
              ),
            ]),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSectionContainer(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
