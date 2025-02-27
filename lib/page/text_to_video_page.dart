import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ai_video/constants/theme.dart';
import 'package:provider/provider.dart';
import 'package:ai_video/providers/theme_provider.dart';
import 'package:ai_video/service/database_service.dart';
import 'package:ai_video/models/generated_video.dart';
import 'package:ai_video/service/video_service.dart';
import 'package:ai_video/utils/dialog_utils.dart';

class TextToVideoPage extends StatefulWidget {
  const TextToVideoPage({super.key});

  @override
  State<TextToVideoPage> createState() => _TextToVideoPageState();
}

class _TextToVideoPageState extends State<TextToVideoPage> {
  final _promptController = TextEditingController();
  int _selectedLength = 5; // 默认5秒
  bool _canGenerate = false; // 添加状态变量
  bool _isLoading = false; // 添加加载状态

  @override
  void initState() {
    super.initState();
    // 添加输入监听
    _promptController.addListener(_updateGenerateButtonState);
  }

  @override
  void dispose() {
    // 移除监听
    _promptController.removeListener(_updateGenerateButtonState);
    _promptController.dispose();
    super.dispose();
  }

  // 更新按钮状态
  void _updateGenerateButtonState() {
    final canGenerate = _promptController.text.trim().isNotEmpty;
    if (canGenerate != _canGenerate) {
      setState(() {
        _canGenerate = canGenerate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Text to Video',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Describe the video',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _promptController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          maxLines: 4,
                          maxLength: 1000,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Eg. A white little fox in the forest',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(bottom: 60),
                              child: Icon(
                                Icons.edit,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Video Length',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildLengthOption(5),
                          const SizedBox(width: 16),
                          _buildLengthOption(10),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildLengthOption(int seconds) {
    final isSelected = _selectedLength == seconds;
    return GestureDetector(
      onTap: () => setState(() => _selectedLength = seconds),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          '${seconds}s',
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD7905F), Color(0xFFC060C3)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.monetization_on, color: Color(0xFFFFD700)),
              SizedBox(width: 8),
              Text(
                '150 Coins',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          _buildGenerateButton(),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: _canGenerate
            ? const LinearGradient(
                colors: [Colors.white, Color(0xFFF0F0F0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: _canGenerate ? null : Colors.grey[400],
        borderRadius: BorderRadius.circular(24),
        boxShadow: _canGenerate
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _canGenerate && !_isLoading ? _generateVideo : null,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 12,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : Text(
                    'Generate',
                    style: TextStyle(
                      color: _canGenerate ? Colors.black : Colors.black38,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _generateVideo() async {
    setState(() => _isLoading = true);

    try {
      final videoService = VideoService();
      final (success, message) = await videoService.textToVideo(
        prompt: _promptController.text.trim(),
        duration: _selectedLength,
      );

      if (success) {
        _showSuccessMessage(message);
      } else {
        _showErrorMessage(message);
      }
    } catch (e) {
      _showErrorMessage('生成视频时发生错误：$e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorMessage(String message) {
    DialogUtils.showError(
      context: context,
      content: message,
    );
  }

  void _showSuccessMessage(String message) {
    DialogUtils.showSuccess(
      context: context,
      content: message,
      autoDismiss: true, // 2秒后自动关闭
      onDismissed: () {
        // 清空输入
        setState(() {
          _promptController.clear();
          _canGenerate = false;
        });
      },
    );
  }
}
