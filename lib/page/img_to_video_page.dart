import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ai_video/constants/theme.dart';
import 'package:provider/provider.dart';
import 'package:ai_video/providers/theme_provider.dart';
import 'package:ai_video/models/generated_video.dart';
import 'package:ai_video/service/database_service.dart';
import 'package:ai_video/service/video_service.dart';
import 'package:ai_video/service/user_service.dart';
import 'package:ai_video/utils/dialog_utils.dart';
import 'package:ai_video/utils/coin_check_utils.dart';
import 'package:go_router/go_router.dart';

class ImgToVideoPage extends StatefulWidget {
  const ImgToVideoPage({super.key});

  @override
  State<ImgToVideoPage> createState() => _ImgToVideoPageState();
}

class _ImgToVideoPageState extends State<ImgToVideoPage> {
  final _promptController = TextEditingController();
  File? _selectedImage;
  final _picker = ImagePicker();
  int _selectedLength = 5; // 默认5秒
  bool _isLoading = false; // 添加加载状态
  bool _hasPromptInput = false; // 添加提示词输入状态
  bool _isHighQuality = false; // 添加高品质选项状态

  @override
  void initState() {
    super.initState();
    _promptController.addListener(() {
      setState(() {
        _hasPromptInput = _promptController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
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
            'Image to Video',
            style: TextStyle(color: Colors.white, fontSize: 20),
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
                        'Upload a Photo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Image file size should not exceed 8MB, the length of the shortest side should be greater than 400px.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 140,
                          width: 140,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.add,
                                    color: Colors.grey,
                                    size: 32,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Upload',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Describe the video',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '(Optional)',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
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
                          maxLines: 3,
                          maxLength: 1000,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Eg. A white little fox in the forest',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(bottom: 40),
                              child: Icon(Icons.edit, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Video Length',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
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
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: _isHighQuality,
                            onChanged: (value) {
                              setState(() {
                                _isHighQuality = value ?? false;
                              });
                            },
                            activeColor: const Color(0xFFD7905F),
                            side: const BorderSide(color: Colors.white),
                          ),
                          Consumer<UserService>(
                            builder: (context, userService, child) {
                              return Text(
                                'High Quality (Member Free)',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              );
                            },
                          ),
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
    final bool canGenerate = _selectedImage != null && _hasPromptInput;
    final userService = context.watch<UserService>();
    final int baseCoins = _selectedLength == 10 ? 200 : 100;
    final int requiredCoins =
        _isHighQuality && !userService.isSubscribed ? baseCoins * 2 : baseCoins;

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
          Row(
            children: [
              const Icon(Icons.monetization_on, color: Color(0xFFFFD700)),
              const SizedBox(width: 8),
              Text(
                '$requiredCoins Coins',
                style: const TextStyle(
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
    final bool canGenerate = _selectedImage != null && _hasPromptInput;

    return Container(
      decoration: BoxDecoration(
        gradient: canGenerate
            ? const LinearGradient(
                colors: [Colors.white, Color(0xFFF0F0F0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: canGenerate ? null : Colors.grey[400],
        borderRadius: BorderRadius.circular(24),
        boxShadow: canGenerate
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
          onTap: canGenerate && !_isLoading ? _generateVideo : null,
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
                      color: canGenerate ? Colors.black : Colors.black38,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

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
    final int baseCoins = _selectedLength == 10 ? 200 : 100;
    final int requiredCoins = _isHighQuality ? baseCoins * 2 : baseCoins;

    // 检查金币余额
    final hasEnoughCoins = await CoinCheckUtils.checkCoinsBalance(
      context,
      requiredCoins: requiredCoins,
    );

    if (!hasEnoughCoins) return;

    setState(() => _isLoading = true);

    try {
      final videoService = VideoService();
      final (success, message) = await videoService.imageToVideo(
        imageFile: _selectedImage!,
        prompt: _promptController.text.trim(),
        duration: _selectedLength,
        isHighQuality: _isHighQuality,
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
    // 先移除焦点，避免自动打开键盘
    FocusScope.of(context).unfocus();

    setState(() {
      _selectedImage = null;
      _promptController.clear();
    });
    // 跳转到进度页面
    context.go('/processing');
  }
}
