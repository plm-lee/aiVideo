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
  XFile? _selectedImage;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() => _selectedImage = image);
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
            onPressed: () {
              // TODO: 切换布局
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: _selectedImage != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Image.file(
                            File(_selectedImage!.path),
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() => _selectedImage = null);
                            },
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildUploadButton(),
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
          ),
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildUploadButton() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFD7905F).withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.add, color: Color(0xFFD7905F)),
        onPressed: _pickImage,
      ),
    );
  }

  Widget _buildBottomSection() {
    final bool canGenerate = _selectedImage != null;

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
