abstract class TokenStore {
  Future<void> saveSession({
    required String token,
    String? refreshToken,
    String? userJson,
  });

  Future<String?> readToken();

  Future<String?> readRefreshToken();

  Future<String?> readUserJson();

  Future<void> clearSession();
}
