class VideoSample {
  final String title;
  final String icon;
  final List<VideoSampleItem> items;

  VideoSample({
    required this.title,
    required this.icon,
    required this.items,
  });

  factory VideoSample.fromJson(Map<String, dynamic> json) {
    return VideoSample(
      title: json['title'] as String,
      icon: json['icon'] as String,
      items: (json['items'] as List)
          .map((item) => VideoSampleItem.fromJson(item))
          .toList(),
    );
  }
}

class VideoSampleItem {
  final String title;
  final String image;
  final String videoUrl;
  final int imgNum;
  final String prompt;

  VideoSampleItem({
    required this.title,
    this.imgNum = 1,
    required this.image,
    required this.videoUrl,
    this.prompt = '',
  });

  factory VideoSampleItem.fromJson(Map<String, dynamic> json) {
    return VideoSampleItem(
      title: json['title'] as String? ?? '',
      imgNum: json['img_num'] as int? ?? 1,
      image: json['image'] as String? ?? '',
      videoUrl: json['video_url'] as String? ?? '',
      prompt: json['prompt'] as String? ?? '',
    );
  }
}
