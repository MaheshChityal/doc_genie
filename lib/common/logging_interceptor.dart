import 'package:dio/dio.dart';
import 'package:doc_genie/utils/app_logger.dart';

/// Logs every Dio request / response / error via [AppLogger] (pretty-printed,
/// gated on `kDebugMode`). Registered only in debug builds.
///
/// Note: repositories currently run on mock data (`useMock = true`), which
/// bypasses Dio entirely — so these logs appear once real network calls are
/// made (flip a repository's `useMock` to `false`).
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.d(
      '→ REQUEST  ${options.method}  ${options.uri}\n'
      'headers: ${options.headers}\n'
      'query: ${options.queryParameters}\n'
      'body: ${options.data}',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.d(
      '← RESPONSE ${response.statusCode}  ${response.requestOptions.uri}\n'
      'data: ${response.data}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.e(
      '✖ ERROR    ${err.response?.statusCode}  ${err.requestOptions.uri}\n'
      'message: ${err.message}\n'
      'data: ${err.response?.data}',
    );
    handler.next(err);
  }
}
