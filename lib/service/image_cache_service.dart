import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  Future<String?> getCachedImagePath(String url) async {
    try {
      final directory = await path_provider.getApplicationDocumentsDirectory();
      final fileName = _generateFileName(url);
      final imagePath = '${directory.path}/image_cache/$fileName';
      final file = File(imagePath);

      if (await file.exists()) {
        return imagePath;
      }
      return null;
    } catch (e) {
      debugPrint('获取缓存图片路径失败: $e');
      return null;
    }
  }

  Future<String?> downloadAndCacheImage(String url) async {
    try {
      final directory = await path_provider.getApplicationDocumentsDirectory();
      final cacheDir = Directory('${directory.path}/image_cache');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      final fileName = _generateFileName(url);
      final imagePath = '${cacheDir.path}/$fileName';
      final file = File(imagePath);

      // 如果文件已存在，直接返回路径
      if (await file.exists()) {
        return imagePath;
      }

      // 下载图片
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('下载图片失败');
      }

      // 保存图片
      await file.writeAsBytes(response.bodyBytes);
      return imagePath;
    } catch (e) {
      debugPrint('下载并缓存图片失败: $e');
      return null;
    }
  }

  String _generateFileName(String url) {
    // 使用 URL 的 MD5 值作为文件名
    final bytes = utf8.encode(url);
    final digest = md5.convert(bytes);
    return '$digest.jpg';
  }

  Future<void> clearCache() async {
    try {
      final directory = await path_provider.getApplicationDocumentsDirectory();
      final cacheDir = Directory('${directory.path}/image_cache');
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('清除缓存失败: $e');
    }
  }
}
