class SubscriptionPackage {
  final String name;
  final String description;
  final int price;
  final String uuid;
  final int discount;

  SubscriptionPackage({
    required this.name,
    required this.description,
    required this.price,
    required this.uuid,
    required this.discount,
  });

  factory SubscriptionPackage.fromJson(Map<String, dynamic> json) {
    return SubscriptionPackage(
      name: json['name'] as String,
      description: json['description'] as String,
      price: json['price'] as int,
      uuid: json['uuid'] as String,
      discount: json['discount'] as int,
    );
  }
}
