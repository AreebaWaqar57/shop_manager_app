import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../models/product_model.dart';
import '../models/product_response.dart';
import '../repositories/product_repository.dart';

class ProductProvider extends ChangeNotifier {
  ProductProvider(this._repository);

  final ProductRepository _repository;

  // List state
  List<Product> _products = [];
  List<String> _categories = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasLoaded = false;
  String _errorMessage = '';
  int _total = 0;
  String _query = '';
  String? _selectedCategory;
  int _requestId = 0;

  // Details state
  Product? _selectedProduct;
  bool _isDetailsLoading = false;
  String _detailsError = '';

  bool _isSaving = false;
  String _actionError = '';

  final Map<int, Product> _localChanges = {};
  final Set<int> _createdIds = {};
  int _localDelta = 0;
  int _lastCreatedId = 0;

  bool _disposed = false;

  List<Product> get products => _products;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasLoaded => _hasLoaded;
  String get errorMessage => _errorMessage;
  int get total => _total + _localDelta;
  String? get selectedCategory => _selectedCategory;
  bool get hasMore => _products.length < total;

  Product? get selectedProduct => _selectedProduct;
  bool get isDetailsLoading => _isDetailsLoading;
  String get detailsError => _detailsError;

  bool get isSaving => _isSaving;
  String get actionError => _actionError;


  Future<ProductResponse> _fetchPage(int skip) {
    if (_query.isNotEmpty) {
      return _repository.searchProducts(_query, skip: skip);
    }
    if (_selectedCategory != null) {
      return _repository.getProductsByCategory(_selectedCategory!, skip: skip);
    }
    return _repository.getProducts(skip: skip);
  }


  Future<void> fetchProducts() async {
    final requestId = ++_requestId;
    _isLoading = true;
    _isLoadingMore = false;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _fetchPage(0);
      if (requestId != _requestId) return;

      _products = response.products;
      _total = response.total;
      _localDelta = 0;

    } on ApiException catch (e) {
      if (requestId != _requestId) return;
      _errorMessage = e.message;
    } catch (_) {
      if (requestId != _requestId) return;
      _errorMessage = 'Something went wrong. Please try again.';
    }

    _isLoading = false;
    _hasLoaded = true;
    notifyListeners();
  }


  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !hasMore) return;

    final requestId = _requestId;
    _isLoadingMore = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _fetchPage(_products.length - _localDelta);
      if (requestId != _requestId) return;
      _products = [..._products, ...response.products];

      _total = response.products.isEmpty
          ? _products.length - _localDelta
          : response.total;

    } on ApiException catch (e) {
      if (requestId != _requestId) return;
      _errorMessage = e.message;
    } catch (_) {
      if (requestId != _requestId) return;
      _errorMessage = 'Something went wrong. Please try again.';
    }

    _isLoadingMore = false;
    notifyListeners();
  }


  Future<void> search(String query) {
    _query = query.trim();
    _selectedCategory = null;
    _products = [];
    _total = 0;
    return fetchProducts();
  }


  Future<void> selectCategory(String? category) {
    _selectedCategory = category;
    _query = '';
    _products = [];
    _total = 0;
    return fetchProducts();
  }

  Future<void> fetchCategories() async {
    try {
      _categories = await _repository.getCategories();
      notifyListeners();
    } catch (_) {

    }
  }

  Future<void> fetchProductDetails(int id) async {
    _detailsError = '';

    final local = _localChanges[id];
    if (local != null) {
      _selectedProduct = local;
      _isDetailsLoading = false;
      notifyListeners();
      return;
    }

    _selectedProduct = null;
    _isDetailsLoading = true;
    notifyListeners();

    try {
      _selectedProduct = await _repository.getProductById(id);
    } on ApiException catch (e) {
      _detailsError = e.message;
    } catch (_) {
      _detailsError = 'Something went wrong. Please try again.';
    }

    _isDetailsLoading = false;
    notifyListeners();
  }

  void clear() {
    _requestId++;
    _products = [];
    _categories = [];
    _isLoading = false;
    _isLoadingMore = false;
    _hasLoaded = false;
    _errorMessage = '';
    _total = 0;
    _localDelta = 0;
    _query = '';
    _selectedCategory = null;
    _selectedProduct = null;
    _isDetailsLoading = false;
    _detailsError = '';
    notifyListeners();
  }

  Future<bool> createProduct(Product draft) {
    return _runWrite(() async {
      final created = await _repository.addProduct(draft);


      final newId = created.id > _lastCreatedId ? created.id : _lastCreatedId + 1;
      _lastCreatedId = newId;

      final product = draft.copyWith(id: newId);
      _products = [product, ..._products];
      _localChanges[newId] = product;
      _createdIds.add(newId);
      _localDelta++;
    });
  }

  Future<bool> updateProduct(Product product) {
    return _runWrite(() async {

      if (!_createdIds.contains(product.id)) {
        await _repository.updateProduct(product);
      }
      _products =
          _products.map((p) => p.id == product.id ? product : p).toList();
      _localChanges[product.id] = product;
      if (_selectedProduct?.id == product.id) _selectedProduct = product;
    });
  }

  Future<bool> deleteProduct(int id) {
    return _runWrite(() async {
      if (!_createdIds.contains(id)) {
        await _repository.deleteProduct(id);
      }
      _products = _products.where((p) => p.id != id).toList();
      _localChanges.remove(id);
      _createdIds.remove(id);
      _localDelta--;
      if (_selectedProduct?.id == id) _selectedProduct = null;
    });
  }

  Future<bool> _runWrite(Future<void> Function() action) async {
    if (_isSaving) return false;

    _isSaving = true;
    _actionError = '';
    notifyListeners();

    try {
      await action();
      _isSaving = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _actionError = e.message;
    } catch (_) {
      _actionError = 'Something went wrong. Please try again.';
    }

    _isSaving = false;
    notifyListeners();
    return false;
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}