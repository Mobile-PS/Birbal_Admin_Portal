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

Map<String, dynamic> sampleDashboardBody({
  int activePolicies = 2,
  int inactivePolicies = 0,
  int totalCustomers = 2,
  int totalInquiries = 1,
  int totalPlans = 8,
  int totalPolicies = 2,
  int totalUsers = 2,
}) {
  return {
    'status': true,
    'message': 'Operation completed successfully',
    'data': {
      'activePolicies': activePolicies,
      'inactivePolicies': inactivePolicies,
      'totalCustomers': totalCustomers,
      'totalInquiries': totalInquiries,
      'totalPlans': totalPlans,
      'totalPolicies': totalPolicies,
      'totalUsers': totalUsers,
    },
  };
}

Map<String, dynamic> sampleUserDetailsBody() {
  return {
    'status': true,
    'message': 'Operation completed successfully',
    'data': {
      'content': [
        {
          'customerFullName': 'Pritesh Chavarkar',
          'customerPublicId': '0b551298-56c9-4970-b74b-3f0def7b5058',
          'email': 'priteshchavarkar19@gmail.com',
          'firstName': 'Pritesh',
          'lastName': 'Chavarkar',
          'mobile': '9769363548',
          'policies': [
            {
              'endDate': '2027-04-13',
              'insurerName': 'BAJAJ FINANCE',
              'planCategory': 'MOTOR',
              'planName': 'BAJAJ FINANCE',
              'policyNumber': 'BA-POL-2026-00002',
              'policyPublicId': '0a046719-96b9-4938-b2ad-f304595881fb',
              'premium': 18450,
              'renewalStatus': 'ACTIVE',
              'status': 'ACTIVE',
              'sumInsured': 1000000,
              'policyDocumentFileName': 'bajaj-policy.pdf',
              'policyDocumentBase64':
                  'data:application/pdf;base64,JVBERi0xLjQK',
            },
          ],
          'policyCount': 1,
          'status': 'ACTIVE',
          'userPublicId': '82726b83-c49d-45c9-b595-e14e52cdc057',
        },
        {
          'customerFullName': 'Atish Vaidya',
          'customerPublicId': '29854995-9b30-4e59-a977-531296367622',
          'email': 'atish@gmail.com',
          'firstName': 'Atish',
          'lastName': 'Vaidya',
          'mobile': '9876543210',
          'policies': [
            {
              'endDate': '2027-04-13',
              'insurerName': 'HDFC ERGO',
              'planCategory': 'HEALTH',
              'planName': 'Optima Secure',
              'policyNumber': 'BA-POL-2026-00001',
              'policyPublicId': '7cfd7d9a-a5a1-4889-a8eb-8ae2f1d9da9f',
              'premium': 18450,
              'renewalStatus': 'ACTIVE',
              'status': 'ACTIVE',
              'sumInsured': 1000000,
            },
            {
              'endDate': '2026-12-01',
              'insurerName': 'ICICI LOMBARD',
              'planCategory': 'MOTOR',
              'planName': 'Comprehensive',
              'policyNumber': 'BA-POL-2026-00003',
              'policyPublicId': '8afe8e0b-b6b2-4990-b9fc-9bf3a2e0eb0a',
              'premium': 9200,
              'renewalStatus': 'ACTIVE',
              'status': 'ACTIVE',
              'sumInsured': 500000,
            },
          ],
          'policyCount': 2,
          'status': 'ACTIVE',
          'userPublicId': 'c70d9550-2822-44af-8e5f-3e68e097299e',
        },
      ],
      'last': true,
      'page': 0,
      'size': 20,
      'totalElements': 2,
      'totalPages': 1,
    },
  };
}

