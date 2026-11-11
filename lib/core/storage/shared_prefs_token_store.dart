import 'package:shared_preferences/shared_preferences.dart';

import 'token_store.dart';

/// Session storage that works on web and mobile.
class SharedPrefsTokenStore implements TokenStore {
  SharedPrefsTokenStore(this._prefs);

  final SharedPreferences _prefs;

  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _userKey = 'auth_user';

  @override
  Future<void> saveSession({
    required String token,
    String? refreshToken,
    String? userJson,
  }) async {
    await _prefs.setString(_tokenKey, token);
    if (refreshToken != null) {
      if (refreshToken.isEmpty) {
        await _prefs.remove(_refreshTokenKey);
      } else {
        await _prefs.setString(_refreshTokenKey, refreshToken);
      }
    }
    if (userJson == null || userJson.isEmpty) {
      await _prefs.remove(_userKey);
      return;
    }
    await _prefs.setString(_userKey, userJson);
  }

  @override
  Future<String?> readToken() async => _prefs.getString(_tokenKey);

  @override
  Future<String?> readRefreshToken() async =>
      _prefs.getString(_refreshTokenKey);

  @override
  Future<String?> readUserJson() async => _prefs.getString(_userKey);

  @override
  Future<void> clearSession() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_refreshTokenKey);
    await _prefs.remove(_userKey);
  }
}
