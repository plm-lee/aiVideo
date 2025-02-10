import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ai_video/constants/theme.dart';
import 'package:provider/provider.dart';
import 'package:ai_video/providers/theme_provider.dart';
import 'package:ai_video/service/database_service.dart';
import 'package:ai_video/models/generated_video.dart';

class TextToVideoPage extends StatefulWidget {
  const TextToVideoPage({super.key});

  @override
  State<TextToVideoPage> createState() => _TextToVideoPageState();
}

class _TextToVideoPageState extends State<TextToVideoPage> {
  bool _isProMode = false;
  final TextEditingController _promptController = TextEditingController();
  String _selectedStyle = 'Realistic';
  bool _canGenerate = false;

  final List<String> _styles = [
    'Realistic',
    'Anime',
    'Cartoon',
    '3D Animation',
    'Cinematic',
  ];

  @override
  void initState() {
    super.initState();
    _promptController.addListener(_updateGenerateButtonState);
  }

  @override
  void dispose() {
    _promptController.removeListener(_updateGenerateButtonState);
    _promptController.dispose();
    super.dispose();
  }

  void _updateGenerateButtonState() {
    final canGenerate = _promptController.text.trim().isNotEmpty;
    if (canGenerate != _canGenerate) {
      setState(() {
        _canGenerate = canGenerate;
      });
    }
  }

  Widget _buildStyleSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacing),
      decoration: AppTheme.getCardDecoration(isDark),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? AppTheme.darkSecondaryTextColor
                      : AppTheme.lightSecondaryTextColor,
                  width: 0.2,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.wand_stars,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.smallSpacing),
                Text(
                  'Style',
                  style: AppTheme.getTitleStyle(isDark),
                ),
                const Spacer(),
                Text(
                  _selectedStyle,
                  style: AppTheme.getSubtitleStyle(isDark),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  color: isDark
                      ? AppTheme.darkSecondaryTextColor
                      : AppTheme.lightSecondaryTextColor,
                  size: 16,
                ),
              ],
            ),
          ),
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _styles.length,
              itemBuilder: (context, index) {
                final style = _styles[index];
                final isSelected = style == _selectedStyle;
                return GestureDetector(
                  onTap: () => setState(() => _selectedStyle = style),
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : (isDark ? Colors.black : Colors.white),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : isDark
                                ? AppTheme.darkSecondaryTextColor
                                    .withOpacity(0.3)
                                : AppTheme.lightSecondaryTextColor
                                    .withOpacity(0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        style,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                  ? AppTheme.darkTextColor
                                  : AppTheme.lightTextColor),
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacing),
      decoration: AppTheme.getCardDecoration(isDark),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? AppTheme.darkSecondaryTextColor
                      : AppTheme.lightSecondaryTextColor,
                  width: 0.2,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.lightbulb,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Your Ideas',
                  style: AppTheme.getTitleStyle(isDark),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    _promptController.text =
                        'A romantic couple walking on beach';
                  },
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.arrow_2_circlepath,
                        color: isDark
                            ? AppTheme.darkSecondaryTextColor
                            : AppTheme.lightSecondaryTextColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Random',
                        style: AppTheme.getSubtitleStyle(isDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing),
            child: TextField(
              controller: _promptController,
              maxLines: 4,
              style: AppTheme.getTitleStyle(isDark),
              decoration: InputDecoration(
                hintText:
                    'Keywords of the scene you imagine, separated by commas',
                hintStyle: AppTheme.getSubtitleStyle(isDark),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppTheme.darkSecondaryTextColor.withOpacity(0.3)
                        : AppTheme.lightSecondaryTextColor.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppTheme.darkSecondaryTextColor.withOpacity(0.3)
                        : AppTheme.lightSecondaryTextColor.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppTheme.darkSecondaryTextColor
                : AppTheme.lightSecondaryTextColor,
            width: 0.2,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _canGenerate ? _generateVideo : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            disabledBackgroundColor: isDark
                ? AppTheme.darkSecondaryTextColor
                : AppTheme.lightSecondaryTextColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.smallBorderRadius),
            ),
          ),
          child: Text(
            'Generate',
            style: TextStyle(
              color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _generateVideo() async {
    // TODO: 实现生成视频逻辑
    final video = GeneratedVideo(
      title: 'Generated Video ${DateTime.now()}',
      filePath: '/path/to/video.mp4', // 替换为实际路径
      style: _selectedStyle,
      prompt: _promptController.text,
      createdAt: DateTime.now(),
      type: 'text',
    );

    await DatabaseService().saveGeneratedVideo(video);
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
          'Text → Video',
          style: AppTheme.getTitleStyle(isDark),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildStyleSection(),
                  _buildPromptSection(),
                ],
              ),
            ),
          ),
          _buildBottomSection(),
        ],
      ),
    );
  }
}
