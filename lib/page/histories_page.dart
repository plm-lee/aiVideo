import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ai_video/constants/theme.dart';
import 'package:ai_video/models/generated_video.dart';
import 'package:ai_video/service/database_service.dart';

class HistoriesPage extends StatefulWidget {
  const HistoriesPage({super.key});

  @override
  State<HistoriesPage> createState() => _HistoriesPageState();
}

class _HistoriesPageState extends State<HistoriesPage> {
  List<GeneratedVideo> _histories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistories();
  }

  Future<void> _loadHistories() async {
    setState(() => _isLoading = true);
    try {
      final histories = await DatabaseService().getAllGeneratedVideos();
      setState(() {
        _histories = histories;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('加载历史记录失败: $e');
      setState(() => _isLoading = false);
    }
  }

  Widget _buildHistoryItem(GeneratedVideo video) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          video.title,
          style: AppTheme.getTitleStyle(isDark),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              '类型: ${video.type == 'text' ? '文字生成' : '图片生成'}',
              style: AppTheme.getSubtitleStyle(isDark),
            ),
            const SizedBox(height: 4),
            Text(
              '风格: ${video.style}',
              style: AppTheme.getSubtitleStyle(isDark),
            ),
            const SizedBox(height: 4),
            Text(
              '创建时间: ${video.createdAt.toString().split('.')[0]}',
              style: AppTheme.getSubtitleStyle(isDark),
            ),
          ],
        ),
        trailing: Icon(
          CupertinoIcons.chevron_right,
          color: isDark
              ? AppTheme.darkSecondaryTextColor
              : AppTheme.lightSecondaryTextColor,
          size: 20,
        ),
        onTap: () {
          // TODO: 实现视频详情页面跳转
          debugPrint('查看视频详情: ${video.title}');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.darkBackgroundColor : AppTheme.lightBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppTheme.darkBackgroundColor
            : AppTheme.lightBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Histories',
          style: AppTheme.getTitleStyle(isDark),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _histories.isEmpty
              ? Center(
                  child: Text(
                    '暂无历史记录',
                    style: AppTheme.getSubtitleStyle(isDark),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistories,
                  child: ListView.builder(
                    itemCount: _histories.length,
                    itemBuilder: (context, index) =>
                        _buildHistoryItem(_histories[index]),
                  ),
                ),
    );
  }
}
