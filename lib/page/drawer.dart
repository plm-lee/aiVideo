import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildCreditsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Credits',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
                child: const Text('Buy'),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '¢ 0',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Follow us',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.discord),
                color: Colors.white,
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.facebook),
                color: Colors.white,
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
    return Drawer(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            _buildCreditsSection(),
            const Divider(color: Colors.grey, height: 1),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMenuItem(
                    icon: CupertinoIcons.time,
                    title: 'More Histories',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: CupertinoIcons.person_2,
                    title: 'Characters',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: CupertinoIcons.pencil,
                    title: 'My Creations',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: CupertinoIcons.sparkles,
                    title: 'Discover',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: CupertinoIcons.paintbrush,
                    title: 'Creative',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: CupertinoIcons.settings,
                    title: 'Setting',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.grey, height: 1),
            _buildSocialSection(),
          ],
        ),
      ),
    );
  }
}
