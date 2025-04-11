import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:ai_video/api/video_api.dart';
import 'package:ai_video/service/auth_service.dart';
import 'package:ai_video/models/video_task.dart';
import 'package:ai_video/models/video_sample.dart';
import 'package:ai_video/service/database_service.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:http/http.dart' as http;

class VideoService extends ChangeNotifier {
  final VideoApi _videoApi = VideoApi();
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

  // 通过theme创建视频
  Future<(bool, String)> themeToVideo({
    required int sampleId,
    required File imageFile,
    required bool isHighQuality,
    required int duration,
  }) async {
    try {
      // 获取当前用户信息
      final (success, message, user) = await _authService.getCurrentUser();
      if (!success || user == null) {
        return (false, message ?? 'User not logged in');
      }

      debugPrint('themeToVideo: ${sampleId}');

      final response = await _videoApi.generateVideoByTemplateId(
        uuid: user.uuid,
        sampleId: sampleId,
        model: isHighQuality ? 'std' : 'pro',
        duration: duration,
      );

      if (response['response']['success'] != '1') {
        return (
          false,
          'Failed to create video task: ${response['response']['description']}'
        );
      }

      return (true, 'Video task created successfully');
    } catch (e) {
      return (false, 'Video generation failed: $e');
    }
  }

  Future<(bool, String)> imageToVideo({
    required File imageFile,
    required String prompt,
    required int duration,
    required bool isHighQuality,
  }) async {
    try {
      // 获取当前用户信息
      final (success, message, user) = await _authService.getCurrentUser();
      if (!success || user == null) {
        return (false, message ?? 'User not logged in');
      }

      final List<int> imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      final response = await _videoApi.addVideoTask(
        image: base64Image,
        prompt: prompt,
        model: isHighQuality ? 'pro' : 'std',
        duration: duration,
        uuid: user.uuid,
      );

      if (response['response']['success'] != '1') {
        return (
          false,
          'Failed to create video task: ${response['response']['description']}'
        );
      }

      return (true, 'Video task created successfully');
    } catch (e) {
      return (false, 'Video generation failed: $e');
    }
  }

  Future<(bool, String)> textToVideo({
    required String prompt,
    required int duration,
    bool isHighQuality = false,
  }) async {
    try {
      // 获取当前用户信息
      final (success, message, user) = await _authService.getCurrentUser();
      if (!success || user == null) {
        return (false, message ?? 'User not logged in');
      }

      final response = await _videoApi.addVideoTask(
        image: '',
        prompt: prompt,
        model: isHighQuality ? 'pro' : 'std',
        duration: duration,
        uuid: user.uuid,
      );

      if (response['response']['success'] != '1') {
        return (
          false,
          'Failed to create video task: ${response['response']['description']}'
        );
      }

      return (true, 'Video task created successfully');
    } catch (e) {
      return (false, 'Video generation failed: $e');
    }
  }

  Future<(bool, String)> getUserTasks() async {
    debugPrint('刷新任务列表----');
    try {
      final (success, message, user) = await _authService.getCurrentUser();
      if (!success || user == null) {
        return (false, message ?? 'User not logged in');
      }

      final response = await _videoApi.getUserTasks(uuid: user.uuid);

      debugPrint('getUserTasks: ${user.uuid},response: ${response}');
      if (response['response']['success'] != '1') {
        return (
          false,
          'Failed to get tasks: ${response['response']['description']}'
        );
      }

      if (response['video_tasks'] == null) {
        return (false, 'Failed to get tasks: Empty server response');
      }

      final List<VideoTask> videoTasks =
          (response['video_tasks'] as List).map((task) {
        // 直接使用服务器返回的已解码字符串
        final prompt = task['prompt'] as String? ?? '';
        task['prompt'] = prompt;

        // 如果任务完成且有 object_key，将其作为视频地址
        if (task['object_key'] != null) {
          task['video_url'] = task['object_key'];
        }

        return VideoTask.fromJson(task as Map<String, dynamic>);
      }).toList();

      await _databaseService.saveVideoTasks(videoTasks);
      return (true, 'Get tasks successfully');
    } catch (e) {
      return (false, 'Failed to get tasks: $e');
    }
  }

  // 获取视频本地缓存路径
  Future<String?> getLocalVideoPath(String businessId) async {
    try {
      final directory = await path_provider.getApplicationDocumentsDirectory();
      final videoPath = '${directory.path}/videos/$businessId.mp4';
      final file = File(videoPath);

      if (await file.exists()) {
        return videoPath;
      }
      return null;
    } catch (e) {
      debugPrint('Failed to get local video path: $e');
      return null;
    }
  }

  // 下载并缓存视频
  Future<String?> downloadVideo(String url, String businessId) async {
    try {
      final directory = await path_provider.getApplicationDocumentsDirectory();
      final videoDir = Directory('${directory.path}/videos');
      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }

      final videoPath = '${videoDir.path}/$businessId.mp4';
      final file = File(videoPath);

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to download video');
      }

      await file.writeAsBytes(response.bodyBytes);
      return videoPath;
    } catch (e) {
      debugPrint('Failed to download video: $e');
      return null;
    }
  }

  // 获取视频素材库
  Future<List<VideoSample>> getVideoSamples() async {
    try {
      final (success, message, user) = await _authService.getCurrentUser();
      if (!success || user == null) {
        return [];
      }

      final response = await _videoApi.getVideoSamples(uuid: user.uuid);
      if (response['response']['success'] != '1') {
        return [];
      }

      debugPrint('getVideoSamples: ${response['samples']}');

      return (response['samples'] as List)
          .map((sample) => VideoSample.fromJson(sample as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting video samples: $e');
      return [];
    }
  }

  // 获取最新一条任务
  Future<VideoTask?> getLatestTask() async {
    // 先刷新一次
    final (success, message) = await getUserTasks();
    if (!success) {
      return null;
    }
    final videoTasks = await _databaseService.getVideoTasks();
    if (videoTasks.isNotEmpty) {
      return videoTasks.first;
    }
    return null;
  }

  // 查询任务进度
  Future<int> getTaskDetail(String businessId) async {
    final (success, message, user) = await _authService.getCurrentUser();
    if (!success || user == null) {
      return 0;
    }
    final response = await _videoApi.getTaskDetail(
      uuid: user.uuid,
      business_id: businessId,
    );
    if (response['response']['success'] != '1') {
      return 0;
    }

    debugPrint('getTaskDetail: ${response}');

    return response['video_task']['state'];
  }
}
