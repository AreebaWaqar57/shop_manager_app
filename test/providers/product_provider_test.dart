import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shop_manager/core/network/api_exception.dart';
import 'package:shop_manager/features/products/models/product_model.dart';
import 'package:shop_manager/features/products/providers/product_provider.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeProductRepository repo;
  late ProductProvider provider;

  const noInternet = ApiException(
    'No internet connection.',
    type: ApiErrorType.network,
  );

  Product newDraft() => const Product(
    id: 0,
    title: 'New item',
    description: 'Description',
    price: 5,
    category: 'misc',
    thumbnail: '',
  );

  setUp(() {
    repo = FakeProductRepository(
      products: sampleProducts(45),
      categories: ['laptops', 'smartphones'],
    );
    provider = ProductProvider(repo);
  });

  tearDown(() => provider.dispose());

  group('loading products', () {
    test('starts empty and idle', () {
      expect(provider.products, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.hasLoaded, isFalse);
      expect(provider.errorMessage, isEmpty);
    });

    test('success: loading goes true then false and products are stored',
            () async {
          final loadingStates = <bool>[];
          provider.addListener(() => loadingStates.add(provider.isLoading));

          await provider.fetchProducts();

          expect(loadingStates, [true, false]);
          expect(provider.products, hasLength(20));
          expect(provider.total, 45);
          expect(provider.hasMore, isTrue);
          expect(provider.hasLoaded, isTrue);
          expect(provider.errorMessage, isEmpty);
        });

    test('failure: error message is stored and nothing is loaded', () async {
      repo.readError = noInternet;

      await provider.fetchProducts();

      expect(provider.errorMessage, 'No internet connection.');
      expect(provider.products, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.hasLoaded, isTrue);
    });

    test('retry after a failure clears the error', () async {
      repo.readError = noInternet;
      await provider.fetchProducts();

      repo.readError = null;
      await provider.fetchProducts();

      expect(provider.errorMessage, isEmpty);
      expect(provider.products, hasLength(20));
    });

    test('empty result is not an error', () async {
      repo.products = [];

      await provider.fetchProducts();

      expect(provider.products, isEmpty);
      expect(provider.errorMessage, isEmpty);
      expect(provider.hasLoaded, isTrue);
    });

    test('fetchCategories stores the categories', () async {
      await provider.fetchCategories();

      expect(provider.categories, ['laptops', 'smartphones']);
    });
  });

  group('pagination', () {
    test('loadMore appends pages until everything is loaded', () async {
      await provider.fetchProducts();
      expect(provider.products, hasLength(20));

      await provider.loadMore();
      expect(provider.products, hasLength(40));
      expect(provider.hasMore, isTrue);

      await provider.loadMore();
      expect(provider.products, hasLength(45));
      expect(provider.hasMore, isFalse);
    });

    test('loadMore does nothing when there are no more products', () async {
      await provider.fetchProducts();
      await provider.loadMore();
      await provider.loadMore();
      final callsBefore = repo.getProductsCalls;

      await provider.loadMore();

      expect(repo.getProductsCalls, callsBefore);
      expect(provider.products, hasLength(45));
    });

    test('duplicate pagination requests are ignored', () async {
      await provider.fetchProducts();
      repo.gate = Completer<void>();

      final first = provider.loadMore();
      final second = provider.loadMore();
      repo.gate!.complete();
      await Future.wait([first, second]);

      expect(repo.getProductsCalls, 2); // first page + one next page
      expect(provider.products, hasLength(40));
    });

    test('a failed loadMore keeps the loaded products', () async {
      await provider.fetchProducts();
      repo.readError = noInternet;

      await provider.loadMore();

      expect(provider.products, hasLength(20));
      expect(provider.errorMessage, 'No internet connection.');
      expect(provider.isLoadingMore, isFalse);
    });
  });

  group('search and category filter', () {
    test('search uses the query and only returns matches', () async {
      await provider.search('phone');

      expect(repo.lastQuery, 'phone');
      expect(
        provider.products.every((p) => p.title.toLowerCase().contains('phone')),
        isTrue,
      );
      expect(provider.total, 22);
    });

    test('search with no matches is empty, not an error', () async {
      await provider.search('zzz');

      expect(provider.products, isEmpty);
      expect(provider.errorMessage, isEmpty);
    });

    test('a new search starts again from the first page', () async {
      await provider.fetchProducts();
      await provider.loadMore();
      expect(provider.products, hasLength(40));

      await provider.search('phone');
      expect(provider.products, hasLength(20));

      await provider.loadMore();
      expect(provider.products, hasLength(22));
      expect(provider.hasMore, isFalse);
    });

    test('selectCategory only returns that category', () async {
      await provider.selectCategory('laptops');

      expect(provider.selectedCategory, 'laptops');
      expect(repo.lastCategory, 'laptops');
      expect(provider.products.every((p) => p.category == 'laptops'), isTrue);
      expect(provider.total, 23);
    });

    test('selecting "All" (null) loads every product again', () async {
      await provider.selectCategory('laptops');

      await provider.selectCategory(null);

      expect(provider.selectedCategory, isNull);
      expect(provider.total, 45);
    });

    test('searching clears the selected category', () async {
      await provider.selectCategory('laptops');

      await provider.search('phone');

      expect(provider.selectedCategory, isNull);
    });
  });

  group('product details', () {
    test('fetchProductDetails stores the product', () async {
      await provider.fetchProductDetails(3);

      expect(provider.selectedProduct?.id, 3);
      expect(provider.detailsError, isEmpty);
      expect(provider.isDetailsLoading, isFalse);
    });

    test('fetchProductDetails stores an error when not found', () async {
      await provider.fetchProductDetails(999);

      expect(provider.selectedProduct, isNull);
      expect(provider.detailsError, isNotEmpty);
    });
  });

  group('create, update, delete', () {
    test('createProduct adds the product at the top and updates the total',
            () async {
          await provider.fetchProducts();

          final ok = await provider.createProduct(newDraft());

          expect(ok, isTrue);
          expect(provider.products.first.title, 'New item');
          expect(provider.products, hasLength(21));
          expect(provider.total, 46);
          expect(repo.addCalls, 1);
        });

    test('created products get unique ids', () async {
      await provider.fetchProducts();

      await provider.createProduct(newDraft());
      await provider.createProduct(newDraft());

      final ids = provider.products.take(2).map((p) => p.id).toSet();
      expect(ids, hasLength(2));
    });

    test('updateProduct changes the list and the details', () async {
      await provider.fetchProducts();
      final edited = provider.products.first.copyWith(title: 'Edited title');

      final ok = await provider.updateProduct(edited);
      await provider.fetchProductDetails(edited.id);

      expect(ok, isTrue);
      expect(provider.products.first.title, 'Edited title');
      expect(provider.selectedProduct?.title, 'Edited title');
      expect(repo.updateCalls, 1);
    });

    test('updating a created product does not call the API', () async {
      await provider.fetchProducts();
      await provider.createProduct(newDraft());
      final created = provider.products.first;

      final ok = await provider.updateProduct(created.copyWith(title: 'Changed'));

      expect(ok, isTrue);
      expect(provider.products.first.title, 'Changed');
      expect(repo.updateCalls, 0);
    });

    test('deleteProduct removes the product and lowers the total', () async {
      await provider.fetchProducts();

      final ok = await provider.deleteProduct(1);

      expect(ok, isTrue);
      expect(provider.products.any((p) => p.id == 1), isFalse);
      expect(provider.total, 44);
      expect(repo.deleteCalls, 1);
    });

    test('deleting a created product does not call the API', () async {
      await provider.fetchProducts();
      await provider.createProduct(newDraft());
      final created = provider.products.first;

      await provider.deleteProduct(created.id);

      expect(provider.products.any((p) => p.id == created.id), isFalse);
      expect(repo.deleteCalls, 0);
    });

    test('loadMore stays correct after local changes', () async {
      await provider.fetchProducts();
      await provider.deleteProduct(1);

      await provider.loadMore();

      final ids = provider.products.map((p) => p.id).toList();
      expect(ids.toSet(), hasLength(ids.length)); // no duplicates
      expect(ids, contains(21)); // first product of the next page
      expect(ids, hasLength(39));
    });

    test('a failed write keeps the list and exposes the error', () async {
      await provider.fetchProducts();
      repo.writeError = const ApiException(
        'Server error. Please try again later.',
        statusCode: 500,
        type: ApiErrorType.server,
      );

      final created = await provider.createProduct(newDraft());
      final deleted = await provider.deleteProduct(1);

      expect(created, isFalse);
      expect(deleted, isFalse);
      expect(provider.actionError, 'Server error. Please try again later.');
      expect(provider.products, hasLength(20));
      expect(provider.products.any((p) => p.id == 1), isTrue);
      expect(provider.isSaving, isFalse);
    });

    test('a second save while one is running is ignored', () async {
      await provider.fetchProducts();
      repo.writeGate = Completer<void>();

      final first = provider.createProduct(newDraft());
      final second = provider.createProduct(newDraft());
      expect(provider.isSaving, isTrue);
      repo.writeGate!.complete();

      expect(await first, isTrue);
      expect(await second, isFalse);
      expect(repo.addCalls, 1);
    });
  });

  group('lifecycle', () {
    test('clear() removes all protected data', () async {
      await provider.fetchProducts();
      await provider.fetchCategories();
      await provider.createProduct(newDraft());

      provider.clear();

      expect(provider.products, isEmpty);
      expect(provider.categories, isEmpty);
      expect(provider.total, 0);
      expect(provider.hasLoaded, isFalse);
      expect(provider.selectedProduct, isNull);
    });

    test('does not notify listeners after it is disposed', () async {
      final gate = Completer<void>();
      final slowRepo = FakeProductRepository(products: sampleProducts(3))
        ..gate = gate;
      final other = ProductProvider(slowRepo);

      final future = other.fetchProducts();
      other.dispose();
      gate.complete();

      await expectLater(future, completes);
    });
  });
}