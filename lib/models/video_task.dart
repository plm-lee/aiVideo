class VideoTask {
  final String businessId;
  final DateTime createdAt;
  final int state;
  final String prompt;
  final String? originImg;

  VideoTask({
    required this.businessId,
    required this.createdAt,
    required this.state,
    required this.prompt,
    this.originImg,
  });

  factory VideoTask.fromJson(Map<String, dynamic> json) {
    return VideoTask(
      businessId: json['business_id'],
      createdAt: DateTime.parse(json['created_at']),
      state: json['state'],
      prompt: json['prompt'],
      originImg: json['origin_img'],
    );
  }
}
