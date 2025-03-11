class VideoTask {
  final String businessId;
  final DateTime createdAt;
  final int state;
  final String prompt;
  final String? originImg;
  final String? videoUrl;
  final String? remark;

  VideoTask({
    required this.businessId,
    required this.createdAt,
    required this.state,
    required this.prompt,
    this.originImg,
    this.videoUrl,
    this.remark,
  });

  factory VideoTask.fromJson(Map<String, dynamic> json) {
    return VideoTask(
      businessId: json['business_id'],
      createdAt: DateTime.parse(json['created_at']),
      state: json['state'],
      prompt: json['prompt'],
      originImg: json['origin_img'],
      videoUrl: json['video_url'],
      remark: json['remark'],
    );
  }

  factory VideoTask.fromMap(Map<String, dynamic> map) {
    return VideoTask(
      businessId: map['business_id'],
      createdAt: DateTime.parse(map['created_at']),
      state: map['state'],
      prompt: map['prompt'],
      originImg: map['origin_img'],
      videoUrl: map['video_url'],
      remark: map['remark'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'business_id': businessId,
      'created_at': createdAt.toIso8601String(),
      'state': state,
      'prompt': prompt,
      'origin_img': originImg,
      'video_url': videoUrl,
      'remark': remark,
    };
  }
}
