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
      // {"response":{"success":"1","description":"success","errorcode":"0000"},"video_tasks":[{"business_id":"dba7feb1e2cc41d3842e4cc4c37dba28","created_at":"2025-02-11 07:40","state":1,"prompt":"让图片中的狗奔跑起来","origin_img":"https://magaai.s3.us-west-1.amazonaws.com/2025/02/11/aduio_img/8839693ce1e04f9498fe253cc7a1295e?X-Amz-Algorithm=AWS4-HMAC-SHA256\u0026X-Amz-Credential=AKIAQ4NSA4KUYKEC6U7L%2F20250213%2Fus-west-1%2Fs3%2Faws4_request\u0026X-Amz-Date=20250213T014543Z\u0026X-Amz-Expires=3600\u0026X-Amz-SignedHeaders=host\u0026X-Amz-Signature=b03b49643f70ee5d773d0d9887c473b400094a33a29032661696d6d0b9fc0c95"}]}
      if (response['response']['success'] != '1') {
        return (false, '获取任务失败：${response['response']['description']}');
      }

      final List<VideoTask> videoTasks = response['video_tasks']
          .map((task) => VideoTask.fromJson(task))
          .toList();

      // 保存到db
      await _databaseService.saveVideoTasks(videoTasks);

      return (true, '获取任务成功');
    } catch (e) {
      return (false, '获取任务失败：$e');
    }
  }
}
