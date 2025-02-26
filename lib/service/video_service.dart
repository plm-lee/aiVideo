import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:ai_video/api/video_api.dart';
import 'package:ai_video/service/auth_service.dart';
import 'package:ai_video/models/video_task.dart';
import 'package:ai_video/service/database_service.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

class VideoService extends ChangeNotifier {
  final VideoApi _videoApi = VideoApi();
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

  Future<(bool, String)> imageToVideo({
    required File imageFile,
    required String prompt,
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
        model: 'VideoMax-A',
        uuid: user.uuid,
      );

      if (response != null) {
        return (true, 'Video task created successfully');
      }

      // {"response":{"success":"1","description":"success","errorcode":"0000"},"business_id":"62e4b4d2a9a44ac7876fc193c2ef5ee5"}

      return (false, 'Failed to create video task: Empty server response');
    } catch (e) {
      return (false, 'Video generation failed: $e');
    }
  }

  Future<(bool, String)> textToVideo({
    required String prompt,
    required int duration,
  }) async {
    try {
      // 获取当前用户信息
      final (success, message, user) = await _authService.getCurrentUser();
      if (!success || user == null) {
        return (false, message ?? 'User not logged in');
      }

      final response = await _videoApi.addVideoTask(
        image: '', // 文本转视频不需要图片
        prompt: prompt,
        model: 'VideoMax-A', // 使用文本转视频模型
        uuid: user.uuid,
      );

      if (response != null) {
        return (true, 'Video task created successfully');
      }

      // {"response":{"success":"1","description":"success","errorcode":"0000"},"business_id":"62e4b4d2a9a44ac7876fc193c2ef5ee5"}

      return (false, 'Failed to create video task: Empty server response');
    } catch (e) {
      return (false, 'Video generation failed: $e');
    }
  }

  Future<(bool, String)> getUserTasks() async {
    try {
      final (success, message, user) = await _authService.getCurrentUser();
      if (!success || user == null) {
        return (false, message ?? 'User not logged in');
      }

      debugPrint('getUserTasks: ${user.uuid}');
      final response = await _videoApi.getUserTasks(uuid: user.uuid);
      if (response['response']['success'] != '1') {
        return (
          false,
          'Failed to get tasks: ${response['response']['description']}'
        );
      }

      final List<VideoTask> videoTasks =
          (response['video_tasks'] as List).map((task) {
        // 处理中文编码
        final decodedPrompt = utf8.decode(
          utf8.encode(task['prompt'] as String),
        );
        task['prompt'] = decodedPrompt;

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
}
