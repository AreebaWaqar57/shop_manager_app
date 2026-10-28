import 'dart:async';

import 'package:shop_manager/core/constants/api_constants.dart';
import 'package:shop_manager/core/network/api_client.dart';
import 'package:shop_manager/core/network/api_exception.dart';
import 'package:shop_manager/core/storage/token_storage.dart';
import 'package:shop_manager/features/auth/models/user_model.dart';
import 'package:shop_manager/features/auth/repositories/auth_repository.dart';
import 'package:shop_manager/features/products/models/product_model.dart';
import 'package:shop_manager/features/products/models/product_response.dart';
import 'package:shop_manager/features/products/repositories/product_repository.dart';

/// Mock data: even ids are phones, odd ids are laptops.
List<Product> sampleProducts(int count) {
  return List.generate(count, (i) {
    final id = i + 1;
    return Product(
      id: id,
      title: id.isEven ? 'Phone $id' : 'Laptop $id',
      description: 'Description $id',
      price: 10.0 + id,
      category: id.isEven ? 'smartphones' : 'laptops',
      thumbnail: '', // empty: tests never touch the network
    );
  });
}

/// In-memory repository, so tests are deterministic and run offline.
class FakeProductRepository extends ProductRepository {
  FakeProductRepository({
    List<Product> products = const [],
    this.categories = const [],
  })  : products = List.of(products),
        super(ApiClient());

  List<Product> products;
  List<String> categories;

  ApiException? readError;
  ApiException? writeError;
  Completer<void>? gate; // holds read requests until completed
  Completer<void>? writeGate; // holds write requests until completed

  int getProductsCalls = 0;
  int addCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;
  String? lastQuery;
  String? lastCategory;

  Future<void> _checkRead() async {
    if (gate != null) await gate!.future;
    if (readError != null) throw readError!;
  }

  Future<void> _checkWrite() async {
    if (writeGate != null) await writeGate!.future;
    if (writeError != null) throw writeError!;
  }

  ProductResponse _page(List<Product> list, int limit, int skip) {
    return ProductResponse(
      products: list.skip(skip).take(limit).toList(),
      total: list.length,
      skip: skip,
      limit: limit,
    );
  }

  @override
  Future<ProductResponse> getProducts({
    int limit = ApiConstants.defaultLimit,
    int skip = 0,
  }) async {
    getProductsCalls++;
    await _checkRead();
    return _page(products, limit, skip);
  }

  @override
  Future<ProductResponse> searchProducts(
      String query, {
        int limit = ApiConstants.defaultLimit,
        int skip = 0,
      }) async {
    lastQuery = query;
    await _checkRead();
    final matches = products
        .where((p) => p.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return _page(matches, limit, skip);
  }

  @override
  Future<ProductResponse> getProductsByCategory(
      String category, {
        int limit = ApiConstants.defaultLimit,
        int skip = 0,
      }) async {
    lastCategory = category;
    await _checkRead();
    final matches = products.where((p) => p.category == category).toList();
    return _page(matches, limit, skip);
  }

  @override
  Future<List<String>> getCategories() async => categories;

  @override
  Future<Product> getProductById(int id) async {
    await _checkRead();
    return products.firstWhere(
          (p) => p.id == id,
      orElse: () => throw const ApiException(
        'The requested resource was not found.',
        statusCode: 404,
        type: ApiErrorType.notFound,
      ),
    );
  }

  @override
  Future<Product> addProduct(Product product) async {
    addCalls++;
    await _checkWrite();
    return product.copyWith(id: 195); // DummyJSON always answers with 195
  }

  @override
  Future<Product> updateProduct(Product product) async {
    updateCalls++;
    await _checkWrite();
    return product;
  }

  @override
  Future<void> deleteProduct(int id) async {
    deleteCalls++;
    await _checkWrite();
  }
}

class FakeTokenStorage extends TokenStorage {
  String? accessToken;
  String? refreshToken;

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
  }
}

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository() : super(ApiClient());

  ApiException? loginError;
  Completer<void>? gate;
  int loginCalls = 0;

  static const user = User(id: 1, username: 'demo', firstName: 'Demo');

  @override
  Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    loginCalls++;
    if (gate != null) await gate!.future;
    if (loginError != null) throw loginError!;
    return const LoginResult(
      accessToken: 'test-token',
      refreshToken: 'test-refresh',
      user: user,
    );
  }

  @override
  Future<User> getCurrentUser() async => user;
}