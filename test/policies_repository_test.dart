import 'package:birbal_advice_admin_portal/core/constants/api_endpoints.dart';
import 'package:birbal_advice_admin_portal/core/network/api_client.dart';
import 'package:birbal_advice_admin_portal/data/repositories/policies_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/json_adapter.dart';

void main() {
  test('createPolicy posts the expected body to /policies', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'));
    late RequestOptions captured;

    dio.httpClientAdapter = JsonAdapter((options) async {
      captured = options;
      return jsonBody({
        'status': true,
        'message': 'Policy created successfully.',
        'data': {'policyPublicId': 'pol-1'},
      });
    });

    final message = await PoliciesRepository(ApiClient(dio)).createPolicy(
      userPublicId: 'user-1',
      customerId: 'customer-1',
      planCategory: 'HEALTH',
      productName: 'Optima Secure',
      insurerName: 'HDFC ERGO',
      startDate: '2026-04-14',
      endDate: '2027-04-13',
      firstPolicyInceptionDate: '2026-04-14',
      renewalDate: '2027-04-14',
      premium: 18450,
      sumInsured: 1000000,
      policyTermYears: 1,
      policyDocumentBase64: 'data:application/pdf;base64,AAA',
    );

    expect(captured.path, ApiEndpoints.policies);
    expect(captured.method, 'POST');
    expect(captured.data, {
      'userPublicId': 'user-1',
      'customerId': 'customer-1',
      'planCategory': 'HEALTH',
      'productName': 'Optima Secure',
      'insurerName': 'HDFC ERGO',
      'startDate': '2026-04-14',
      'endDate': '2027-04-13',
      'firstPolicyInceptionDate': '2026-04-14',
      'renewalDate': '2027-04-14',
      'premium': 18450,
      'sumInsured': 1000000,
      'policyTermYears': 1,
      'policyDocumentBase64': 'data:application/pdf;base64,AAA',
    });
    expect(message, 'Policy created successfully.');
  });

  test('updatePolicy puts the expected body to /policies/{id}', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'));
    late RequestOptions captured;

    dio.httpClientAdapter = JsonAdapter((options) async {
      captured = options;
      return jsonBody({
        'status': true,
        'message': 'Policy updated successfully.',
        'data': {'policyPublicId': 'pol-1'},
      });
    });

    final message = await PoliciesRepository(ApiClient(dio)).updatePolicy(
      policyId: 'pol-1',
      userPublicId: 'user-1',
      customerId: 'customer-1',
      planCategory: 'HEALTH',
      productName: 'Optima Secure',
      insurerName: 'HDFC ERGO',
      policyNumber: 'BA-POL-2026-00001',
      startDate: '2026-04-14',
      endDate: '2027-04-13',
      firstPolicyInceptionDate: '2026-04-14',
      renewalDate: '2027-04-14',
      premium: 18450,
      sumInsured: 1000000,
      policyTermYears: 1,
      policyDocumentBase64: 'data:application/pdf;base64,AAA',
    );

    expect(captured.path, ApiEndpoints.policy('pol-1'));
    expect(captured.method, 'PUT');
    expect(captured.data, {
      'userPublicId': 'user-1',
      'customerId': 'customer-1',
      'planCategory': 'HEALTH',
      'productName': 'Optima Secure',
      'insurerName': 'HDFC ERGO',
      'policyNumber': 'BA-POL-2026-00001',
      'startDate': '2026-04-14',
      'endDate': '2027-04-13',
      'firstPolicyInceptionDate': '2026-04-14',
      'renewalDate': '2027-04-14',
      'premium': 18450,
      'sumInsured': 1000000,
      'policyTermYears': 1,
      'policyDocumentBase64': 'data:application/pdf;base64,AAA',
    });
    expect(message, 'Policy updated successfully.');
  });

  test('updatePolicyStatus patches ACTIVE/INACTIVE to /policies/{id}/status',
      () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'));
    late RequestOptions captured;

    dio.httpClientAdapter = JsonAdapter((options) async {
      captured = options;
      return jsonBody({
        'status': true,
        'message': 'Policy status updated successfully.',
        'data': {'policyPublicId': 'pol-1', 'status': 'INACTIVE'},
      });
    });

    final message = await PoliciesRepository(ApiClient(dio)).updatePolicyStatus(
      policyId: 'pol-1',
      status: 'INACTIVE',
    );

    expect(captured.path, ApiEndpoints.policyStatus('pol-1'));
    expect(captured.method, 'PATCH');
    expect(captured.data, {'status': 'INACTIVE'});
    expect(message, 'Policy status updated successfully.');
  });
}
