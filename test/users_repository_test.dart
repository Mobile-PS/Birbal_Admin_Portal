import 'package:birbal_advice_admin_portal/core/constants/api_endpoints.dart';
import 'package:birbal_advice_admin_portal/core/network/api_client.dart';
import 'package:birbal_advice_admin_portal/core/network/api_exception.dart';
import 'package:birbal_advice_admin_portal/data/models/customer_role.dart';
import 'package:birbal_advice_admin_portal/data/repositories/users_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/json_adapter.dart';

void main() {
  test('createUser posts the expected body to /users', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'));
    late RequestOptions captured;

    dio.httpClientAdapter = JsonAdapter((options) async {
      captured = options;
      return jsonBody({
        'status': true,
        'message': 'User created successfully.',
        'data': {'id': 'user-1'},
      });
    });

    final message = await UsersRepository(ApiClient(dio)).createUser(
      firstName: 'Atish',
      lastName: 'Vaidya',
      email: 'atish@example.com',
      mobile: '9876543210',
      role: CustomerRole.sales,
    );

    expect(captured.path, ApiEndpoints.users);
    expect(captured.method, 'POST');
    expect(captured.data, {
      'firstName': 'Atish',
      'lastName': 'Vaidya',
      'email': 'atish@example.com',
      'mobile': '9876543210',
      'role': 'SALES',
    });
    expect(message, 'User created successfully.');
  });

  test('createUser throws when the API returns status false', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'));
    dio.httpClientAdapter = JsonAdapter((options) async {
      return jsonBody({
        'status': false,
        'message': 'Email already exists.',
      });
    });

    expect(
      () => UsersRepository(ApiClient(dio)).createUser(
        firstName: 'Atish',
        lastName: 'Vaidya',
        email: 'atish@example.com',
        mobile: '9876543210',
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'Email already exists.',
        ),
      ),
    );
  });
}
