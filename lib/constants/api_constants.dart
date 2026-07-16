import 'package:doc_genie/config/app_config.dart';

class ApiConstants {
  const ApiConstants._();

  static const String login = '${AppConfig.baseUrl}auth/login';
  static const String refreshToken = '${AppConfig.baseUrl}auth/refresh';
  static const String logout = '${AppConfig.baseUrl}auth/logout';

  static const String homeFeed = '${AppConfig.baseUrl}home/feed';

  static const String autoScan = '${AppConfig.baseUrl}maker/auto-scan';
  static const String manualScan = '${AppConfig.baseUrl}maker/manual-scan';
  static const String makerDocs = '${AppConfig.baseUrl}maker/documents';
  static String makerDoc(String id) => '${AppConfig.baseUrl}maker/documents/$id';

  static const String checkerDocs = '${AppConfig.baseUrl}checker/documents';
  static String checkerDecide(String id) =>
      '${AppConfig.baseUrl}checker/documents/$id/decide';
}
