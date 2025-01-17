class UserConfig {
  final int? id;
  final String key;
  final String value;
  final int? userId;

  UserConfig({
    this.id,
    required this.key,
    required this.value,
    this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'key': key,
      'value': value,
      'userId': userId,
    };
  }

  factory UserConfig.fromMap(Map<String, dynamic> map) {
    return UserConfig(
      id: map['id'],
      key: map['key'],
      value: map['value'],
      userId: map['userId'],
    );
  }
}
