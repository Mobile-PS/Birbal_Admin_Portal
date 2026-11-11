import 'dart:convert';

import '../../core/config/app_config.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/api_response.dart';
import '../../core/storage/token_store.dart';
import '../models/otp_request_result.dart';
import '../models/user_model.dart';

class AuthRepository {
  AuthRepository(this._client, this._tokenStore);

  final ApiClient _client;
  final TokenStore _tokenStore;

  /// Requests an OTP for [identifier].
  /// [type] is `M` for mobile and `E` for email.
  Future<OtpRequestResult> requestOtp({
    required String identifier,
    String type = 'M',
  }) async {
    if (AppConfig.disableApiCalls) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      return const OtpRequestResult(
        registered: true,
        message: 'OTP sent (offline mode). Use any 6-digit code.',
      );
    }

    final data = await _client.post(
      ApiEndpoints.requestOtp,
      data: {
        'type': type,
        'identifier': identifier,
      },
    );

    if (data is! Map) {
      throw const ApiException('Unexpected response while sending OTP.');
    }

    final body = Map<String, dynamic>.from(data);
    ApiResponse.ensureSuccess(body);
    return OtpRequestResult.fromBody(body);
  }

  /// Verifies OTP and persists access / refresh tokens.
  Future<UserModel> verifyOtp({
    required String identifier,
    required String otp,
    String type = 'M',
  }) async {
    if (AppConfig.disableApiCalls) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      final user = UserModel(
        id: 'offline-admin',
        name: type == 'E' ? identifier.split('@').first : 'Admin',
        email: type == 'E' ? identifier : null,
        phone: type == 'M' ? identifier : null,
      );
      await _tokenStore.saveSession(
        token: 'offline-access-token',
        refreshToken: 'offline-refresh-token',
        userJson: jsonEncode(user.toJson()),
      );
      return user;
    }

    final data = await _client.post(
      ApiEndpoints.verifyOtp,
      data: {
        'type': type,
        'identifier': identifier,
        'otp': otp,
      },
    );

    if (data is! Map) {
      throw const ApiException('Unexpected response while verifying OTP.');
    }

    final body = Map<String, dynamic>.from(data);
    ApiResponse.ensureSuccess(body);

    final auth = ApiResponse.dataMap(body);
    final accessToken = auth['accessToken'] ?? auth['access_token'];
    if (accessToken is! String || accessToken.isEmpty) {
      throw const ApiException('Verify OTP did not return an access token.');
    }

    final refreshToken = auth['refreshToken'] ?? auth['refresh_token'];
    final parsed = UserModel.fromJson(
      auth,
      phone: type == 'M' ? identifier : null,
    );
    final user = UserModel(
      id: parsed.id,
      name: parsed.name,
      email: parsed.email ?? (type == 'E' ? identifier : null),
      phone: parsed.phone ?? (type == 'M' ? identifier : null),
    );

    await _tokenStore.saveSession(
      token: accessToken,
      refreshToken: refreshToken is String ? refreshToken : null,
      userJson: jsonEncode(user.toJson()),
    );
    return user;
  }

  Future<UserModel?> currentUser() async {
    final raw = await _tokenStore.readUserJson();
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return UserModel.fromJson(Map<String, dynamic>.from(decoded));
    } on FormatException {
      return null;
    }
  }

  Future<void> logout() => _tokenStore.clearSession();
}
