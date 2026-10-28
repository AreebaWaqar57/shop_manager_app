import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/network/api_client.dart';
import 'core/network/api_interceptors.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/repositories/auth_repository.dart';
import 'features/products/providers/product_provider.dart';
import 'features/products/repositories/product_repository.dart';

class ShopManagerApp extends StatefulWidget {
  const ShopManagerApp({super.key});

  @override
  State<ShopManagerApp> createState() => _ShopManagerAppState();
}

class _ShopManagerAppState extends State<ShopManagerApp> {
  late final AuthProvider _authProvider;
  late final ProductProvider _productProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    final tokenStorage = TokenStorage();
    final apiClient = ApiClient();

    _authProvider = AuthProvider(AuthRepository(apiClient), tokenStorage);
    _productProvider = ProductProvider(ProductRepository(apiClient));

    apiClient.dio.interceptors.addAll([
      SafeLogInterceptor(),
      AuthInterceptor(
        tokenStorage: tokenStorage,
        dio: apiClient.dio,
        onSessionExpired: _authProvider.handleSessionExpired,
      ),
    ]);

    // On logout, clear the protected product data from memory.
    _authProvider.onLoggedOut = _productProvider.clear;

    _router = AppRouter.create(_authProvider);
    _authProvider.initSession();
  }

  @override
  void dispose() {
    _router.dispose();
    _authProvider.dispose();
    _productProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<ProductProvider>.value(value: _productProvider),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'ShopManager',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        routerConfig: _router,
      ),
    );
  }
}