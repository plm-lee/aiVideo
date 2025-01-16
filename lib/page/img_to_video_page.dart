import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bigchanllger/constants/theme.dart';
import 'package:provider/provider.dart';
import 'package:bigchanllger/providers/theme_provider.dart';

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
                    icon:
                        const Icon(Icons.refresh, color: Colors.grey, size: 20),
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
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Click to upload',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Support JPG, PNG, etc.',
                            style: TextStyle(
                              color: Colors.grey[800],
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
        color: AppTheme.darkCardColor,
        border: Border(
          top: BorderSide(
            color: AppTheme.darkSecondaryTextColor,
            width: 0.2,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium,
                    color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Pro Mode',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _isProMode,
                  onChanged: (value) {
                    setState(() {
                      _isProMode = value;
                    });
                  },
                  activeColor: const Color(0xFFFF69B4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedImage != null
                  ? () {
                      // TODO: 实现生成视频逻辑
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF69B4),
                disabledBackgroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Generate',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
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
          'Img → Video',
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
