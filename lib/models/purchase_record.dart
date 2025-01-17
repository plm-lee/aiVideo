class PurchaseRecord {
  final int id;
  final String title;
  final int amount;
  final String createdAt;
  final String? expireAt;
  final int userId;

  PurchaseRecord({
    required this.id,
    required this.title,
    required this.amount,
    required this.createdAt,
    this.expireAt,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'createdAt': createdAt,
      'expireAt': expireAt,
      'userId': userId,
    };
  }

  factory PurchaseRecord.fromMap(Map<String, dynamic> map) {
    return PurchaseRecord(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      createdAt: map['createdAt'],
      expireAt: map['expireAt'],
      userId: map['userId'],
    );
  }
}
