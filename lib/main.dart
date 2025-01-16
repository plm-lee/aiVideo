import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: const CupertinoThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: CupertinoColors.black,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child:
              const Icon(CupertinoIcons.settings, color: CupertinoColors.white),
          onPressed: () {
            // TODO: 处理设置按钮点击
          },
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(CupertinoIcons.money_dollar_circle_fill,
                  color: CupertinoColors.systemYellow, size: 20),
              SizedBox(width: 4),
              Text('150 Coins',
                  style: TextStyle(
                    color: Color(0xFFFF69B4),
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                _buildFeatureCard(
                  icon: CupertinoIcons.photo,
                  title: 'Img → Video',
                  onTap: () {},
                ),
                const SizedBox(width: 16),
                _buildFeatureCard(
                  icon: CupertinoIcons.textformat,
                  title: 'Text → Video',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildCategoryHeader('AI Kiss', icon: '💗'),
            const SizedBox(height: 12),
            _buildCategoryList([
              CategoryItem('Kiss my Crush', 'assets/images/kiss1.jpg'),
              CategoryItem('Kiss Manga', 'assets/images/kiss2.jpg'),
              CategoryItem('Kiss my Kitty', 'assets/images/kiss3.jpg'),
            ]),
            const SizedBox(height: 24),
            _buildCategoryHeader('AI Hug', icon: '🫂'),
            const SizedBox(height: 12),
            _buildCategoryList([
              CategoryItem('Hug the Late', 'assets/images/hug1.jpg'),
              CategoryItem('Hug my Pet', 'assets/images/hug2.jpg'),
              CategoryItem('Hug Anything', 'assets/images/hug3.jpg'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFFF69B4)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: const Color(0xFFFF69B4)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        CupertinoIcons.chevron_right,
                        color: CupertinoColors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(String title, {required String icon}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(icon, style: const TextStyle(fontSize: 20)),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: CupertinoColors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        CupertinoButton(
          padding: EdgeInsets.zero,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'All',
              style: TextStyle(color: CupertinoColors.white),
            ),
          ),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildCategoryList(List<CategoryItem> items) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return _buildCategoryCard(items[index]);
        },
      ),
    );
  }

  Widget _buildCategoryCard(CategoryItem item) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: AssetImage(item.image),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        alignment: Alignment.bottomLeft,
        child: Text(
          item.title,
          style: const TextStyle(
            color: CupertinoColors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class CategoryItem {
  final String title;
  final String image;

  CategoryItem(this.title, this.image);
}
