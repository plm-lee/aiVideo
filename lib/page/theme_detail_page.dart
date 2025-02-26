import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:ai_video/service/video_service.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';

class ThemeDetailPage extends StatefulWidget {
  final String title;
  final String imagePath;
  final String? videoUrl;
  final VideoPlayerController? preloadedController;

  const ThemeDetailPage({
    super.key,
    required this.title,
    required this.imagePath,
    this.videoUrl,
    this.preloadedController,
  });

  @override
  State<ThemeDetailPage> createState() => _ThemeDetailPageState();
}

class _ThemeDetailPageState extends State<ThemeDetailPage> {
  VideoPlayerController? _videoController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    if (widget.videoUrl == null) return;
    debugPrint('初始化视频: ${widget.videoUrl}');

    setState(() => _isLoading = true);

    try {
      if (widget.preloadedController != null) {
        _videoController = widget.preloadedController;
        // 重置视频到开始位置并立即播放
        await _videoController!.seekTo(Duration.zero);
        _videoController!.setVolume(1.0);
        _videoController!.setLooping(true);
        _videoController!.play();
        setState(() => _isLoading = false);
        return;
      }

      _videoController = widget.videoUrl!.startsWith('http')
          ? VideoPlayerController.networkUrl(
              Uri.parse(widget.videoUrl!),
              videoPlayerOptions: VideoPlayerOptions(
                mixWithOthers: true,
                allowBackgroundPlayback: false,
              ),
            )
          : VideoPlayerController.asset(widget.videoUrl!);

      // 预加载视频
      await _videoController!.initialize();
      // 设置音量并开始播放
      _videoController!.setVolume(1.0);
      _videoController!.setLooping(true);
      _videoController!.play();

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error initializing video: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    if (widget.preloadedController == null) {
      _videoController?.dispose();
    } else {
      // 返回列表页面时恢复静音
      _videoController?.setVolume(0.0);
    }
    super.dispose();
  }

  Widget _buildMediaContent() {
    if (widget.videoUrl != null) {
      if (_isLoading) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }

      if (_videoController?.value.isInitialized ?? false) {
        return AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        );
      }

      // 视频加载失败时显示图片
      return _buildImage();
    }

    return _buildImage();
  }

  Widget _buildImage() {
    return widget.imagePath.startsWith('http')
        ? Image.network(
            widget.imagePath,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorWidget();
            },
          )
        : Image.asset(
            widget.imagePath,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorWidget();
            },
          );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Icon(
          Icons.error_outline,
          color: Colors.white,
          size: 48,
        ),
      ),
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
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMediaContent(),
          ),
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD7905F), Color(0xFFC060C3)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: ElevatedButton(
              onPressed: () => context.push(
                '/make-collage',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Use this theme',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