Map<String, dynamic> sampleInquiriesBody() {
  return {
    'status': true,
    'message': 'Operation completed successfully',
    'data': {
      'content': [
        {
          'createdAt': '2026-11-13T12:29:45.367254',
          'email': 'priteshchavarkar19@gmail.com',
          'mobileNumber': '9769363548',
          'policyCategory': 'ACCIDENT INSURANCE',
          'policyName': 'Insurance plan',
          'publicId': 'bbc98adc-84dd-44b9-82e8-52fdeb7aa59a',
          'status': 'NEW',
          'username': 'Pritesh Chavarkar',
        },
      ],
      'last': true,
      'page': 0,
      'size': 20,
      'totalElements': 1,
      'totalPages': 1,
    },
  };
}

Map<String, dynamic> sampleCategoriesBody() {
  return {
    'status': true,
    'message': 'Operation completed successfully',
    'data': [
      {
        'code': 'ACCIDENT',
        'category': 'ACCIDENT INSURANCE',
        'active': true,
        'displayOrder': 0,
        'planCount': 1,
        'documentBase64':
            'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
        'documentFileName': 'accident.png',
      },
      {
        'code': 'HEALTH',
        'category': 'Health',
        'active': true,
        'displayOrder': 0,
        'planCount': 3,
      },
      {
        'code': 'MOTOR',
        'category': 'MOTOR INSURANCE',
        'active': false,
        'displayOrder': 0,
        'planCount': 2,
      },
    ],
  };
}

Map<String, dynamic> sampleInsurancePlansBody({String category = 'ACCIDENT'}) {
  return {
    'status': true,
    'message': 'Operation completed successfully',
    'data': {
      'content': [
        {
          'publicId': 'plan-1',
          'name': 'Personal Accident Cover',
          'category': category,
          'insurerName': 'BAJAJ FINANCE',
          'description': 'Covers accidental injuries and hospitalization.',
          'documentBase64': 'data:application/pdf;base64,JVBERi0xLjQK',
          'documentFileName': 'personal-accident.pdf',
          'active': true,
        },
      ],
      'last': true,
      'page': 0,
      'size': 50,
      'totalElements': 1,
      'totalPages': 1,
    },
  };
}

