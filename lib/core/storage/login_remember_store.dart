import 'package:shared_preferences/shared_preferences.dart';

class RememberedLogin {
  const RememberedLogin({
    required this.type,
    required this.identifier,
  });

  /// `M` for mobile, `E` for email.
  final String type;
  final String identifier;

  bool get isMobile => type.toUpperCase() == 'M';
}

/// Persists the last login identifier when "Remember me" is enabled.
class LoginRememberStore {
  LoginRememberStore(this._prefs);

  final SharedPreferences _prefs;

  static const _enabledKey = 'login_remember_enabled';
  static const _typeKey = 'login_remember_type';
  static const _identifierKey = 'login_remember_identifier';

  bool get isEnabled => _prefs.getBool(_enabledKey) ?? false;

  RememberedLogin? read() {
    if (!isEnabled) return null;
    final type = (_prefs.getString(_typeKey) ?? '').trim().toUpperCase();
    final identifier = (_prefs.getString(_identifierKey) ?? '').trim();
    if ((type != 'M' && type != 'E') || identifier.isEmpty) return null;
    return RememberedLogin(type: type, identifier: identifier);
  }

  Future<void> save({
    required String type,
    required String identifier,
  }) async {
    final normalizedType = type.trim().toUpperCase();
    final normalizedIdentifier = identifier.trim();
    if ((normalizedType != 'M' && normalizedType != 'E') ||
        normalizedIdentifier.isEmpty) {
      await clear();
      return;
    }

    await _prefs.setBool(_enabledKey, true);
    await _prefs.setString(_typeKey, normalizedType);
    await _prefs.setString(_identifierKey, normalizedIdentifier);
  }

  Future<void> clear() async {
    await _prefs.remove(_enabledKey);
    await _prefs.remove(_typeKey);
    await _prefs.remove(_identifierKey);
  }
}
