import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bigchanllger/constants/theme.dart';
import 'package:provider/provider.dart';
import 'package:bigchanllger/providers/theme_provider.dart';
import 'package:bigchanllger/models/generated_video.dart';
import 'package:bigchanllger/service/database_service.dart';

class ImgToVideoPage extends StatefulWidget {
  const ImgToVideoPage({super.key});

  @override
  State<ImgToVideoPage> createState() => _ImgToVideoPageState();
}

class _ImgToVideoPageState extends State<ImgToVideoPage> {
  bool _isProMode = false;
  File? _selectedImage;
  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _generateVideo() async {
    if (_selectedImage == null) return;

    final video = GeneratedVideo(
      title: 'Generated Video ${DateTime.now()}',
      filePath: '/path/to/video.mp4', // 替换为实际路径
      style: 'default',
      prompt: '',
      createdAt: DateTime.now(),
      type: 'image',
      originalImagePath: _selectedImage!.path,
    );

    await DatabaseService().saveGeneratedVideo(video);
  }

  Widget _buildImageSection() {
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
                  CupertinoIcons.photo,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.smallSpacing),
                Text(
                  'Original Image',
                  style: AppTheme.getTitleStyle(isDark),
                ),
                const Spacer(),
                if (_selectedImage != null)
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: isDark
                          ? AppTheme.darkSecondaryTextColor
                          : AppTheme.lightSecondaryTextColor,
                      size: 20,
                    ),
                    onPressed: _pickImage,
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color:
                    isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.cloud_upload,
                            size: 48,
                            color: isDark
                                ? AppTheme.darkSecondaryTextColor
                                : AppTheme.lightSecondaryTextColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Click to upload',
                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.darkSecondaryTextColor
                                  : AppTheme.lightSecondaryTextColor,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Support JPG, PNG, etc.',
                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.darkSecondaryTextColor
                                  : AppTheme.lightSecondaryTextColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
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
          onPressed: _selectedImage != null
              ? () {
                  _generateVideo();
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            disabledBackgroundColor: Colors.grey,
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
          'Img To Video',
          style: AppTheme.getTitleStyle(isDark),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildImageSection(),
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
