class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://dummyjson.com';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);

  static const int defaultLimit = 20;

  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String refresh = '/auth/refresh';

  static const String products = '/products';
  static const String productSearch = '/products/search';
  static const String productCategories = '/products/categories';
  static const String productAdd = '/products/add';

  static String productById(int id) => '/products/$id';
  static String productsByCategory(String category) =>
      '/products/category/$category';

}