import 'product_model.dart';

class ProductResponse {

  const ProductResponse({
    required this.products,
    required this.total,
    required this.skip,
    required this.limit,
});

  final List<Product> products;
  final int total;
  final int skip;
  final int limit;

  bool get hasMore => skip + products.length < total;

  factory ProductResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['products'];
    final products = rawList is List
        ? rawList
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList()
        : <Product>[];

    return ProductResponse(
      products: products,
      total: (json['total'] as num?)?.toInt() ?? products.length,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? products.length,
    );
  }
}