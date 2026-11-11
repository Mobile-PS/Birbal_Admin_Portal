import 'package:birbal_advice_admin_portal/core/constants/api_endpoints.dart';
import 'package:birbal_advice_admin_portal/core/network/api_client.dart';
import 'package:birbal_advice_admin_portal/data/repositories/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/json_adapter.dart';
import 'support/memory_token_store.dart';

void main() {
  test('requestOtp posts to the OTP endpoint', () async {
    final store = MemoryTokenStore();
    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'));
    late RequestOptions captured;

    dio.httpClientAdapter = JsonAdapter((options) async {
      captured = options;
      return jsonBody({
        'status': true,
        'data': {'registered': true, 'message': 'OTP sent successfully.'},
        'message': 'OTP sent successfully.',
      });
    });

    final result = await AuthRepository(ApiClient(dio), store).requestOtp(
      identifier: '9876543210',
      type: 'M',
    );

    expect(captured.path, ApiEndpoints.requestOtp);
    expect(result.registered, isTrue);
    expect(result.message, 'OTP sent successfully.');
  });

  test('verifyOtp stores the access token and user', () async {
    final store = MemoryTokenStore();
    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'));

    dio.httpClientAdapter = JsonAdapter((options) async {
      return jsonBody({
        'status': true,
        'data': {
          'accessToken': 'access-123',
          'refreshToken': 'refresh-123',
          'id': 'admin-1',
          'name': 'Portal Admin',
          'phone': '9876543210',
        },
      });
    });

    final user = await AuthRepository(ApiClient(dio), store).verifyOtp(
      identifier: '9876543210',
      otp: '123456',
    );

    expect(user.name, 'Portal Admin');
    expect(await store.readToken(), 'access-123');
    expect(await store.readRefreshToken(), 'refresh-123');
    expect(await store.readUserJson(), contains('Portal Admin'));
  });
}
