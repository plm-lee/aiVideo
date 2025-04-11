import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ai_video/models/video_sample.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

class VideoSamplesPage extends StatefulWidget {
  final String title;
  final List<VideoSampleItem> items;
  final Map<String, VideoPlayerController>? preloadedControllers;

  const VideoSamplesPage({
    super.key,
    required this.title,
    required this.items,
    this.preloadedControllers,
  });

  @override
  State<VideoSamplesPage> createState() => _VideoSamplesPageState();
}

class _VideoSamplesPageState extends State<VideoSamplesPage> {
  final Map<String, VideoPlayerController> _videoControllers = {};
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    if (widget.preloadedControllers != null) {
      _videoControllers.addAll(widget.preloadedControllers!);
    }
    _initializeVideoControllers();
  }

  @override
  void dispose() {
    // 只处理在本页面创建的控制器
    for (var entry in _videoControllers.entries) {
      if (widget.preloadedControllers?.containsKey(entry.key) != true) {
        entry.value.dispose();
      }
    }
    _videoControllers.clear();
    super.dispose();
  }

  Future<void> _initializeVideoControllers() async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      for (var item in widget.items) {
        final String? videoUrl = item.videoUrl;
        if (videoUrl == null || videoUrl.isEmpty) continue;

        if (!_videoControllers.containsKey(videoUrl)) {
          try {
            final controller = VideoPlayerController.networkUrl(
              Uri.parse(videoUrl),
              videoPlayerOptions: VideoPlayerOptions(
                mixWithOthers: true,
                allowBackgroundPlayback: false,
              ),
            );

            _videoControllers[videoUrl] = controller;

            // 添加错误监听器
            controller.addListener(() {
              if (controller.value.hasError) {
                if (_videoControllers[videoUrl] == controller) {
                  _videoControllers.remove(videoUrl);
                  controller.dispose();
                }
              }
            });

            try {
              await controller.initialize().timeout(
                const Duration(seconds: 5),
                onTimeout: () {
                  throw TimeoutException('视频初始化超时');
                },
              );

              if (!mounted) {
                controller.dispose();
                _videoControllers.remove(videoUrl);
                continue;
              }

              controller.setLooping(true);
              controller.setVolume(0.0);
              controller.play();

              if (mounted) {
                setState(() {});
              }
            } catch (e) {
              debugPrint('视频初始化失败: $videoUrl, 错误: $e');
              _videoControllers.remove(videoUrl);
              controller.dispose();
            }
          } catch (e) {
            debugPrint('创建视频控制器失败: $videoUrl, 错误: $e');
            continue;
          }
        } else {
          // 如果控制器已存在但没有播放，重新开始播放
          final controller = _videoControllers[videoUrl]!;
          if (controller.value.isInitialized && !controller.value.isPlaying) {
            controller.play();
          }
        }
      }
    } catch (e) {
      debugPrint('初始化视频控制器时出错: $e');
    } finally {
      _isInitializing = false;
    }
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
        // 确保视频在显示时播放
        if (!controller!.value.isPlaying) {
          controller.play();
        }

        return AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        );
      } else {
        // 如果视频控制器未初始化，尝试初始化
        if (!_isInitializing && !_videoControllers.containsKey(videoUrl)) {
          _initializeVideoControllers();
        }
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

  void _navigateToThemeDetail(VideoSampleItem item) {
    debugPrint('navigate to theme detail: ${item.title}, id: ${item.id}');
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          final item = widget.items[index];
          return GestureDetector(
            onTap: () => _navigateToThemeDetail(item),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFF1E1E1E),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildMediaContent(item),
                  if (item.title.isNotEmpty)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: const TextStyle(
                                  color: Color(0xFF1E1E1E),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right,
                              color: Color(0xFF1E1E1E),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
