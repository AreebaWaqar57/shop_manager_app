import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/products/models/product_model.dart';
import '../../features/products/screens/product_detail.dart';
import '../../features/products/screens/product_form.dart';
import '../../features/products/screens/products.dart';
import '../../features/profile/screens/profile_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = 'splash';
  static const login = 'login';
  static const products = 'products';
  static const productNew = 'productNew';
  static const productDetails = 'productDetails';
  static const productEdit = 'productEdit';
  static const profile = 'profile';
}

class AppRouter {
  AppRouter._();

  static GoRouter create(AuthProvider auth) {
    return GoRouter(
      initialLocation: '/splash',

      refreshListenable: auth,
      redirect: (context, state) {
        final location = state.matchedLocation;


        if (auth.status == AuthStatus.unknown) {
          return location == '/splash' ? null : '/splash';
        }


        if (auth.status == AuthStatus.unauthenticated) {
          return location == '/login' ? null : '/login';
        }


        if (location == '/splash' || location == '/login') return '/products';
        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          name: AppRoutes.splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          name: AppRoutes.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/products',
          name: AppRoutes.products,
          builder: (context, state) => const ProductsScreen(),
          routes: [

            GoRoute(
              path: 'new',
              name: AppRoutes.productNew,
              builder: (context, state) => const ProductFormScreen(),
            ),
            GoRoute(
              path: ':id',
              name: AppRoutes.productDetails,
              builder: (context, state) => ProductDetailsScreen(
                productId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
              ),
              routes: [
                GoRoute(
                  path: 'edit',
                  name: AppRoutes.productEdit,

                  builder: (context, state) => ProductFormScreen(
                    product: state.extra is Product
                        ? state.extra as Product
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/profile',
          name: AppRoutes.profile,
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    );
  }
}