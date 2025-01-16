class GeneratedVideo {
  final int? id;
  final String title;
  final String filePath;
  final String style;
  final String prompt;
  final DateTime createdAt;
  final String type; // 'text' or 'image'
  final String? originalImagePath;

  GeneratedVideo({
    this.id,
    required this.title,
    required this.filePath,
    required this.style,
    required this.prompt,
    required this.createdAt,
    required this.type,
    this.originalImagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'filePath': filePath,
      'style': style,
      'prompt': prompt,
      'createdAt': createdAt.toIso8601String(),
      'type': type,
      'originalImagePath': originalImagePath,
    };
  }

  factory GeneratedVideo.fromMap(Map<String, dynamic> map) {
    return GeneratedVideo(
      id: map['id'],
      title: map['title'],
      filePath: map['filePath'],
      style: map['style'],
      prompt: map['prompt'],
      createdAt: DateTime.parse(map['createdAt']),
      type: map['type'],
      originalImagePath: map['originalImagePath'],
    );
  }
}
