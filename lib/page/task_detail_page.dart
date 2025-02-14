import 'package:flutter/material.dart';
import 'package:ai_video/models/video_task.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dart:convert';
import 'dart:io';
import 'package:ai_video/service/video_service.dart';

class TaskDetailPage extends StatefulWidget {
  final VideoTask task;

  const TaskDetailPage({
    super.key,
    required this.task,
  });

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  final _videoService = VideoService();
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isPlaying = false;
  bool _isFullScreen = false;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    if (widget.task.videoUrl == null) return;

    try {
      // 先检查本地缓存
      String? localPath = await _videoService.getLocalVideoPath(
        widget.task.businessId,
      );

      // 如果本地没有，下载并缓存
      if (localPath == null) {
        setState(() => _isDownloading = true);
        localPath = await _videoService.downloadVideo(
          widget.task.videoUrl!,
          widget.task.businessId,
        );
        setState(() => _isDownloading = false);
      }

      if (localPath == null) {
        debugPrint('Failed to get video');
        return;
      }

      // 使用本地文件初始化播放器
      _videoController = VideoPlayerController.file(File(localPath));
      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: true,
        aspectRatio: _videoController!.value.aspectRatio,
        showControls: false,
        autoInitialize: true,
      );

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Video initialization failed: $e');
    }
  }

  void _togglePlay() {
    if (_videoController == null) return;

    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _videoController!.play();
      } else {
        _videoController!.pause();
      }
    });
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  String _getDecodedPrompt(String prompt) {
    try {
      return utf8.decode(prompt.runes.toList());
    } catch (e) {
      debugPrint('解码提示词失败: $e');
      return prompt;
    }
  }

  String _getStatusText(int state) {
    switch (state) {
      case 0:
        return 'Processing';
      case 1:
        return 'Completed';
      case 2:
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
      case 2:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final decodedPrompt = _getDecodedPrompt(widget.task.prompt);

    if (_isFullScreen && _videoController != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
                  onPressed: _toggleFullScreen,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Task Details',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 视频预览框
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    _buildVideoPreview(),
                    if (_videoController?.value.isInitialized ?? false)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: IconButton(
                          icon: const Icon(
                            Icons.fullscreen,
                            color: Colors.white,
                          ),
                          onPressed: _toggleFullScreen,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(widget.task.state),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _getStatusText(widget.task.state),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Prompt',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      decodedPrompt,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (_isDownloading) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 8),
              Text(
                'Downloading video...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.task.videoUrl != null &&
        _videoController?.value.isInitialized == true) {
      return GestureDetector(
        onTap: _togglePlay,
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: Stack(
            children: [
              VideoPlayer(_videoController!),
              if (!_isPlaying)
                Center(
                  child: Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
            ],
          ),
        ),
      );
    } else if (widget.task.state == 0) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.hourglass_empty,
                color: Colors.white,
                size: 36,
              ),
              SizedBox(height: 8),
              Text(
                'Processing...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const AspectRatio(
      aspectRatio: 16 / 9,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 36,
            ),
            SizedBox(height: 8),
            Text(
              'Video not ready',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
