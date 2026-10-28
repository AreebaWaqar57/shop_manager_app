import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shop_manager/core/network/api_exception.dart';
import 'package:shop_manager/features/products/providers/product_provider.dart';
import 'package:shop_manager/features/products/screens/products.dart';

import '../helpers/fakes.dart';

void main() {
  Widget buildApp(ProductProvider provider) {
    return ChangeNotifierProvider<ProductProvider>.value(
      value: provider,
      child: const MaterialApp(home: ProductsScreen()),
    );
  }

  testWidgets('shows a loading indicator while products load', (tester) async {
    final repo = FakeProductRepository(products: sampleProducts(3))
      ..gate = Completer<void>(); // the request never finishes
    final provider = ProductProvider(repo);
    addTearDown(provider.dispose);

    await tester.pumpWidget(buildApp(provider));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Laptop 1'), findsNothing);
  });

  testWidgets('renders the product list from mock data', (tester) async {
    final repo = FakeProductRepository(products: sampleProducts(3));
    final provider = ProductProvider(repo);
    addTearDown(provider.dispose);

    await tester.pumpWidget(buildApp(provider));
    await tester.pumpAndSettle();

    expect(find.text('Laptop 1'), findsOneWidget);
    expect(find.text('Phone 2'), findsOneWidget);
    expect(find.text('Laptop 3'), findsOneWidget);
    expect(find.text('laptops'), findsNWidgets(2)); // category on the cards
    expect(find.text(r'$11.00'), findsOneWidget); // price of product 1
    expect(find.text('Products (3)'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows the empty state when there are no products',
          (tester) async {
        final repo = FakeProductRepository(products: []);
        final provider = ProductProvider(repo);
        addTearDown(provider.dispose);

        await tester.pumpWidget(buildApp(provider));
        await tester.pumpAndSettle();

        expect(find.text('No products found.'), findsOneWidget);
      });

  testWidgets('shows the error state and Retry loads the products',
          (tester) async {
        final repo = FakeProductRepository(products: sampleProducts(3))
          ..readError = const ApiException(
            'No internet connection.',
            type: ApiErrorType.network,
          );
        final provider = ProductProvider(repo);
        addTearDown(provider.dispose);

        await tester.pumpWidget(buildApp(provider));
        await tester.pumpAndSettle();

        expect(find.text('No internet connection.'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);

        repo.readError = null; // the network is back
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        expect(find.text('No internet connection.'), findsNothing);
        expect(find.text('Laptop 1'), findsOneWidget);
      });

  testWidgets('shows the categories in the dropdown', (tester) async {
    final repo = FakeProductRepository(
      products: sampleProducts(3),
      categories: ['laptops', 'smartphones'],
    );
    final provider = ProductProvider(repo);
    addTearDown(provider.dispose);

    await tester.pumpWidget(buildApp(provider));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All categories'));
    await tester.pumpAndSettle();

    expect(find.text('Laptops'), findsOneWidget);
    expect(find.text('Smartphones'), findsOneWidget);
  });
}