import 'package:flutter_test/flutter_test.dart';
import 'package:shop_manager/features/products/models/product_model.dart';
import 'package:shop_manager/features/products/models/product_response.dart';

void main() {
  final fullJson = <String, dynamic>{
    'id': 1,
    'title': 'Essence Mascara',
    'description': 'A great mascara',
    'price': 9.99,
    'category': 'beauty',
    'brand': 'Essence',
    'stock': 5,
    'rating': 4.94,
    'discountPercentage': 7.17,
    'thumbnail': 'https://example.com/thumb.png',
    'images': ['https://example.com/1.png', 'https://example.com/2.png'],
  };

  group('Product.fromJson', () {
    test('parses a complete product', () {
      final product = Product.fromJson(fullJson);

      expect(product.id, 1);
      expect(product.title, 'Essence Mascara');
      expect(product.description, 'A great mascara');
      expect(product.price, 9.99);
      expect(product.category, 'beauty');
      expect(product.brand, 'Essence');
      expect(product.stock, 5);
      expect(product.rating, 4.94);
      expect(product.discountPercentage, 7.17);
      expect(product.thumbnail, 'https://example.com/thumb.png');
      expect(product.images, hasLength(2));
    });

    test('handles missing optional fields', () {
      final product = Product.fromJson({
        'id': 2,
        'title': 'No extras',
        'price': 5.5,
      });

      expect(product.brand, isNull);
      expect(product.stock, isNull);
      expect(product.rating, isNull);
      expect(product.discountPercentage, isNull);
      expect(product.images, isEmpty);
      expect(product.description, '');
      expect(product.category, '');
      expect(product.thumbnail, '');
    });

    test('handles an empty map without throwing', () {
      final product = Product.fromJson({});

      expect(product.id, 0);
      expect(product.title, '');
      expect(product.price, 0.0);
    });

    test('converts an int price to double', () {
      final product = Product.fromJson({'id': 3, 'price': 10});

      expect(product.price, 10.0);
      expect(product.price, isA<double>());
    });

    test('ignores non-string values in images', () {
      final product = Product.fromJson({
        'id': 4,
        'images': ['a.png', 42, null],
      });

      expect(product.images, ['a.png']);
    });
  });

  group('Product.toJson / copyWith', () {
    test('toJson then fromJson keeps the data', () {
      final original = Product.fromJson(fullJson);
      final copy = Product.fromJson(original.toJson());

      expect(copy.id, original.id);
      expect(copy.title, original.title);
      expect(copy.price, original.price);
      expect(copy.brand, original.brand);
      expect(copy.images, original.images);
    });

    test('copyWith changes only the given fields', () {
      final original = Product.fromJson(fullJson);
      final changed = original.copyWith(title: 'New title', price: 20);

      expect(changed.title, 'New title');
      expect(changed.price, 20);
      expect(changed.id, original.id);
      expect(changed.category, original.category);
    });
  });

  group('ProductResponse.fromJson', () {
    test('parses products and pagination fields', () {
      final response = ProductResponse.fromJson({
        'products': [fullJson, fullJson],
        'total': 194,
        'skip': 20,
        'limit': 20,
      });

      expect(response.products, hasLength(2));
      expect(response.total, 194);
      expect(response.skip, 20);
      expect(response.limit, 20);
      expect(response.hasMore, isTrue);
    });

    test('hasMore is false on the last page', () {
      final response = ProductResponse.fromJson({
        'products': [fullJson, fullJson],
        'total': 194,
        'skip': 192,
        'limit': 20,
      });

      expect(response.hasMore, isFalse);
    });

    test('handles missing keys', () {
      final response = ProductResponse.fromJson({});

      expect(response.products, isEmpty);
      expect(response.total, 0);
      expect(response.skip, 0);
      expect(response.hasMore, isFalse);
    });

    test('skips items that are not objects', () {
      final response = ProductResponse.fromJson({
        'products': ['oops', fullJson, 42],
        'total': 1,
      });

      expect(response.products, hasLength(1));
    });
  });
}