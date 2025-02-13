import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ai_video/service/credits_service.dart';
import 'package:provider/provider.dart';
import 'package:ai_video/widgets/bottom_nav_bar.dart';
import 'package:ai_video/service/video_service.dart';
import 'package:ai_video/service/database_service.dart';
import 'package:ai_video/models/video_task.dart';
import 'dart:convert';

class MinePage extends StatefulWidget {
  const MinePage({super.key});

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  final _videoService = VideoService();
  final _databaseService = DatabaseService();
  bool _isLoading = true;
  List<VideoTask> _tasks = [];

  @override
  void initState() {
    super.initState();
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
            const SizedBox(height: 32),
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
          itemCount: _tasks.length,
          itemBuilder: (context, index) {
            final task = _tasks[index];
            return _buildTaskCard(task);
          },
        ),
      ),
    );
  }

  Widget _buildTaskCard(VideoTask task) {
    String getDecodedPrompt(String prompt) {
      try {
        return utf8.decode(prompt.runes.toList());
      } catch (e) {
        debugPrint('解码提示词失败: $e');
        return prompt;
      }
    }

    final bool isImageTask =
        task.originImg != null && task.originImg!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isImageTask)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  task.originImg!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFF2E2E2E),
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.white,
                        size: 40,
                      ),
                    );
                  },
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
                    Icon(
                      isImageTask ? Icons.image : Icons.text_fields,
                      color: Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isImageTask ? 'Image to Video' : 'Text to Video',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  getDecodedPrompt(task.prompt),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  task.createdAt.toString().split('.')[0],
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
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
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Consumer<CreditsService>(
              builder: (context, creditsService, child) {
                return Row(
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${creditsService.credits} Coins',
                      style: const TextStyle(
                        color: Color(0xFFFF6B6B),
                        fontSize: 16,
                      ),
                    ),
                  ],
                );
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
}
