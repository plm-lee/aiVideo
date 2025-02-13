class User {
  final int? id;
  final String email;
  final String token;
  final String uuid;
  final DateTime loginTime;

  User({
    this.id,
    required this.email,
    required this.token,
    required this.uuid,
    required this.loginTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'token': token,
      'uuid': uuid,
      'loginTime': loginTime.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'],
      token: map['token'],
      uuid: map['uuid'],
      loginTime: DateTime.parse(map['loginTime']),
    );
  }
}
