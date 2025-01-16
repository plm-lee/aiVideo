class User {
  final int? id;
  final String email;
  final String token;
  final DateTime loginTime;

  User({
    this.id,
    required this.email,
    required this.token,
    required this.loginTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'token': token,
      'loginTime': loginTime.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'],
      token: map['token'],
      loginTime: DateTime.parse(map['loginTime']),
    );
  }
}
