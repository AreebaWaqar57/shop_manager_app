import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import 'api_exception.dart';

class ApiClient {

  ApiClient({Dio? dio}) : _dio = dio ?? _createDio();

  final Dio _dio;

  static Dio _createDio() {
    return Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      sendTimeout: ApiConstants.sendTimeout,
      responseType: ResponseType.json,
      contentType: Headers.jsonContentType,
      headers: const {'Accept': 'application/json'},
    ),
    );
  }

  Dio get dio => _dio;

  Future<T> get<T> (
      String path, {
      Map<String, dynamic>? queryParameters,
        Map<String, dynamic>? headers,
  })  {
    return _send<T>(
        () => _dio.get<dynamic> (
          path,
          queryParameters: queryParameters,
          options: Options(headers: headers),
        ),
    );
  }

  Future<T> post<T> (
      String path, {
        Object? data,
        Map<String, dynamic>? headers,
  }) {
    return _send<T>(
          () =>
          _dio.post<dynamic>(
            path,
            data: data,
            options: Options(headers: headers),
          ),
    );
  }

  Future<T> patch<T>(
    String path, {
      Object? data,
        Map<String,dynamic>? headers,
  })  {
    return _send<T>(
        () =>
            _dio.patch<dynamic>(
              path,
              data: data,
              options: Options(headers: headers),
            ),
    );
  }

  Future<T> delete<T>(
      String path, {
        Map<String, dynamic>? headers,
  }) {
    return _send<T>(
        () =>
            _dio.delete<dynamic>(
              path,
              options: Options(headers: headers),
            ),

    );
  }
  Future<T> _send<T>(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      final data = response.data;
      if (data is T) return data;
      throw ApiException(
        'Unexpected response format.',
        statusCode: response.statusCode,
        type: ApiErrorType.unexpectedResponse,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}