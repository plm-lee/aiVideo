import 'package:ai_video/api/api_client.dart';
import 'package:flutter/foundation.dart';

class VideoApi {
  static const String baseUrl = 'https://chat.bigchallenger.com';
  final ApiClient _apiClient;

  VideoApi({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(baseUrl: baseUrl);

  // 添加视频生成任务
  Future<Map<String, dynamic>> addVideoTask({
    required String uuid,
    required String image,
    required String prompt,
    required String model,
    required int duration,
  }) async {
    return await _apiClient.post(
      '/api/ai_video/add_task',
      {
        'uuid': uuid,
        'image': image,
        'prompt': prompt,
        'model': model,
        'duration': duration,
      },
    );
  }

  // 查询任务进度
  Future<Map<String, dynamic>> getTaskDetail({
    required String uuid,
    required String business_id,
  }) async {
    return await _apiClient.get(
      '/api/ai_video/task_detail?uuid=$uuid&business_id=$business_id',
    );
  }

  // 获取用户所有任务
  Future<Map<String, dynamic>> getUserTasks({
    required String uuid,
  }) async {
    return await _apiClient.get(
      '/api/ai_video/all_tasks',
      queryParameters: {
        'uuid': uuid,
      },
    );
  }

  // 获取视频样例库
  Future<Map<String, dynamic>> getVideoSamples({
    required String uuid,
  }) async {
    return await _apiClient.get(
      '/api/ai_video/samples',
      queryParameters: {'uuid': uuid},
    );
  }

  // 通过模版ID生成视频
  Future<Map<String, dynamic>> generateVideoByTemplateId({
    required String uuid,
    required int sampleId,
  }) async {
    return await _apiClient.get(
      '/api/ai_video/generate_video',
      queryParameters: {'uuid': uuid, 'sample_item_id': sampleId},
    );
  }
}
