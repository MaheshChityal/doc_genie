import 'dart:convert';

import 'package:doc_genie/common/logging_interceptor.dart';
import 'package:doc_genie/config/app_config.dart';
import 'package:doc_genie/constants/api_constants.dart';
import 'package:doc_genie/constants/enum_const.dart';
import 'package:doc_genie/services/secure_helper.dart';
import 'package:doc_genie/services/session_manager.dart';
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

  /// Mirrors AuthRepository.useMockAuth — simulates the refresh endpoint so the
  /// session/extend flow works without a backend. Set to false with real APIs.
  static const bool mockAuth = true;

  late final Dio _dio;
  late final Dio _refreshDio;

  static String token = '';
  static String refresh = '';

  Future<String?>? _refreshFuture;

  /// Calls the refresh endpoint (single-flight). Returns true on success.
  /// Used by the session-expiry popup's "Stay Signed In" action.
  Future<bool> refreshSession() async {
    final newToken = await _refreshTokenIfNeeded();
    return newToken != null;
  }

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
  Map<String, dynamic> get _multipartPlainHeaders => {
    'Content-Type': 'multipart/form-data',
    'Accept': '*/*',
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
      case RequestType.postMultiPart:
        return _dio.post(
          url,
          data: parameter,
          queryParameters: queryParameters,
          options: Options(headers: _multipartPlainHeaders),
        );
      case RequestType.putWithToken:
        return _dio.put(
          url,
          data: jsonEncode(parameter),
          queryParameters: queryParameters,
          options: Options(headers: _bearerHeaders),
        );
      case RequestType.put:
        return _dio.put(
          url,
          data: jsonEncode(parameter),
          queryParameters: queryParameters,
          options: Options(headers: _plainHeaders),
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

        // Refresh failed (incl. 401 on the refresh endpoint) → sign out.
        await logout(expired: true);
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

      if (mockAuth) {
        // Simulate a successful refresh so the session flow is testable.
        await Future<void>.delayed(const Duration(milliseconds: 400));
        final newAccess =
            'mock-access-token-${DateTime.now().millisecondsSinceEpoch}';
        token = newAccess;
        refresh = 'mock-refresh-token';
        await SecureHelper.instance.saveTokens(
          accessToken: newAccess,
          refreshToken: refresh,
        );
        AppLogger.i('Access token refreshed (mock)');
        return newAccess;
      }

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

  /// Signs the user out: cancels the session, clears tokens, and returns to
  /// login. Shows the "session expired" message only when [expired] is true
  /// (auto-logout); a manual logout stays silent.
  Future<void> logout({bool expired = false}) async {
    SessionManager.instance.cancel();
    token = '';
    refresh = '';
    await SecureHelper.instance.clearAll();
    if (expired) {
      SnackBarUtils.show(
        'Session expired. Please log in again.',
        type: SnackType.error,
      );
    }
    final ctx = navigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      // '/' resolves to the MaterialApp `home` (LoginScreen).
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (r) => false);
    }
  }
}
