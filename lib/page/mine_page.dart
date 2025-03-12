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
  bool _showRefreshHint = true;
  List<VideoTask> _tasks = [];
  late Future<List<VideoTask>> _videoTasksFuture;

  @override
  void initState() {
    super.initState();
    _videoTasksFuture = _databaseService.getVideoTasks();
    _loadLocalTasks();
  }

  Future<void> _loadLocalTasks() async {
    try {
      final tasks = await _databaseService.getVideoTasks();
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('加载本地任务失败: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onRefresh() async {
    try {
      final (success, message) = await _videoService.getUserTasks();
      if (!success) {
        debugPrint('获取远程任务失败: $message');
        return;
      }

      if (mounted) {
        setState(() {
          _showRefreshHint = false;
        });
        await _loadLocalTasks();
      }
    } catch (e) {
      debugPrint('获取远程任务出错: $e');
    }
  }

  Widget _buildContent() {
    if (_tasks.isEmpty) {
      return Center(
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
            const SizedBox(height: 8),
            const Text(
              'Pull down to refresh tasks',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
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
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
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
    );
  }

  Widget _buildMediaContent(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return _buildErrorWidget();
    }

    return FutureBuilder<String?>(
      future: _loadImage(imagePath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFFD7905F).withOpacity(0.8),
                ),
                strokeWidth: 2,
              ),
            ),
          );
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
                    child: _buildMediaContent(task.originImg),
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
            child: GestureDetector(
              onTap: () {
                final userService = context.read<UserService>();
                if (userService.isSubscribed) {
                  context.push('/buy-coins');
                } else {
                  context.push('/subscribe');
                }
              },
              child: Consumer<UserService>(
                builder: (context, userService, child) {
                  return CoinDisplay(coins: userService.credits);
                },
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              onRefresh: _onRefresh,
              child: _buildContent(),
            ),
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
