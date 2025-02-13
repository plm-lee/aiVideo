import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:ai_video/constants/theme.dart';
import 'package:provider/provider.dart';
import 'package:ai_video/providers/theme_provider.dart';
import 'package:ai_video/service/auth_service.dart';
import 'package:ai_video/service/locale_service.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

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
        title: Text(
          'Settings',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Color(0xFFFFD700)),
                const SizedBox(width: 4),
                Text(
                  '0 Coins',
                  style: const TextStyle(color: Color(0xFFFF69B4)),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pro 升级卡片
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF2D0A31), // 深紫色
                    Color(0xFF3D1440), // 中紫色
                    Color(0xFF4A1C4D), // 浅紫色
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
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
                    const Text(
                      'Get VideoMax Pro',
                      style: TextStyle(
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
                    ),
                  ],
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
        style: const TextStyle(color: Colors.white),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
