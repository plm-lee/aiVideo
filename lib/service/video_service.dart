import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:ai_video/api/video_api.dart';
import 'package:ai_video/models/generated_video.dart';
import 'package:ai_video/service/database_service.dart';
import 'package:ai_video/service/auth_service.dart';

class VideoService extends ChangeNotifier {
  final VideoApi _videoApi;
  final DatabaseService _databaseService;
  final AuthService _authService;

  VideoService({
    required VideoApi videoApi,
    required DatabaseService databaseService,
    required AuthService authService,
  })  : _videoApi = videoApi,
        _databaseService = databaseService,
        _authService = authService;

  Future<(bool, String)> imageToVideo({
    required File imageFile,
    required String prompt,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null || currentUser.uuid == null) {
        return (false, '用户未登录或uuid为空');
      }

      final List<int> imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      final response = await _videoApi.addVideoTask(
        image: base64Image,
        prompt: prompt,
        model: 'video_model',
        uuid: currentUser.uuid,
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
