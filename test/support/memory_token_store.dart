import 'package:birbal_advice_admin_portal/core/storage/token_store.dart';

class MemoryTokenStore implements TokenStore {
  String? token;
  String? refreshToken;
  String? userJson;

  @override
  Future<void> saveSession({
    required String token,
    String? refreshToken,
    String? userJson,
  }) async {
    this.token = token;
    if (refreshToken != null) {
      this.refreshToken = refreshToken.isEmpty ? null : refreshToken;
    }
    this.userJson = (userJson == null || userJson.isEmpty) ? null : userJson;
  }

  @override
  Future<String?> readToken() async => token;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<String?> readUserJson() async => userJson;

  @override
  Future<void> clearSession() async {
    token = null;
    refreshToken = null;
    userJson = null;
  }
}
