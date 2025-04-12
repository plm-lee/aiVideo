import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img; // 添加image包用于图片处理
import 'package:ai_video/service/video_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:ai_video/utils/dialog_utils.dart'; // 添加导入
import 'package:ai_video/utils/coin_check_utils.dart';
import 'package:provider/provider.dart';
import 'package:ai_video/service/user_service.dart';

class MakeCollagePage extends StatefulWidget {
  final int imgNum;
  final int sampleId;

  const MakeCollagePage({
    super.key,
    required this.imgNum,
    required this.sampleId,
  });

  @override
  State<MakeCollagePage> createState() => _MakeCollagePageState();
}

class _MakeCollagePageState extends State<MakeCollagePage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _leftImage; // 左侧图片
  XFile? _rightImage;
  bool _isSplitLayout = false;
  bool _isLoading = false; // 添加加载状态

  @override
  void initState() {
    super.initState();
    _isSplitLayout = widget.imgNum == 2; // 根据imgNum设置布局

    debugPrint('makeCollagePage by sampleId: ${widget.sampleId}');
  }

  void _toggleLayout() {
    // 如果imgNum为2，不允许切换布局
    if (widget.imgNum == 2) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLayoutOption(
                    isSelected: !_isSplitLayout,
                    icon: Icons.crop_square,
                    onTap: () {
                      setState(() {
                        _isSplitLayout = false;
                        _rightImage = null; // 切换到单图时清除右侧图片
                      });
                      Navigator.pop(context);
                    },
                  ),
                  _buildLayoutOption(
                    isSelected: _isSplitLayout,
                    icon: Icons.vertical_split,
                    onTap: () {
                      setState(() => _isSplitLayout = true);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLayoutOption({
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFFD7905F) : Colors.grey,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isSelected ? const Color(0xFFD7905F) : Colors.grey,
          size: 32,
        ),
      ),
    );
  }

  Future<void> _pickImage(bool isLeftImage) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          if (_isSplitLayout) {
            if (isLeftImage) {
              _leftImage = image;
            } else {
              _rightImage = image;
            }
          } else {
            _leftImage = image;
            _rightImage = null;
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<File?> _mergeAndCompressImages() async {
    try {
      // 读取图片
      final leftImageBytes = await File(_leftImage!.path).readAsBytes();
      final leftImg = img.decodeImage(leftImageBytes);
      if (leftImg == null) return null;

      img.Image finalImage;

      if (_isSplitLayout && _rightImage != null) {
        // 双图模式
        final rightImageBytes = await File(_rightImage!.path).readAsBytes();
        final rightImg = img.decodeImage(rightImageBytes);
        if (rightImg == null) return null;

        // 计算目标尺寸 (9:16 比例)
        const targetAspectRatio = 3 / 4;
        final targetWidth = 720; // 设置合适的宽度
        final targetHeight = (targetWidth / targetAspectRatio).round();

        // 调整每张图片的大小
        final halfWidth = targetWidth ~/ 2;
        final resizedLeft = img.copyResize(
          leftImg,
          width: halfWidth,
          height: targetHeight,
          interpolation: img.Interpolation.linear,
        );
        final resizedRight = img.copyResize(
          rightImg,
          width: halfWidth,
          height: targetHeight,
          interpolation: img.Interpolation.linear,
        );

        // 创建新图像并拼接
        finalImage = img.Image(width: targetWidth, height: targetHeight);
        img.compositeImage(finalImage, resizedLeft);
        img.compositeImage(
          finalImage,
          resizedRight,
          dstX: halfWidth,
        );
      } else {
        // 单图模式
        const targetAspectRatio = 9 / 16;
        final targetWidth = 720;
        final targetHeight = (targetWidth / targetAspectRatio).round();

        // 调整图片大小并保持比例
        final resized = img.copyResize(
          leftImg,
          width: targetWidth,
          height: targetHeight,
          interpolation: img.Interpolation.linear,
        );

        finalImage = resized;
      }

      // 保存处理后的图片
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/merged_image.jpg');
      await tempFile.writeAsBytes(img.encodeJpg(finalImage, quality: 90));

      return tempFile;
    } catch (e) {
      debugPrint('Error processing images: $e');
      return null;
    }
  }

  Widget _buildBottomSection() {
    // 检查是否可以生成
    final bool canGenerate = _leftImage != null &&
        (!_isSplitLayout || (_isSplitLayout && _rightImage != null));
    final userService = context.watch<UserService>();
    final int requiredCoins = 100; // 固定100金币

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFD7905F).withOpacity(canGenerate ? 1 : 0.5),
                  const Color(0xFFC060C3).withOpacity(canGenerate ? 1 : 0.5),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: ElevatedButton(
              onPressed: canGenerate && !_isLoading ? _generateVideo : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    )
                  : const Text(
                      'Generate Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.monetization_on,
                color: Color(0xFFFFD700),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '$requiredCoins Coins',
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _generateVideo() async {
    final userService = context.read<UserService>();
    final int requiredCoins = 100; // 固定100金币

    // 检查金币余额
    final hasEnoughCoins = await CoinCheckUtils.checkCoinsBalance(
      context,
      requiredCoins: requiredCoins,
    );

    if (!hasEnoughCoins) return;

    setState(() => _isLoading = true);

    try {
      // 检查是否有必要的图片
      if (_leftImage == null || (_isSplitLayout && _rightImage == null)) {
        throw Exception('请选择所需的图片');
      }

      // 如果是双图模式，需要处理拼接
      File imageToUse;
      if (_isSplitLayout) {
        final mergedImage = await _mergeAndCompressImages();
        if (mergedImage == null) {
          throw Exception('图片处理失败');
        }
        imageToUse = mergedImage;
      } else {
        // 单图模式，直接使用左侧图片
        imageToUse = File(_leftImage!.path);
      }

      final videoService = VideoService();
      final (success, message) = await videoService.themeToVideo(
        imageFile: imageToUse,
        sampleId: widget.sampleId,
        isHighQuality: false, // 固定为false
        duration: 5, // 固定为5秒
      );

      if (success) {
        _showSuccessMessage(message);
      } else {
        _showErrorMessage(message);
      }
    } catch (e) {
      _showErrorMessage(e.toString());
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
    // 清空选择的图片
    setState(() {
      _leftImage = null;
      _rightImage = null;
    });
    // 跳转到等待页面
    context.go('/processing');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Make Collage',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          // 只有在imgNum为1时显示布局切换按钮
          if (widget.imgNum == 1)
            IconButton(
              icon: const Icon(Icons.grid_view, color: Colors.white),
              onPressed: _toggleLayout,
            ),
        ],
      ),
      body: Column(
        children: [
          const Spacer(flex: 1),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: MediaQuery.of(context).size.height * 2 / 3, // 占屏幕高度的 2/3
            child: AspectRatio(
              aspectRatio: 1.5,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: _isSplitLayout
                    ? Row(
                        children: [
                          Expanded(
                            child: _buildUploadSection(isLeftSide: true),
                          ),
                          Container(
                            width: 1,
                            color: Colors.grey[800],
                          ),
                          Expanded(
                            child: _buildUploadSection(isLeftSide: false),
                          ),
                        ],
                      )
                    : _buildUploadSection(isLeftSide: true),
              ),
            ),
          ),
          const Spacer(flex: 1),
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildUploadSection({required bool isLeftSide}) {
    final currentImage = isLeftSide ? _leftImage : _rightImage;

    if (currentImage != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(currentImage.path),
            fit: BoxFit.cover,
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _pickImage(isLeftSide),
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => setState(() {
                if (isLeftSide) {
                  _leftImage = null;
                } else {
                  _rightImage = null;
                }
              }),
            ),
          ),
        ],
      );
    }

    return Material(
      color: Colors.grey[900],
      child: InkWell(
        onTap: () => _pickImage(isLeftSide),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildUploadButton(isLeftSide),
              const SizedBox(height: 16),
              const Text(
                'Upload',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadButton(bool isLeftSide) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFD7905F).withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.add, color: Color(0xFFD7905F)),
        onPressed: () => _pickImage(isLeftSide),
      ),
    );
  }
}
