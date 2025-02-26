import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class MakeCollagePage extends StatefulWidget {
  const MakeCollagePage({
    super.key,
  });

  @override
  State<MakeCollagePage> createState() => _MakeCollagePageState();
}

class _MakeCollagePageState extends State<MakeCollagePage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _leftImage; // 左侧图片
  XFile? _rightImage; // 右侧图片
  bool _isSplitLayout = false;

  void _toggleLayout() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Make Collage',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
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
          GestureDetector(
            onTap: () => _pickImage(isLeftSide),
            child: Image.file(
              File(currentImage.path),
              fit: BoxFit.cover,
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

    return Center(
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

  Widget _buildBottomSection() {
    final bool canGenerate = _isSplitLayout
        ? _leftImage != null && _rightImage != null
        : _leftImage != null;

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
              onPressed: canGenerate
                  ? () {
                      // TODO: 生成拼图
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
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
            children: const [
              Icon(
                Icons.monetization_on,
                color: Colors.white,
                size: 16,
              ),
              SizedBox(width: 4),
              Text(
                '150 Coins',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
