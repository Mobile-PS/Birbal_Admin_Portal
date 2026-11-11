import 'package:birbal_advice_admin_portal/app/app.dart';
import 'package:birbal_advice_admin_portal/core/auth/session_controller.dart';
import 'package:birbal_advice_admin_portal/core/constants/api_endpoints.dart';
import 'package:birbal_advice_admin_portal/core/network/api_client.dart';
import 'package:birbal_advice_admin_portal/data/repositories/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'json_adapter.dart';
import 'memory_token_store.dart';

Future<void> pumpAdminApp(
  WidgetTester tester, {
  required Size size,
  String? token,
  Dio? dio,
  bool mockAuthApi = false,
  bool mockUsersApi = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final tokenStore = MemoryTokenStore();
  if (token != null) {
    await tokenStore.saveSession(token: token);
  }

  final clientDio = dio ?? Dio(BaseOptions(baseUrl: 'http://example.com'));
  if (mockAuthApi || mockUsersApi) {
    clientDio.httpClientAdapter = JsonAdapter((options) async {
      if (mockAuthApi && options.path.endsWith(ApiEndpoints.requestOtp)) {
        return jsonBody({
          'status': true,
          'data': {
            'registered': true,
            'message': 'OTP sent successfully.',
          },
          'message': 'OTP sent successfully.',
        });
      }
      if (mockAuthApi && options.path.endsWith(ApiEndpoints.verifyOtp)) {
        return jsonBody({
          'status': true,
          'data': {
            'accessToken': 'test-access-token',
            'refreshToken': 'test-refresh-token',
            'id': 'admin-1',
            'name': 'Portal Admin',
            'phone': '9876543210',
          },
        });
      }
      if (mockUsersApi && options.path.endsWith(ApiEndpoints.users)) {
        return jsonBody({
          'status': true,
          'message': 'User created successfully.',
          'data': {'id': 'user-1'},
        });
      }
      return jsonBody({
        'status': false,
        'message': 'Unhandled test path: ${options.path}',
      }, statusCode: 404);
    });
  }

  final client = ApiClient(clientDio);
  final authRepository = AuthRepository(client, tokenStore);
  final session = SessionController(authRepository, tokenStore);
  await session.bootstrap();

  await tester.pumpWidget(
    BirbalAdminApp(
      apiClient: client,
      tokenStore: tokenStore,
      authRepository: authRepository,
      session: session,
    ),
  );
  await tester.pumpAndSettle();
}
