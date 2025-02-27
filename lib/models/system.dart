class SubscriptionPackage {
  final String name;
  final String description;
  final int price;
  final bool isSubscription;
  final String uuid;

  SubscriptionPackage({
    required this.name,
    required this.description,
    required this.price,
    required this.isSubscription,
    required this.uuid,
  });

  factory SubscriptionPackage.fromJson(Map<String, dynamic> json) {
    return SubscriptionPackage(
      name: json['name'] as String,
      description: json['description'] as String,
      price: json['price'] as int,
      isSubscription: json['is_subscription'] as bool,
      uuid: json['uuid'] as String,
    );
  }
}
