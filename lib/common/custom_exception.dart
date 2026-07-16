import 'dart:async';

import 'package:dio/dio.dart';

class CustomException implements Exception {
  CustomException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'CustomException($statusCode): $message';
}

CustomException getCustomException(dynamic error) {
  if (error is CustomException) return error;

  if (error is DioException) {
    final status = error.response?.statusCode;
    final data = error.response?.data;

    String? message;
    if (data is Map) {
      message = (data['message'] ?? data['error'] ?? data['detail'])
          ?.toString();
    } else if (data is String && data.isNotEmpty) {
      message = data;
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return CustomException(
          'Connection timed out. Please try again.',
          statusCode: -1,
        );
      case DioExceptionType.connectionError:
        return CustomException('No internet connection.', statusCode: -1);
      default:
        return CustomException(
          message?.isNotEmpty == true
              ? message!
              : 'Something went wrong. Please try again.',
          statusCode: status,
        );
    }
  }

  if (error is TimeoutException) {
    return CustomException(
      'Request timed out. Please try again.',
      statusCode: -1,
    );
  }

  return CustomException(error?.toString() ?? 'Unexpected error occurred.');
}
