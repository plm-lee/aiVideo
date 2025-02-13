import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:ai_video/api/video_api.dart';
import 'package:ai_video/service/auth_service.dart';

class VideoService extends ChangeNotifier {
  final VideoApi _videoApi = VideoApi();
  final AuthService _authService = AuthService();

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
        model: 'video_model',
        uuid: user.uuid,
      );

      if (response != null) {
        return (true, '视频任务创建成功');
      }

      return (false, '视频任务创建失败：服务器响应为空');
    } catch (e) {
      return (false, '视频生成失败：$e');
    }
  }
}
