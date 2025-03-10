import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ai_video/constants/theme.dart';
import 'package:ai_video/service/user_service.dart';
import 'package:provider/provider.dart';
import 'package:ai_video/widgets/bottom_nav_bar.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'dart:ui';
import 'package:ai_video/service/video_service.dart';
import 'package:ai_video/models/video_sample.dart';
import 'package:ai_video/service/video_cache.dart';
import 'package:flutter/rendering.dart';

class AIVideo extends StatefulWidget {
  const AIVideo({super.key});

  @override
  State<AIVideo> createState() => _AIVideoState();
}

class _AIVideoState extends State<AIVideo> with WidgetsBindingObserver {
  static const double _cardHeight = 130.0;
  static const double _spacing = 16.0;
  static const double _borderRadius = 16.0;

  final VideoService _videoService = VideoService();
  final VideoCache _videoCache = VideoCache();

  List<VideoSample> _categories = [];

  // 添加视频控制器管理
  final Map<String, VideoPlayerController> _videoControllers = {};
  bool _isInitializing = false;

  // 添加渐变色列表
  final List<List<Color>> _gradients = [
    [const Color(0xFFD7905F), const Color(0xFFC060C3)], // 橙色到紫色
    [const Color(0xFF4FACFE), const Color(0xFF00F2FE)], // 蓝色渐变
    [const Color(0xFFFF5E50), const Color(0xFFFF4E50)], // 红色渐变
    [const Color(0xFF13E2DA), const Color(0xFF00B4D8)], // 青色渐变
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCategories();
    _initializeVideoControllers();
    _updateCredits();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateCredits();
    }
  }

  void _updateCredits() {
    final userService = Provider.of<UserService>(context, listen: false);
    userService.loadCredits();
  }

  Future<void> _loadCategories() async {
    // 先尝试加载缓存数据
    final cachedCategories = await _videoCache.loadCachedCategories();
    if (cachedCategories.isNotEmpty) {
      setState(() {
        _categories = cachedCategories;
      });
    }

    // 检查是否需要更新缓存
    if (await _videoCache.shouldUpdateCache()) {
      await _getVideoSamples();
    }
  }

  Future<void> _getVideoSamples() async {
    try {
      final videoSamples = await _videoService.getVideoSamples();

      if (mounted) {
        setState(() {
          _categories = videoSamples;
        });
      }

      // 更新缓存
      await _videoCache.updateCache(videoSamples);
    } catch (e) {
      debugPrint('Error getting video samples: $e');
    }
  }

  Future<void> _initializeVideoControllers() async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      for (var category in _categories) {
        for (var item in category.items) {
          final String? videoUrl = item.videoUrl;
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

  Widget _buildCategorySection(VideoSample category) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient =
        _gradients[_categories.indexOf(category) % _gradients.length];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(_spacing),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        category.icon,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  category.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              _buildAllButton(category.title),
            ],
          ),
        ),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: _spacing),
            itemCount: category.items.length,
            itemBuilder: (context, index) {
              final item = category.items[index];
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

  Widget _buildMediaContent(VideoSampleItem item) {
    final String imagePath = item.image;
    final String videoUrl = item.videoUrl;
    final bool isNetworkPath = imagePath.startsWith('http');

    // 默认灰色背景
    Widget placeholder = Container(
      color: Colors.grey[900],
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD7905F)),
          strokeWidth: 2,
        ),
      ),
    );

    // 优先展示视频
    if (videoUrl.isNotEmpty) {
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
    }

    // 如果视频未就绪，显示图片
    if (imagePath.isNotEmpty) {
      if (isNetworkPath) {
        return Image.network(
          imagePath,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return placeholder;
          },
          errorBuilder: (context, error, stackTrace) => placeholder,
        );
      } else {
        return Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => placeholder,
        );
      }
    }

    return placeholder;
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.black,
      child: const Icon(Icons.error, color: Colors.white),
    );
  }

  Widget _buildCategoryCard(VideoSampleItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _navigateToThemeDetail(item),
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
            if (item.title.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                child: Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 3,
                        color: Colors.black,
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _navigateToThemeDetail(VideoSampleItem item) {
    context.push(
      '/theme-detail',
      extra: {
        'title': item.title,
        'prompt': item.prompt,
        'imagePath': item.image,
        'videoUrl': item.videoUrl,
        'preloadedController':
            item.videoUrl.isNotEmpty ? _videoControllers[item.videoUrl] : null,
        'imgNum': item.imgNum,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.black,
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
              onTap: () {
                final userService =
                    Provider.of<UserService>(context, listen: false);
                if (userService.isSubscribed) {
                  context.push('/buy-coins');
                } else {
                  context.push('/subscribe');
                }
              },
              child: Consumer<UserService>(
                builder: (context, userService, child) {
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
                          '${userService.credits}',
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
