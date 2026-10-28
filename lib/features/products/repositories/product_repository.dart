import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/product_model.dart';
import '../models/product_response.dart';

class ProductRepository {

  ProductRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<ProductResponse> getProducts({
    int limit = ApiConstants.defaultLimit,
    int skip = 0,
}) async {
    final json = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.products,
      queryParameters: {'limit': limit, 'skip': skip},
    );
    return _parse(() => ProductResponse.fromJson(json));
  }

  Future<ProductResponse> searchProducts(
      String query, {
        int limit = ApiConstants.defaultLimit,
        int skip = 0,
      }) async {
    final json = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.productSearch,
      queryParameters: {'q': query, 'limit': limit, 'skip': skip},
    );
    return _parse(() => ProductResponse.fromJson(json));
  }

  Future<ProductResponse> getProductsByCategory(
      String category, {
        int limit = ApiConstants.defaultLimit,
        int skip = 0,
      }) async {
    final json = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.productsByCategory(category),
      queryParameters: {'limit': limit, 'skip': skip},
    );
    return _parse(() => ProductResponse.fromJson(json));
  }

  Future<List<String>> getCategories() async {
    final list = await _apiClient.get<List<dynamic>>(
      ApiConstants.productCategories,
    );

    return _parse(
          () => list
          .map((item) => item is Map ? item['slug'].toString() : item.toString())
          .toList(),
    );
  }

  Future<Product> getProductById(int id) async {
    final json = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.productById(id),
    );
    return _parse(() => Product.fromJson(json));
  }

  Future<Product> addProduct(Product product) async {
    final json = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.productAdd,
      data: _toBody(product),
    );
    return _parse(() => Product.fromJson(json));
  }

  Future<Product> updateProduct(Product product) async {
    final json = await _apiClient.patch<Map<String, dynamic>>(
      ApiConstants.productById(product.id),
      data: _toBody(product),
    );
    return _parse(() => Product.fromJson(json));
  }

  Future<void> deleteProduct(int id) async {
    await _apiClient.delete<Map<String, dynamic>>(
      ApiConstants.productById(id),
    );
  }

  Map<String, dynamic> _toBody(Product product) {
    return product.toJson()
      ..remove('id')
      ..removeWhere((key, value) => value == null);
  }

  T _parse<T>(T Function() parser) {
    try {
      return parser();
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        'Unexpected response format.',
        type: ApiErrorType.unexpectedResponse,
      );
    }
  }
}