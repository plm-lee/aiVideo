import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:bigchanllger/page/drawer.dart';

class AIVideo extends StatefulWidget {
  const AIVideo({super.key});

  @override
  State<AIVideo> createState() => _AIVideoState();
}

class _AIVideoState extends State<AIVideo> {
  static const double _cardHeight = 130.0;
  static const double _spacing = 16.0;
  static const double _borderRadius = 16.0;

  final List<Map<String, dynamic>> _categories = [
    {
      'title': 'AI Kiss',
      'icon': '💗',
      'items': [
        {'title': '', 'image': 'assets/images/kiss1.jpg'},
        {'title': '', 'image': 'assets/images/kiss2.jpg'},
        {'title': '', 'image': 'assets/images/kiss3.jpg'},
      ]
    },
    {
      'title': 'AI Hug',
      'icon': '🫂',
      'items': [
        {'title': '', 'image': 'assets/images/hug1.jpg'},
        {'title': '', 'image': 'assets/images/hug2.jpg'},
        {'title': '', 'image': 'assets/images/hug3.jpg'},
      ]
    },
  ];

  void _handleVideoConversion(String type) {
    debugPrint('处理$type转视频');
    final uri = Uri.parse(type == 'text'
        ? '/creative-draw/create?mode=text-to-image'
        : '/creative-draw/create-video');
    context.push(uri.toString());
  }

  Widget _buildConversionCard({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: Container(
        height: _cardHeight,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(_borderRadius),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFF69B4).withOpacity(0.3),
                      ),
                    ),
                    child: Icon(icon, color: const Color(0xFFFF69B4), size: 20),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(Map<String, dynamic> category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(_spacing),
          child: Row(
            children: [
              Text(
                category['icon'],
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Text(
                category['title'],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              _buildAllButton(category['title']),
            ],
          ),
        ),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: _spacing),
            itemCount: (category['items'] as List).length,
            itemBuilder: (context, index) {
              final item = category['items'][index];
              return _buildCategoryCard(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAllButton(String category) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => debugPrint('查看全部 $category'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'All',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> item) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: _spacing),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_borderRadius),
        color: const Color(0xFF1E1E1E),
        border: Border.all(
          color: const Color(0xFFFF69B4).withOpacity(0.3),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(item['image'], fit: BoxFit.cover),
          if (item['title'].isNotEmpty)
            Positioned(
              left: 12,
              bottom: 12,
              child: Text(
                item['title'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: const [
                Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                SizedBox(width: 4),
                Text(
                  '150 Coins',
                  style: TextStyle(
                    color: Color(0xFFFF69B4),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(_spacing),
              child: Row(
                children: [
                  _buildConversionCard(
                    icon: Icons.image,
                    title: 'Img → Video',
                    onTap: () => _handleVideoConversion('image'),
                  ),
                  const SizedBox(width: _spacing),
                  _buildConversionCard(
                    icon: Icons.text_fields,
                    title: 'Text → Video',
                    onTap: () => _handleVideoConversion('text'),
                  ),
                ],
              ),
            ),
            ..._categories.map(_buildCategorySection),
          ],
        ),
      ),
    );
  }
}
