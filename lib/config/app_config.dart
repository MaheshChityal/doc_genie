class AppConfig {
  const AppConfig._();

  static const String appName = 'DocGenie';

  /// TODO: set the real DocGenie API base URL.
  static const String baseUrl = 'https://api.example.com/';

  static const Duration timeout = Duration(seconds: 60);

  /// How long a login session stays valid before it must be refreshed.
  static const Duration sessionDuration = Duration(minutes: 30);

  /// How long before [sessionDuration] ends to show the "session expiring"
  /// warning popup (also the countdown length shown in that popup).
  static const Duration sessionWarnBefore = Duration(minutes: 2);
}
