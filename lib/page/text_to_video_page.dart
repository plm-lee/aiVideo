import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class TextToVideoPage extends StatefulWidget {
  const TextToVideoPage({super.key});

  @override
  State<TextToVideoPage> createState() => _TextToVideoPageState();
}

class _TextToVideoPageState extends State<TextToVideoPage> {
  bool _isProMode = false;
  final TextEditingController _promptController = TextEditingController();
  String _selectedStyle = 'Realistic';

  final List<String> _styles = [
    'Realistic',
    'Anime',
    'Cartoon',
    '3D Animation',
    'Cinematic',
  ];

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Widget _buildStyleSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF69B4).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey,
                  width: 0.2,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.wand_stars,
                  color: Color(0xFFFF69B4),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Style',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  _selectedStyle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_right,
                  color: Colors.grey,
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
                      color:
                          isSelected ? const Color(0xFFFF69B4) : Colors.black,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFF69B4)
                            : Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        style,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey,
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
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF69B4).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey,
                  width: 0.2,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.lightbulb,
                  color: Color(0xFFFF69B4),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Your Ideas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    _promptController.text =
                        'A romantic couple walking on beach';
                  },
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.arrow_2_circlepath,
                        color: Colors.grey,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Random',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _promptController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText:
                    'Keywords of the scene you imagine, separated by commas',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.grey.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.grey.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFFF69B4),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(
          top: BorderSide(
            color: Colors.grey,
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
              onPressed: _promptController.text.isNotEmpty
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Text → Video',
          style: TextStyle(color: Colors.white),
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
