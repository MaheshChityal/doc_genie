class AppConfig {
  const AppConfig._();

  static const String appName = 'DocGenie';

  /// TODO: set the real DocGenie API base URL.
  static const String baseUrl = 'https://api.example.com/';

  static const Duration timeout = Duration(seconds: 60);
}
