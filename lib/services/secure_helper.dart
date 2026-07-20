import 'package:doc_genie/constants/secure_key_const.dart';
import 'package:doc_genie/services/secure_storage.dart';

class SecureHelper {
  SecureHelper._();
  static final SecureHelper instance = SecureHelper._();

  final SecureStorage _storage = SecureStorage.instance;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(SecureKeyConstant.accessTokenKey, accessToken);
    await _storage.write(SecureKeyConstant.refreshTokenKey, refreshToken);
  }

  Future<void> saveAccessToken(String accessToken) =>
      _storage.write(SecureKeyConstant.accessTokenKey, accessToken);

  Future<void> saveUser(String userJson) =>
      _storage.write(SecureKeyConstant.userKey, userJson);

  Future<void> saveRole(String role) =>
      _storage.write(SecureKeyConstant.roleKey, role);

  Future<String?> getAccessToken() =>
      _storage.read(SecureKeyConstant.accessTokenKey);

  Future<String?> getRefreshToken() =>
      _storage.read(SecureKeyConstant.refreshTokenKey);

  Future<String?> getUser() => _storage.read(SecureKeyConstant.userKey);

  Future<String?> getRole() => _storage.read(SecureKeyConstant.roleKey);

  /// Persists when the current login session expires (ISO-8601). Used to
  /// enforce the timeout across tab freeze/restore, where in-memory timers
  /// don't track real elapsed time.
  Future<void> saveSessionExpiry(DateTime expiry) => _storage.write(
    SecureKeyConstant.sessionExpiryKey,
    expiry.toIso8601String(),
  );

  Future<DateTime?> getSessionExpiry() async {
    final raw = await _storage.read(SecureKeyConstant.sessionExpiryKey);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> clearSessionExpiry() =>
      _storage.delete(SecureKeyConstant.sessionExpiryKey);

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearAll() => _storage.deleteAll();
}
