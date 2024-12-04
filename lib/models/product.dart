import 'package:uuid/uuid.dart';
class Product {
  String id;
  String name;
  String sku;
  double price;
  int quantity;

  Product({
    String? id,
    required this.name,
    required this.sku,
    required this.price,
    required this.quantity,
  }) : id = id ?? const Uuid().v4();

  // Convert to and from JSON for storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sku': sku,
    'price': price,
    'quantity': quantity,
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] ?? '',
    name: json['name'] ?? 'Unnamed Product',
    sku: json['sku'] ?? '',
    price: (json['price'] ?? 0.0).toDouble(),
    quantity: (json['quantity'] ?? 0).toInt(),
  );
}