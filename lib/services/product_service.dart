import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';

class ProductService {
  static const _productsKey = 'products';
  final Uuid _uuid = const Uuid();

  Future<List<Product>> getProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final productListJson = prefs.getStringList(_productsKey) ?? [];

    return productListJson
        .map((productJson) {
      try {
        final Map<String, dynamic> jsonMap = json.decode(productJson);
        return Product.fromJson(jsonMap);
      } catch (e) {
        print('Error parsing product: $e');
        return null;
      }
    })
        .whereType<Product>()
        .toList();
  }

  Future<void> saveProduct(Product product) async {
    final prefs = await SharedPreferences.getInstance();
    final products = await getProducts();

    if (product.id.isEmpty) {
      product.id = _uuid.v4();
      products.add(product);
    } else {
      final index = products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        products[index] = product;
      }
    }

    await prefs.setStringList(
      _productsKey,
      products.map((p) => json.encode(p.toJson())).toList(),
    );
  }

  Future<void> deleteProduct(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final products = await getProducts();
    products.removeWhere((product) => product.id == id);

    await prefs.setStringList(
      _productsKey,
      products.map((p) => json.encode(p.toJson())).toList(),
    );
  }
}