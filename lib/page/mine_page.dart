import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ai_video/service/user_service.dart';
import 'package:provider/provider.dart';
import 'package:ai_video/widgets/bottom_nav_bar.dart';
import 'package:ai_video/service/video_service.dart';
import 'package:ai_video/service/database_service.dart';
import 'package:ai_video/models/video_task.dart';
import 'dart:convert';
import 'package:ai_video/page/task_detail_page.dart';
import 'package:ai_video/widgets/coin_display.dart';
import 'package:ai_video/service/image_cache_service.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:video_player/video_player.dart';

class MinePage extends StatefulWidget {
  const MinePage({super.key});

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  final _videoService = VideoService();
  final _databaseService = DatabaseService();
  final _imageCacheService = ImageCacheService();
  bool _isLoading = true;
  List<VideoTask> _tasks = [];
  Timer? _progressTimer;
  String business_id = '';
  Map<String, VideoPlayerController> _videoControllers = {};

  @override
  void initState() {
    super.initState();
    _loadLocalTasks();

    // 每10秒查询一次任务进度
    _progressTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _queryTaskProgress();
    });
  }

  @override
  void dispose() {
    // 取消定时器
    if (_progressTimer != null) {
      _progressTimer?.cancel();
    }
    // 释放所有视频控制器
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    super.dispose();
  }

  Future<void> _loadLocalTasks() async {
    try {
      final tasks = await _databaseService.getVideoTasks();
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoading = false;
          business_id = tasks.first.businessId;
        });
      }
    } catch (e) {
      debugPrint('加载本地任务失败: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 查询任务进度
  Future<void> _queryTaskProgress() async {
    final videoService = VideoService();
    // 如果business_id为空，则获取当前任务
    if (business_id.isEmpty) {
      // 最新一条任务ID
      final task = await videoService.getLatestTask();
      if (task != null) {
        business_id = task.businessId;
        debugPrint('on progress task: $business_id');
      }
    }

    final state = await videoService.getTaskDetail(business_id);
    if (state == 1) {
      // mounted 表示当前 State 对象是否在 widget 树中
      // 在调用 setState 之前检查 mounted 可以避免在 widget 被销毁后更新状态导致的错误
      if (mounted) {
        debugPrint('on progress task finished: $business_id');

        await videoService.getUserTasks();
        await _loadLocalTasks();

        // 取消定时器
        if (_progressTimer != null) {
          _progressTimer?.cancel();
        }
      }
    }
  }

  Future<void> _onRefresh() async {
    try {
      final (success, message) = await _videoService.getUserTasks();
      if (!success) {
        debugPrint('任务刷新失败: $message');
        return;
      }

      if (mounted) {
        await _loadLocalTasks();
      }
    } catch (e) {
      debugPrint('任务刷新失败: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Widget _buildContent() {
    if (_tasks.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.folder_outlined,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Results',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildButton(
                'Explore more AI effects',
                onTap: () => context.go('/home'),
              ),
              const SizedBox(height: 16),
              _buildButton(
                'Restore',
                onTap: _handleRestore,
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _tasks.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.05),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFD7905F), Color(0xFFC060C3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.refresh_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Pull down to refresh tasks',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              final task = _tasks[index - 1];
              return _buildTaskCard(task);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _initializeVideoController(VideoTask task) async {
    if (task.state != 1 || task.videoUrl == null) return;

    if (_videoControllers.containsKey(task.businessId)) return;

    try {
      // 先检查本地缓存
      String? cachedVideoPath =
          await _imageCacheService.getCachedImagePath(task.videoUrl!);

      VideoPlayerController controller;
      if (cachedVideoPath != null) {
        // 使用本地缓存的视频
        controller = VideoPlayerController.file(File(cachedVideoPath));
      } else {
        // 下载并缓存视频
        cachedVideoPath =
            await _imageCacheService.downloadAndCacheImage(task.videoUrl!);
        if (cachedVideoPath != null) {
          controller = VideoPlayerController.file(File(cachedVideoPath));
        } else {
          // 如果缓存失败，使用网络视频
          controller = VideoPlayerController.networkUrl(
            Uri.parse(task.videoUrl!),
            videoPlayerOptions: VideoPlayerOptions(
              mixWithOthers: true,
              allowBackgroundPlayback: false,
            ),
          );
        }
      }

      // 添加错误监听
      controller.addListener(() {
        if (controller.value.hasError) {
          debugPrint('视频播放错误: ${controller.value.errorDescription}');
          // 如果视频播放出错，释放控制器
          controller.dispose();
          _videoControllers.remove(task.businessId);
        }
      });

      await controller.initialize().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('视频初始化超时: ${task.videoUrl}');
          throw TimeoutException('视频初始化超时');
        },
      );

      if (mounted) {
        controller.setLooping(true);
        controller.setVolume(0.0);
        controller.play();
        setState(() {
          _videoControllers[task.businessId] = controller;
        });
      }
    } catch (e) {
      debugPrint('视频初始化失败: $e');
      // 如果初始化失败，尝试使用备用视频格式
      try {
        final controller = VideoPlayerController.networkUrl(
          Uri.parse(task.videoUrl!),
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: true,
            allowBackgroundPlayback: false,
          ),
        );

        await controller.initialize().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('备用视频初始化超时: ${task.videoUrl}');
            throw TimeoutException('备用视频初始化超时');
          },
        );

        if (mounted) {
          controller.setLooping(true);
          controller.setVolume(0.0);
          controller.play();
          setState(() {
            _videoControllers[task.businessId] = controller;
          });
        }
      } catch (e) {
        debugPrint('备用视频初始化也失败: $e');
      }
    }
  }

  Widget _buildMediaContent(VideoTask task) {
    final bool isImageTask =
        task.originImg != null && task.originImg!.isNotEmpty;
    final bool isCompleted = task.state == 1;
    final bool hasVideo = task.videoUrl != null;

    if (!isImageTask) {
      return Container(
        width: 100,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E1E1E), Color(0xFF2A2A2A)],
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.text_fields,
            color: Colors.white38,
            size: 32,
          ),
        ),
      );
    }

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

    if (isCompleted && hasVideo) {
      final controller = _videoControllers[task.businessId];
      if (controller?.value.isInitialized ?? false) {
        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller!.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        );
      } else {
        // 视频未加载完成，显示图片
        _initializeVideoController(task);
        return FutureBuilder<String?>(
          future: _loadImage(task.originImg!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return placeholder;
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return _buildErrorWidget();
            }

            return Image.file(
              File(snapshot.data!),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
            );
          },
        );
      }
    }

    // 显示图片
    return FutureBuilder<String?>(
      future: _loadImage(task.originImg!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return placeholder;
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildErrorWidget();
        }

        return Image.file(
          File(snapshot.data!),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        );
      },
    );
  }

  Future<String?> _loadImage(String imagePath) async {
    // 1. 先检查本地缓存
    String? cachedPath = await _imageCacheService.getCachedImagePath(imagePath);

    // 2. 如果本地没有缓存，则下载并缓存
    if (cachedPath == null) {
      cachedPath = await _imageCacheService.downloadAndCacheImage(imagePath);
    }

    return cachedPath;
  }

  Widget _buildTaskCard(VideoTask task) {
    final bool isImageTask =
        task.originImg != null && task.originImg!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskDetailPage(task: task),
              ),
            );
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isImageTask)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: Container(
                    width: 100,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                    child: _buildMediaContent(task),
                  ),
                )
              else
                Container(
                  width: 100,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1E1E1E), Color(0xFF2A2A2A)],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.text_fields,
                      color: Colors.white38,
                      size: 32,
                    ),
                  ),
                ),
              Expanded(
                child: Container(
                  height: 140,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 类型标签和状态
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isImageTask ? Icons.image : Icons.text_fields,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isImageTask
                                      ? 'Image to Video'
                                      : 'Text to Video',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  _getStatusColor(task.state).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getStatusColor(task.state)
                                    .withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _getStatusText(task.state),
                              style: TextStyle(
                                color: _getStatusColor(task.state),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Prompt文本
                      Expanded(
                        child: Text(
                          task.prompt,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 时间
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            task.createdAt.toString().split('.')[0],
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleRestore() async {
    setState(() => _isLoading = true);
    try {
      final (success, message) = await _videoService.getUserTasks();
      if (!success) {
        debugPrint('获取任务失败: $message');
      }
      await _loadLocalTasks();
    } catch (e) {
      debugPrint('加载任务出错: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Mine',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 1),
            child: Consumer<UserService>(
              builder: (context, userService, child) {
                return CoinDisplay(coins: userService.credits);
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _buildContent(),
      bottomNavigationBar: const BottomNavBar(currentPath: '/mine'),
    );
  }

  Widget _buildButton(String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  String _getStatusText(int state) {
    switch (state) {
      case 0:
        return 'Processing';
      case 1:
        return 'Completed';
      case -1:
        return 'Failed';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor(int state) {
    switch (state) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.green;
      case -1:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Icon(
          Icons.error_outline,
          color: Colors.white38,
          size: 24,
        ),
      ),
    );
  }
}
