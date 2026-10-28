import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../storage/token_storage.dart';


class SafeLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) debugPrint('--> ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('<-- ${response.statusCode} ${response.requestOptions.path}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '<-- ERROR ${err.response?.statusCode ?? err.type.name} '
            '${err.requestOptions.path}',
      );
    }
    handler.next(err);
  }
}

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.tokenStorage,
    required this.dio,
    required this.onSessionExpired,
  });

  final TokenStorage tokenStorage;
  final Dio dio;
  final VoidCallback onSessionExpired;

  Future<bool>? _refreshing;

  bool _isAuthEndpoint(String path) =>
      path == ApiConstants.login || path == ApiConstants.refresh;

  @override
  void onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    if (!_isAuthEndpoint(options.path)) {
      final token = await tokenStorage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    final isUnauthorized = err.response?.statusCode == 401;

    if (!isUnauthorized ||
        _isAuthEndpoint(request.path) ||
        request.extra['retried'] == true) {
      return handler.next(err);
    }

    _refreshing ??= _refreshToken().whenComplete(() => _refreshing = null);
    final refreshed = await _refreshing!;

    if (!refreshed) {
      onSessionExpired();
      return handler.next(err);
    }


    if (request.method != 'GET') return handler.next(err);

    try {
      request.extra['retried'] = true;
      request.headers.remove('Authorization');
      final response = await dio.fetch<dynamic>(request);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<bool> _refreshToken() async {
    final refreshToken = await tokenStorage.getRefreshToken();
    if (refreshToken == null) return false;

    try {

      final response = await Dio(BaseOptions(baseUrl: ApiConstants.baseUrl))
          .post<dynamic>(
        ApiConstants.refresh,
        data: {'refreshToken': refreshToken},
      );
      final data = response.data;
      if (data is Map && data['accessToken'] is String) {
        await tokenStorage.saveTokens(
          accessToken: data['accessToken'] as String,
          refreshToken: data['refreshToken'] as String?,
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}