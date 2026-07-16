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

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearAll() => _storage.deleteAll();
}
