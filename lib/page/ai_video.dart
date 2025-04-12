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
import 'package:ai_video/widgets/coin_display.dart';
import 'package:ai_video/page/video_samples_page.dart';
import 'package:flutter/rendering.dart';

class AIVideo extends StatefulWidget {
  const AIVideo({super.key});

  @override
  State<AIVideo> createState() => _AIVideoState();
}

class _AIVideoState extends State<AIVideo>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  // 布局常量
  static const double _cardHeight = 100.0; // 顶部两个按钮的高度

  // 样例卡片
  static const double _spacing = 16.0; // 卡片间距
  static const double _borderRadius = 16.0; // 卡片圆角
  static const double _cardWidth = 130.0; // 卡片宽度
  static const double _categoryHeight = 190.0; // 样例列表高度

  // 字体大小

  static const double _subtitleFontSize = 14.0; // 卡片中字体大小
  static const double _iconFontSize = 16.0; // 图标中字体大小
  static const double _smallIconSize = 16.0; // 小图标大小

  // 内边距
  static const EdgeInsets _buttonPadding =
      EdgeInsets.symmetric(horizontal: 10, vertical: 4);
  static const EdgeInsets _contentPadding = EdgeInsets.all(_spacing);

  // 图标尺寸
  static const double _titleFontSize = 18.0; // 样例标题字体大小
  static const double _categoryIconSize = 30.0; // 样例图标尺寸
  static const double _categoryIconRadius = 8.0; // 样例图标圆角

  final VideoService _videoService = VideoService();
  final VideoCache _videoCache = VideoCache();

  List<VideoSample> _categories = [];

  // 添加视频控制器管理
  final Map<String, VideoPlayerController> _videoControllers = {};
  bool _isInitializing = false;
  final int _maxConcurrentLoads = 3; // 最大并发加载数
  final int _preloadCount = 4; // 预加载数量
  Timer? _cleanupTimer;
  final Set<String> _loadingVideos = {};
  final Map<String, int> _retryCount = {}; // 记录重试次数
  final int _maxRetries = 3; // 最大重试次数
  final Duration _retryDelay = const Duration(seconds: 2); // 重试延迟
  bool _isDisposed = false;

  // 添加渐变色列表
  final List<List<Color>> _gradients = [
    [const Color(0xFFD7905F), const Color(0xFFC060C3)], // 橙色到紫色
    [const Color(0xFF4FACFE), const Color(0xFF00F2FE)], // 蓝色渐变
    [const Color(0xFFFF5E50), const Color(0xFFFF4E50)], // 红色渐变
    [const Color(0xFF13E2DA), const Color(0xFF00B4D8)], // 青色渐变
  ];

  // 添加缓存
  final Map<String, ImageProvider> _imageCache = {};
  final Map<String, bool> _videoErrorCache = {};

  // 添加防抖
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCategories();
    _initializeVideoControllers();
    _updateCredits();

    // 定期清理未使用的视频控制器
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted && !_isDisposed) {
        _cleanupUnusedControllers();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _cleanupTimer?.cancel();
    _debounceTimer?.cancel();
    _disposeAllControllers();
    _imageCache.clear();
    _videoErrorCache.clear();
    super.dispose();
  }

  void _disposeAllControllers() {
    for (var controller in _videoControllers.values) {
      try {
        controller.dispose();
      } catch (e) {
        debugPrint('Error disposing controller: $e');
      }
    }
    _videoControllers.clear();
    _loadingVideos.clear();
    _retryCount.clear();
  }

  void _cleanupUnusedControllers() {
    if (_isDisposed) return;

    final now = DateTime.now();
    _videoControllers.removeWhere((url, controller) {
      try {
        // 如果视频超过5分钟未使用，则释放资源
        if (now.difference(DateTime.now()).inMinutes > 5) {
          controller.dispose();
          return true;
        }
      } catch (e) {
        debugPrint('Error cleaning up controller: $e');
        return true;
      }
      return false;
    });
  }

  void _updateCredits() {
    final userService = Provider.of<UserService>(context, listen: false);
    userService.loadCredits();
    userService.loadIsSubscribe();
  }

  Future<void> _loadCategories() async {
    // 先尝试加载缓存数据
    final cachedCategories = await _videoCache.loadCachedCategories();
    if (cachedCategories.isNotEmpty) {
      setState(() {
        _categories = cachedCategories;
      });

      debugPrint('loadCategories: ${_categories[0].items[0].id}');
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
      // 获取当前可见的视频项
      final visibleItems = _getVisibleVideoItems();
      if (visibleItems.isEmpty) return;

      // 限制并发加载数量
      final itemsToLoad = visibleItems.take(_maxConcurrentLoads).toList();

      // 并发加载视频
      await Future.wait(
        itemsToLoad.map((item) => _loadVideoController(item.videoUrl!)),
      );

      // 预加载下一批视频
      _preloadNextVideos(visibleItems);
    } catch (e, stackTrace) {
      debugPrint('Error initializing video controllers: $e\n$stackTrace');
    } finally {
      _isInitializing = false;
    }
  }

  List<VideoSampleItem> _getVisibleVideoItems() {
    final List<VideoSampleItem> items = [];
    for (var category in _categories) {
      items.addAll(category.items.where((item) =>
          item.videoUrl != null &&
          item.videoUrl!.isNotEmpty &&
          !_videoControllers.containsKey(item.videoUrl)));
    }
    return items;
  }

  void _preloadNextVideos(List<VideoSampleItem> currentItems) {
    final nextItems = _getVisibleVideoItems()
        .where((item) => !currentItems.contains(item))
        .take(_preloadCount)
        .toList();

    for (var item in nextItems) {
      _loadVideoController(item.videoUrl!).catchError((e) {
        debugPrint('Error preloading video: $e');
      });
    }
  }

  // 优化视频加载
  Future<void> _loadVideoController(String videoUrl) async {
    if (_isDisposed || !mounted || _hasVideoError(videoUrl)) return;

    if (_videoControllers.containsKey(videoUrl) ||
        _loadingVideos.contains(videoUrl)) {
      return;
    }

    _loadingVideos.add(videoUrl);
    _retryCount[videoUrl] = (_retryCount[videoUrl] ?? 0) + 1;

    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );

      if (_isDisposed || !mounted) {
        controller.dispose();
        return;
      }

      _videoControllers[videoUrl] = controller;

      controller.addListener(() {
        if (controller?.value.hasError ?? false) {
          _handleVideoError(videoUrl, controller!);
        }
      });

      try {
        await controller.initialize().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('视频初始化超时');
          },
        );

        if (_isDisposed || !mounted) {
          _disposeController(videoUrl, controller);
          return;
        }

        controller.setLooping(true);
        controller.setVolume(0.0);
        controller.play();

        _safeSetState(() {});

        _retryCount.remove(videoUrl);
      } catch (e) {
        debugPrint('Error initializing video: $e');
        _disposeController(videoUrl, controller);
        _markVideoError(videoUrl);

        if (_retryCount[videoUrl]! <= _maxRetries) {
          await Future.delayed(_retryDelay);
          if (mounted && !_isDisposed) {
            _loadVideoController(videoUrl);
          }
        } else {
          debugPrint(
              'Video loading failed after $_maxRetries retries: $videoUrl');
          _retryCount.remove(videoUrl);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading video controller: $e\n$stackTrace');
      _disposeController(videoUrl, controller);
      _markVideoError(videoUrl);
    } finally {
      if (mounted && !_isDisposed) {
        _loadingVideos.remove(videoUrl);
      }
    }
  }

  // 优化媒体内容构建
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
    if (videoUrl.isNotEmpty && !_hasVideoError(videoUrl)) {
      final controller = _videoControllers[videoUrl];
      if (controller?.value.isInitialized ?? false) {
        if (!controller!.value.isPlaying) {
          controller.play();
        }

        return AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        );
      } else {
        if (!_isInitializing && !_videoControllers.containsKey(videoUrl)) {
          _debounceTimer?.cancel();
          _debounceTimer = Timer(_debounceDuration, () {
            if (mounted && !_isDisposed) {
              _loadVideoController(videoUrl);
            }
          });
        }
      }
    }

    // 如果视频未就绪或加载失败，显示图片
    if (imagePath.isNotEmpty) {
      return Image(
        image: _getImageProvider(imagePath),
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder;
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error loading image: $error');
          return placeholder;
        },
      );
    }

    return placeholder;
  }

  // 优化分类卡片构建
  Widget _buildCategoryCard(VideoSampleItem item) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () => _navigateToThemeDetail(item),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_borderRadius),
            color: AppTheme.darkCardColor,
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _subtitleFontSize,
                      fontWeight: FontWeight.bold,
                      shadows: const [
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
      ),
    );
  }

  void _handleVideoError(String videoUrl, VideoPlayerController controller) {
    _disposeController(videoUrl, controller);
  }

  void _disposeController(String videoUrl, VideoPlayerController? controller) {
    try {
      if (controller != null) {
        controller.dispose();
      }
      _videoControllers.remove(videoUrl);
      _loadingVideos.remove(videoUrl);
    } catch (e) {
      debugPrint('Error disposing controller: $e');
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
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[850] : Colors.grey[400],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child:
                            Icon(icon, color: AppTheme.primaryColor, size: 20),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
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

  Widget _buildAllButton(String category, List<VideoSampleItem> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.smallBorderRadius),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoSamplesPage(
                title: category,
                items: items,
                preloadedControllers: _videoControllers,
              ),
            ),
          );
        },
        child: Container(
          padding: _buttonPadding,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
            borderRadius: BorderRadius.circular(AppTheme.smallBorderRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'All',
                style: TextStyle(
                  fontSize: _subtitleFontSize,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark
                    ? AppTheme.darkSecondaryTextColor
                    : AppTheme.lightSecondaryTextColor,
                size: _smallIconSize,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(VideoSample category) {
    final gradient =
        _gradients[_categories.indexOf(category) % _gradients.length];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: _contentPadding,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(_categoryIconRadius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    width: _categoryIconSize,
                    height: _categoryIconSize,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(_categoryIconRadius),
                    ),
                    child: Center(
                      child: Text(
                        category.icon,
                        style: TextStyle(fontSize: _iconFontSize),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  category.title,
                  style: TextStyle(
                    fontSize: _titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              _buildAllButton(category.title, category.items),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: _spacing),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: _spacing,
            mainAxisSpacing: _spacing,
          ),
          itemCount: category.items.length,
          itemBuilder: (context, index) {
            final item = category.items[index];
            return _buildCategoryCard(item);
          },
        ),
        const SizedBox(height: _spacing),
      ],
    );
  }

  // 优化图片加载
  ImageProvider _getImageProvider(String imagePath) {
    return _imageCache.putIfAbsent(imagePath, () {
      if (imagePath.startsWith('http')) {
        return NetworkImage(imagePath);
      } else {
        return AssetImage(imagePath);
      }
    });
  }

  // 优化视频错误处理
  bool _hasVideoError(String videoUrl) {
    return _videoErrorCache[videoUrl] ?? false;
  }

  void _markVideoError(String videoUrl) {
    _videoErrorCache[videoUrl] = true;
  }

  // 优化状态更新
  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      setState(fn);
    }
  }

  void _navigateToThemeDetail(VideoSampleItem item) {
    context.push(
      '/theme-detail',
      extra: {
        'sampleId': item.id,
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
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () => context.push('/settings'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 1),
            child: Consumer<UserService>(
              builder: (context, userService, child) {
                return CoinDisplay(coins: userService.credits);
              },
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
            ..._categories
                .where((category) => category.items.isNotEmpty)
                .map(_buildCategorySection),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentPath: '/home'),
    );
  }
}
