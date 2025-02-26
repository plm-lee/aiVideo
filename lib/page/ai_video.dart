import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:ai_video/page/drawer.dart';
import 'package:ai_video/constants/theme.dart';
import 'package:ai_video/service/credits_service.dart';
import 'package:provider/provider.dart';
import 'package:ai_video/widgets/bottom_nav_bar.dart';
import 'theme_detail_page.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

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
        {
          'title': 'Kiss my Crush',
          'image': 'assets/images/kiss1.jpg',
          'video_url':
              'https://magaai.s3.us-west-1.amazonaws.com/2025/02/26/image_to_video/ChFBUme0a_IAAAAAAaPuuA-0_raw_video_2.mp4?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAQ4NSA4KUYKEC6U7L%2F20250226%2Fus-west-1%2Fs3%2Faws4_request&X-Amz-Date=20250226T063028Z&X-Amz-Expires=3600&X-Amz-SignedHeaders=host&X-Amz-Signature=4f370581f0dd0dfbf70deab35fc289ad7950c662bc7c37dbb07cd267437ccdd7',
        },
        {
          'title': 'Kiss Manga',
          'image': 'assets/images/kiss2.jpg',
          'video_url': 'assets/videos/kiss_manga.mp4',
        },
        {
          'title': 'Kiss Anime',
          'image': 'assets/images/kiss3.jpg',
          'video_url':
              'https://magaai.s3.us-west-1.amazonaws.com/2025/02/26/image_to_video/ChFBUme0a_IAAAAAAaaBqw-0_raw_video_2.mp4?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAQ4NSA4KUYKEC6U7L%2F20250226%2Fus-west-1%2Fs3%2Faws4_request&X-Amz-Date=20250226T083755Z&X-Amz-Expires=3600&X-Amz-SignedHeaders=host&X-Amz-Signature=64899a6707d89a235847f66dcd3320d05ba8b2664d8e51f4c3be348abcd7734e',
        },
      ]
    },
    {
      'title': 'AI Hug',
      'icon': '🫂',
      'items': [
        {
          'title': 'Hug my Crush',
          'image': 'assets/images/hug1.jpg',
          'video_url': 'assets/videos/kiss_manga.mp4'
        },
        {
          'title': 'Hug Manga',
          'image': 'assets/images/hug2.jpg',
          'video_url': 'assets/videos/kiss_manga.mp4'
        },
        {
          'title': 'Hug Anime',
          'image': 'assets/images/hug3.jpg',
          'video_url': 'assets/videos/kiss_manga.mp4'
        },
      ]
    },
  ];

  // 添加视频控制器管理
  final Map<String, VideoPlayerController> _videoControllers = {};
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoControllers();
  }

  Future<void> _initializeVideoControllers() async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      for (var category in _categories) {
        for (var item in category['items']) {
          final String? videoUrl = item['video_url'];
          if (videoUrl != null && !_videoControllers.containsKey(videoUrl)) {
            try {
              final controller = videoUrl.startsWith('http')
                  ? VideoPlayerController.networkUrl(
                      Uri.parse(videoUrl),
                      videoPlayerOptions: VideoPlayerOptions(
                        mixWithOthers: true,
                        allowBackgroundPlayback: false,
                      ),
                    )
                  : VideoPlayerController.asset(videoUrl);

              _videoControllers[videoUrl] = controller;

              await controller.initialize().timeout(
                const Duration(seconds: 5),
                onTimeout: () {
                  debugPrint('Video initialization timeout: $videoUrl');
                  throw TimeoutException('Video initialization timeout');
                },
              );

              if (mounted) {
                controller.setLooping(true);
                controller.setVolume(0.0);
                controller.play();
                setState(() {});
              }
            } catch (e) {
              debugPrint('Error initializing video: $videoUrl, error: $e');
              _videoControllers.remove(videoUrl);
              continue;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error initializing video controllers: $e');
    } finally {
      _isInitializing = false;
    }
  }

  @override
  void dispose() {
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    super.dispose();
  }

  void _handleVideoConversion(String type) {
    debugPrint('处理$type转视频');
    final uri = Uri.parse(type == 'text' ? '/text-to-video' : '/img-to-video');
    context.push(uri.toString());
  }

  Widget _buildConversionCard({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        height: _cardHeight,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
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
                      color: isDark ? Colors.grey[850] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Icon(icon, color: AppTheme.primaryColor, size: 20),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: AppTheme.getTitleStyle(isDark),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color:
                      isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.smallBorderRadius),
        onTap: () => debugPrint('查看全部 $category'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
            borderRadius: BorderRadius.circular(AppTheme.smallBorderRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'All',
                style: AppTheme.getTitleStyle(isDark),
              ),
              Icon(Icons.chevron_right,
                  color: isDark
                      ? AppTheme.darkSecondaryTextColor
                      : AppTheme.lightSecondaryTextColor,
                  size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaContent(Map<String, dynamic> item) {
    final String? videoUrl = item['video_url'];
    final String imagePath = item['image'];
    final bool isNetworkPath = videoUrl?.startsWith('http') ?? false;

    if (videoUrl != null) {
      final controller = _videoControllers[videoUrl];
      if (controller?.value.isInitialized ?? false) {
        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller!.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        );
      }
      return Image.asset(imagePath, fit: BoxFit.cover);
    }

    return isNetworkPath
        ? Image.network(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
          )
        : Image.asset(imagePath, fit: BoxFit.cover);
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.black,
      child: const Icon(Icons.error, color: Colors.white),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.push(
        '/theme-detail',
        extra: {
          'title': item['title'] ?? 'Kiss my Crush',
          'imagePath': item['image'],
          'videoUrl': item['video_url'],
          'preloadedController': item['video_url'] != null
              ? _videoControllers[item['video_url']]
              : null,
        },
      ),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: _spacing),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_borderRadius),
          color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            _buildMediaContent(item),
            if (item['title'].isNotEmpty)
              Positioned(
                left: 12,
                bottom: 12,
                child: Text(
                  item['title'],
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.darkTextColor
                        : AppTheme.lightTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.black,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: isDark
            ? AppTheme.darkBackgroundColor
            : AppTheme.lightBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.settings,
            color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
          ),
          onPressed: () => context.push('/settings'),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => context.push('/subscribe'),
              child: Consumer<CreditsService>(
                builder: (context, creditsService, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.monetization_on,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${creditsService.credits}',
                          style: TextStyle(
                            color: isDark
                                ? AppTheme.darkTextColor
                                : AppTheme.lightTextColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
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
      bottomNavigationBar: const BottomNavBar(currentPath: '/home'),
    );
  }
}
