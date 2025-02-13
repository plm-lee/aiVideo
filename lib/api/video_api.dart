import 'package:ai_video/api/api_client.dart';

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
  }) async {
    return await _apiClient.post(
      '/api/ai_video/add_task',
      {
        'uuid': uuid,
        'image': image,
        'prompt': prompt,
        'model': model,
      },
    );
  }

  // 获取用户所有任务
  Future<Map<String, dynamic>> getUserTasks({
    required String uuid,
    int page = 1,
    int pageSize = 10,
  }) async {
    return await _apiClient.post(
      '/api/ai_video/all_tasks',
      {
        'uuid': uuid,
        // 'page': page,
        // 'page_size': pageSize,
      },
    );
  }
}
