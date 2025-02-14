import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:ai_video/api/video_api.dart';
import 'package:ai_video/service/auth_service.dart';
import 'package:ai_video/models/video_task.dart';
import 'package:ai_video/service/database_service.dart';

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
        return (false, message ?? '用户未登录');
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
        return (true, '视频任务创建成功');
      }

      // {"response":{"success":"1","description":"success","errorcode":"0000"},"business_id":"62e4b4d2a9a44ac7876fc193c2ef5ee5"}

      return (false, '视频任务创建失败：服务器响应为空');
    } catch (e) {
      return (false, '视频生成失败：$e');
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
        return (false, message ?? '用户未登录');
      }

      final response = await _videoApi.addVideoTask(
        image: '', // 文本转视频不需要图片
        prompt: prompt,
        model: 'TextMax-A', // 使用文本转视频模型
        uuid: user.uuid,
      );

      if (response != null) {
        return (true, '视频任务创建成功');
      }

      // {"response":{"success":"1","description":"success","errorcode":"0000"},"business_id":"62e4b4d2a9a44ac7876fc193c2ef5ee5"}

      return (false, '视频任务创建失败：服务器响应为空');
    } catch (e) {
      return (false, '视频生成失败：$e');
    }
  }

  Future<(bool, String)> getUserTasks() async {
    try {
      final (success, message, user) = await _authService.getCurrentUser();
      if (!success || user == null) {
        return (false, message ?? '用户未登录');
      }

      final response = await _videoApi.getUserTasks(uuid: user.uuid);
      if (response['response']['success'] != '1') {
        return (false, '获取任务失败：${response['response']['description']}');
      }

      final List<VideoTask> videoTasks =
          (response['video_tasks'] as List).map((task) {
        // 处理中文编码
        final decodedPrompt = utf8.decode(
          utf8.encode(task['prompt'] as String),
        );
        task['prompt'] = decodedPrompt;

        // 如果任务完成且有 object_key，将其作为视频地址
        if (task['state'] == 1 && task['object_key'] != null) {
          task['video_url'] = task['object_key'];
        }

        return VideoTask.fromJson(task as Map<String, dynamic>);
      }).toList();

      await _databaseService.saveVideoTasks(videoTasks);
      return (true, '获取任务成功');
    } catch (e) {
      return (false, '获取任务失败：$e');
    }
  }
}
