import 'dart:io';

import 'package:dio/dio.dart';

enum ApiErrorType {
  network,
  timeout,
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  server,
  cancelled,
  unexpectedResponse,
  unknown,
}

class ApiException implements Exception{

    const ApiException(
        this.message, {
      this.statusCode,
      this.type = ApiErrorType.unknown,
});

  final String message;
  final int? statusCode;
  final ApiErrorType type;


    bool get isNetworkError =>
        type == ApiErrorType.network || type == ApiErrorType.timeout;

    bool get isUnauthorized => type == ApiErrorType.unauthorized;
    factory ApiException.fromDioException(DioException e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.transformTimeout:
          return const ApiException(
            'The request timed out. Please try again.',
            type: ApiErrorType.timeout,
          );
        case DioExceptionType.connectionError:
          return const ApiException(
            'No internet connection. Please check your network.',
            type: ApiErrorType.network,
          );
        case DioExceptionType.badCertificate:
          return const ApiException(
            'A secure connection could not be established',
            type: ApiErrorType.network,
          );
        case DioExceptionType.cancel:
          return const ApiException(
            'The request was cancelled',
            type: ApiErrorType.cancelled,
          );
        case DioExceptionType.badResponse:
          return ApiException._fromStatus(
            e.response?.statusCode,
            e.response?.data,
          );
        case DioExceptionType.unknown:
          if (e.error is SocketException) {
            return const ApiException(
              'No internet connection. Please check your network.',
              type: ApiErrorType.network,
            );
          }
          return const ApiException(
              'Something went wrong.Please try again.',
              type: ApiErrorType.unknown,
          );
      }
    }
    factory ApiException._fromStatus(int? status,dynamic data) {

      final serverMessage =
      (data is Map && data['message'] is String) ? data['message'] as String : null;

       switch (status) {
         case 400:
           return ApiException(
             serverMessage ?? 'Invalid request.' ,
             statusCode: status,
             type: ApiErrorType.badRequest,
           );
         case 401:
           return ApiException(
             serverMessage ?? 'Authentication failed.Please login again.' ,
             statusCode: status,
             type: ApiErrorType.unauthorized,
           );
         case 403:
           return ApiException(
             serverMessage ?? 'You do not have permissions to perform this action.' ,
             statusCode: status,
             type: ApiErrorType.forbidden,
           );
         case 404:
           return ApiException(
             serverMessage ?? 'The requested resources was not found.' ,
             statusCode: status,
             type: ApiErrorType.notFound,
           );
         default:
           if (status != null && status >= 500) {
             return ApiException(
               'Server error. Please try again later.',
               statusCode: status,
               type: ApiErrorType.server,
             );
           }
           return ApiException(
             serverMessage ?? 'Unexpected error (code: ${status ?? 'unknown'}).',
             statusCode: status,
           );
       }
    }
    @override
    String toString() => 'ApiException($statusCode): $message';
}