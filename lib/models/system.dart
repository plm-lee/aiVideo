class SubscriptionPackage {
  final String productName;
  final String productId;
  final double amount;

  SubscriptionPackage({
    required this.productName,
    required this.productId,
    required this.amount,
  });

  factory SubscriptionPackage.fromJson(Map<String, dynamic> json) {
    return SubscriptionPackage(
      productName: json['productName'] as String,
      productId: json['productId'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productName': productName,
      'productId': productId,
      'amount': amount,
    };
  }
}
