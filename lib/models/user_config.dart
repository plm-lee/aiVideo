class UserConfig {
  final int? id;
  final String key;
  final String value;

  UserConfig({
    this.id,
    required this.key,
    required this.value,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'key': key,
      'value': value,
    };
  }

  factory UserConfig.fromMap(Map<String, dynamic> map) {
    return UserConfig(
      id: map['id'],
      key: map['key'],
      value: map['value'],
    );
  }
}
