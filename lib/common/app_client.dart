import 'dart:convert';

import 'package:doc_genie/common/logging_interceptor.dart';
import 'package:doc_genie/config/app_config.dart';
import 'package:doc_genie/constants/api_constants.dart';
import 'package:doc_genie/constants/enum_const.dart';
import 'package:doc_genie/services/secure_helper.dart';
import 'package:doc_genie/utils/app_logger.dart';
import 'package:doc_genie/utils/navigator_utils.dart';
import 'package:doc_genie/utils/snackbar_utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AppClient {
  AppClient._() {
    final baseOptions = BaseOptions(
      connectTimeout: AppConfig.timeout,
      receiveTimeout: AppConfig.timeout,
      sendTimeout: AppConfig.timeout,
    );
    _dio = Dio(baseOptions);
    _refreshDio = Dio(baseOptions);

    if (kDebugMode) {
      _dio.interceptors.add(LoggingInterceptor());
    }
    _dio.interceptors.add(_authInterceptor());
  }

  static final AppClient instance = AppClient._();

  late final Dio _dio;
  late final Dio _refreshDio;

  static String token = '';
  static String refresh = '';

  Future<String?>? _refreshFuture;

  Future<void> init() async {
    token = await SecureHelper.instance.getAccessToken() ?? '';
    refresh = await SecureHelper.instance.getRefreshToken() ?? '';
  }

  Map<String, dynamic> get _plainHeaders => {
    'Content-Type': 'application/json',
    'Accept': '*/*',
  };

  Map<String, dynamic> get _bearerHeaders => {
    'Content-Type': 'application/json',
    'Accept': '*/*',
    'Authorization': 'Bearer $token',
  };

  Map<String, dynamic> get _multipartBearerHeaders => {
    'Content-Type': 'multipart/form-data',
    'Accept': '*/*',
    'Authorization': 'Bearer $token',
  };

  Future<Response> request({
    required RequestType requestType,
    required String url,
    dynamic parameter,
    Map<String, dynamic>? queryParameters,
  }) {
    switch (requestType) {
      case RequestType.get:
        return _dio.get(
          url,
          queryParameters: queryParameters,
          options: Options(headers: _plainHeaders),
        );
      case RequestType.getWithToken:
        return _dio.get(
          url,
          queryParameters: queryParameters,
          options: Options(headers: _bearerHeaders),
        );
      case RequestType.post:
        return _dio.post(
          url,
          data: jsonEncode(parameter),
          queryParameters: queryParameters,
          options: Options(headers: _plainHeaders),
        );
      case RequestType.postWithToken:
        return _dio.post(
          url,
          data: jsonEncode(parameter),
          queryParameters: queryParameters,
          options: Options(headers: _bearerHeaders),
        );
      case RequestType.postMultiPartWithToken:
        return _dio.post(
          url,
          data: parameter,
          queryParameters: queryParameters,
          options: Options(headers: _multipartBearerHeaders),
        );
      case RequestType.putWithToken:
        return _dio.put(
          url,
          data: jsonEncode(parameter),
          queryParameters: queryParameters,
          options: Options(headers: _bearerHeaders),
        );
      case RequestType.patchWithToken:
        return _dio.patch(
          url,
          data: jsonEncode(parameter),
          queryParameters: queryParameters,
          options: Options(headers: _bearerHeaders),
        );
      case RequestType.deleteWithToken:
        return _dio.delete(
          url,
          data: parameter == null ? null : jsonEncode(parameter),
          queryParameters: queryParameters,
          options: Options(headers: _bearerHeaders),
        );
    }
  }

  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onError: (DioException error, handler) async {
        final status = error.response?.statusCode;
        final path = error.requestOptions.path.toLowerCase();
        final isAuthPath =
            path.contains('login') ||
            path.contains('otp') ||
            path.contains('refresh');

        final alreadyRetried = error.requestOptions.extra['__retried'] == true;
        if (status != 401 || isAuthPath || alreadyRetried) {
          return handler.next(error);
        }

        final newToken = await _refreshTokenIfNeeded();
        if (newToken != null) {
          try {
            final response = await _retry(error.requestOptions, newToken);
            return handler.resolve(response);
          } catch (_) {}
        }

        await _forceLogout();
        return handler.next(error);
      },
    );
  }

  Future<String?> _refreshTokenIfNeeded() {
    _refreshFuture ??= _doRefresh().whenComplete(() => _refreshFuture = null);
    return _refreshFuture!;
  }

  Future<String?> _doRefresh() async {
    try {
      if (refresh.isEmpty) {
        refresh = await SecureHelper.instance.getRefreshToken() ?? '';
      }
      if (refresh.isEmpty) return null;

      final res = await _refreshDio.post(
        ApiConstants.refreshToken,
        data: jsonEncode({'refreshToken': refresh}),
        options: Options(headers: _plainHeaders),
      );

      final body = res.data;
      final data = (body is Map && body['data'] is Map) ? body['data'] : body;
      final newAccess = (data['accessToken'] ?? data['token'] ?? '').toString();
      final newRefresh = (data['refreshToken'] ?? refresh).toString();
      if (newAccess.isEmpty) return null;

      token = newAccess;
      refresh = newRefresh;
      await SecureHelper.instance.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );
      AppLogger.i('Access token refreshed');
      return newAccess;
    } catch (e, s) {
      AppLogger.e('Token refresh failed', error: e, stackTrace: s);
      return null;
    }
  }

  Future<Response> _retry(RequestOptions options, String newToken) {
    final headers = Map<String, dynamic>.from(options.headers)
      ..['Authorization'] = 'Bearer $newToken';
    return _dio.fetch(
      options.copyWith(
        headers: headers,
        extra: {...options.extra, '__retried': true},
      ),
    );
  }

  Future<void> _forceLogout() async {
    token = '';
    refresh = '';
    await SecureHelper.instance.clearAll();
    SnackBarUtils.show(
      'Session expired. Please log in again.',
      type: SnackType.error,
    );
    final ctx = navigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      // Navigate to login — imported lazily to avoid circular import
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (r) => false);
    }
  }
}
