import 'package:flutter/material.dart';
import 'package:ai_video/models/video_task.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dart:convert';
import 'dart:io';
import 'package:ai_video/service/video_service.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

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
  bool _hasCopied = false;

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

  Future<void> _saveVideoToGallery() async {
    if (widget.task.videoUrl == null) return;

    final PermissionState permission =
        await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      debugPrint('Photo library permission not granted');
      return;
    }

    try {
      String? localPath = await _videoService.getLocalVideoPath(
        widget.task.businessId,
      );

      if (localPath == null) {
        localPath = await _videoService.downloadVideo(
          widget.task.videoUrl!,
          widget.task.businessId,
        );
      }

      if (localPath != null) {
        final result = await PhotoManager.editor.saveVideo(
          File(localPath),
          title: 'video_${widget.task.businessId}',
        );
        if (result != null) {
          debugPrint('Video saved to gallery');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Video saved to gallery')),
          );
        } else {
          throw Exception('Failed to save video');
        }
      }
    } catch (e) {
      debugPrint('Error saving video: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save video')),
      );
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

  void _copyPrompt(String text) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _hasCopied = true);
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

  @override
  Widget build(BuildContext context) {
    final decodedPrompt = widget.task.prompt;

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
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Task Details',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFD7905F), Color(0xFFC060C3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Icon(Icons.save_alt, color: Colors.white),
              ),
              onPressed: _saveVideoToGallery,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1E1E1E),
                    const Color(0xFF2A2A2A).withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD7905F).withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    _buildVideoPreview(),
                    if (_videoController?.value.isInitialized ?? false)
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.fullscreen,
                              color: Colors.white,
                              size: 24,
                            ),
                            onPressed: _toggleFullScreen,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getStatusColor(widget.task.state),
                              _getStatusColor(widget.task.state)
                                  .withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _getStatusColor(widget.task.state)
                                  .withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.task.state == 1
                                  ? Icons.check_circle
                                  : widget.task.state == 0
                                      ? Icons.hourglass_empty
                                      : Icons.error,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getStatusText(widget.task.state),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          '5s',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFD7905F), Color(0xFFC060C3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Prompt',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1E1E1E),
                          const Color(0xFF2A2A2A).withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            right: 40,
                            bottom: 8,
                          ),
                          child: Text(
                            decodedPrompt,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -8,
                          right: -8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: IconButton(
                              icon: ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                  colors: [
                                    Color(0xFFD7905F),
                                    Color(0xFFC060C3)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds),
                                child: Icon(
                                  _hasCopied
                                      ? Icons.check_rounded
                                      : Icons.copy_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              onPressed: () => _copyPrompt(decodedPrompt),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Created',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.task.createdAt.toString().split('.')[0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
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
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD7905F)),
                  strokeWidth: 2,
                ),
                SizedBox(height: 12),
                Text(
                  'Downloading video...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
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
            alignment: Alignment.center,
            children: [
              VideoPlayer(_videoController!),
              if (!_isPlaying)
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD7905F), Color(0xFFC060C3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD7905F).withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
            ],
          ),
        ),
      );
    } else if (widget.task.state == 0) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFD7905F)),
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Processing...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.grey,
                size: 40,
              ),
              SizedBox(height: 12),
              Text(
                'Video not ready',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
