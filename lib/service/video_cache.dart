import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:ai_video/models/video_sample.dart';

class VideoCache {
  static const String _cacheKey = 'video_categories_cache';
  static const String _cacheDateKey = 'video_categories_cache_date';

  /// 从缓存加载分类数据
  Future<List<VideoSample>> loadCachedCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString(_cacheKey);

      if (cachedData != null) {
        final List<dynamic> decoded = json.decode(cachedData);
        return decoded
            .map((item) => VideoSample.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading cached categories: $e');
    }

    return [];
  }

  /// 检查是否需要更新缓存
  Future<bool> shouldUpdateCache() async {
    // 如果缓存为空，则更新
    final cachedCategories = await loadCachedCategories();
    if (cachedCategories.isEmpty) return true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? lastUpdateStr = prefs.getString(_cacheDateKey);

      if (lastUpdateStr == null) return true;

      final DateTime lastUpdate = DateTime.parse(lastUpdateStr);
      final DateTime now = DateTime.now();

      // 如果缓存时间超过24小时，则更新
      return now.difference(lastUpdate).inMinutes >= 5;
    } catch (e) {
      debugPrint('Error checking cache update time: $e');
      return true;
    }
  }

  /// 更新缓存数据
  Future<void> updateCache(List<VideoSample> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 缓存分类数据
      final String encodedData = json.encode(
        categories
            .map((category) => {
                  'title': category.title,
                  'icon': category.icon,
                  'items': category.items
                      .map((item) => {
                            'title': item.title,
                            'image': item.image,
                            'video_url': item.videoUrl,
                            'img_num': item.imgNum,
                            'prompt': item.prompt,
                          })
                      .toList(),
                })
            .toList(),
      );

      await prefs.setString(_cacheKey, encodedData);

      // 更新缓存时间
      await prefs.setString(
        _cacheDateKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      debugPrint('Error updating cache: $e');
    }
  }

  /// 清除缓存
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheDateKey);
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }
}