Future<void> pumpAdminApp(
  WidgetTester tester, {
  required Size size,
  String? token,
  Dio? dio,
  bool mockAuthApi = false,
  bool mockUsersApi = false,
  bool mockDashboardApi = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final tokenStore = MemoryTokenStore();
  if (token != null) {
    await tokenStore.saveSession(token: token);
  }

  final shouldMockDashboard =
      mockDashboardApi || mockAuthApi || token != null;
  final clientDio = dio ?? Dio(BaseOptions(baseUrl: 'http://example.com'));
  if (mockAuthApi || mockUsersApi || shouldMockDashboard) {
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
      if (mockUsersApi &&
          options.method.toUpperCase() == 'PATCH' &&
          options.path.contains('${ApiEndpoints.users}/')) {
        return jsonBody({
          'status': true,
          'message': 'User updated successfully.',
          'data': {'id': 'user-1'},
        });
      }
      if (shouldMockDashboard &&
          options.path.endsWith(ApiEndpoints.adminDashboardUserDetails)) {
        return jsonBody(sampleUserDetailsBody());
      }
      if (shouldMockDashboard &&
          options.method.toUpperCase() == 'PATCH' &&
          options.path.contains('${ApiEndpoints.adminDashboardCategories}/') &&
          options.path.endsWith('/toggle')) {
        final segments = options.path.split('/');
        final code = segments.length >= 2
            ? segments[segments.length - 2]
            : 'UNKNOWN';
        final source = sampleCategoriesBody()['data'] as List<dynamic>;
        final match = source.cast<Map<String, dynamic>>().firstWhere(
          (item) => item['code'] == code,
          orElse: () => {
            'code': code,
            'category': code,
            'active': true,
            'displayOrder': 0,
            'planCount': 0,
          },
        );
        return jsonBody({
          'status': true,
          'message': match['active'] == true
              ? 'Category deactivated'
              : 'Category activated',
          'data': {
            ...match,
            'active': match['active'] != true,
          },
        });
      }
      if (shouldMockDashboard &&
          options.path.endsWith(ApiEndpoints.adminDashboardCategories)) {
        return jsonBody(sampleCategoriesBody());
      }
      if (shouldMockDashboard &&
          options.path.endsWith(ApiEndpoints.adminDashboard)) {
        return jsonBody(sampleDashboardBody());
      }
      if (shouldMockDashboard &&
          options.path.endsWith(ApiEndpoints.inquiries)) {
        return jsonBody(sampleInquiriesBody());
      }
      if (shouldMockDashboard &&
          options.path.endsWith(ApiEndpoints.createInsuranceCategory)) {
        final payload = options.data;
        final code = payload is Map ? '${payload['code'] ?? 'TEST'}' : 'TEST';
        final category =
            payload is Map ? '${payload['category'] ?? 'Test'}' : 'Test';
        return jsonBody({
          'status': true,
          'message': 'Insurance category created successfully',
          'data': {
            'code': code,
            'category': category,
            'active': true,
            'displayOrder': 0,
            'planCount': 0,
          },
        });
      }
      if (shouldMockDashboard &&
          options.path.contains('/updateInsuranceCategory/')) {
        final payload = options.data;
        final code = payload is Map ? '${payload['code'] ?? 'TEST'}' : 'TEST';
        final category =
            payload is Map ? '${payload['category'] ?? 'Test'}' : 'Test';
        return jsonBody({
          'status': true,
          'message': 'Insurance category updated successfully',
          'data': {
            'code': code,
            'category': category,
            'active': true,
            'displayOrder': 0,
            'planCount': 0,
          },
        });
      }
      if (shouldMockDashboard &&
          options.path.endsWith(ApiEndpoints.insurancePlans)) {
        final category =
            '${options.queryParameters['category'] ?? 'ACCIDENT'}';
        return jsonBody(sampleInsurancePlansBody(category: category));
      }
      if (shouldMockDashboard &&
          options.path.endsWith(ApiEndpoints.createInsurerData)) {
        return jsonBody({
          'status': true,
          'message': 'Insurance plan created successfully.',
          'data': {
            'code': 'ACCIDENT',
            'category': 'ACCIDENT INSURANCE',
            'insurerName': 'Test Insurer',
          },
        });
      }
      if (shouldMockDashboard &&
          options.path.contains('/updateInsurerData/')) {
        return jsonBody({
          'status': true,
          'message': 'Insurance plan updated successfully.',
          'data': {
            'publicId': 'plan-1',
            'code': 'ACCIDENT',
            'category': 'ACCIDENT INSURANCE',
            'insurerName': 'Test Insurer',
          },
        });
      }
      if (shouldMockDashboard &&
          options.path.endsWith(ApiEndpoints.policies)) {
        return jsonBody({
          'status': true,
          'message': 'Policy created successfully.',
          'data': {'policyPublicId': 'pol-1'},
        });
      }
      if (shouldMockDashboard &&
          options.method.toUpperCase() == 'PUT' &&
          options.path.contains('${ApiEndpoints.policies}/') &&
          !options.path.endsWith('/status')) {
        return jsonBody({
          'status': true,
          'message': 'Policy updated successfully.',
          'data': {'policyPublicId': 'pol-1'},
        });
      }
      if (shouldMockDashboard &&
          options.method.toUpperCase() == 'PATCH' &&
          options.path.contains('${ApiEndpoints.policies}/') &&
          options.path.endsWith('/status')) {
        final payload = options.data;
        final status = payload is Map ? '${payload['status'] ?? 'ACTIVE'}' : 'ACTIVE';
        return jsonBody({
          'status': true,
          'message': 'Policy status updated successfully.',
          'data': {'policyPublicId': 'pol-1', 'status': status},
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
