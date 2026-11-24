import 'package:birbal_advice_admin_portal/core/constants/api_endpoints.dart';
import 'package:birbal_advice_admin_portal/core/network/api_client.dart';
import 'package:birbal_advice_admin_portal/data/repositories/insurance_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/json_adapter.dart';
import 'support/test_app.dart';

void main() {
  test('fetchPlans requests insurance-plans with category code', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'));
    late RequestOptions captured;

    dio.httpClientAdapter = JsonAdapter((options) async {
      captured = options;
      return jsonBody(sampleInsurancePlansBody(category: 'ACCIDENT'));
    });

    final page = await InsuranceRepository(ApiClient(dio)).fetchPlans(
      category: 'ACCIDENT',
    );

    expect(captured.path, ApiEndpoints.insurancePlans);
    expect(captured.method, 'GET');
    expect(captured.queryParameters['activeOnly'], true);
    expect(captured.queryParameters['category'], 'ACCIDENT');
    expect(captured.queryParameters['page'], 0);
    expect(captured.queryParameters['size'], 50);
    expect(page.content, hasLength(1));
    expect(page.content.first.name, 'Personal Accident Cover');
    expect(page.content.first.insurerName, 'BAJAJ FINANCE');
    expect(page.content.first.hasDocument, isTrue);
    expect(page.content.first.documentDisplayName, 'personal-accident.pdf');
  });

  test('createInsurerData posts plan payload', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'));
    late RequestOptions captured;

    dio.httpClientAdapter = JsonAdapter((options) async {
      captured = options;
      return jsonBody({
        'status': true,
        'message': 'Insurance plan created successfully.',
        'data': {'code': 'ACCIDENT'},
      });
    });

    final message = await InsuranceRepository(ApiClient(dio)).createInsurerData(
      code: 'ACCIDENT',
      category: 'ACCIDENT INSURANCE',
      name: 'Personal Accident Cover',
      insurerName: 'BAJAJ FINANCE',
      description: 'Accident cover',
      documentBase64: 'data:application/pdf;base64,AAA',
    );

    expect(captured.path, ApiEndpoints.createInsurerData);
    expect(captured.method, 'POST');
    expect(captured.data, {
      'code': 'ACCIDENT',
      'category': 'ACCIDENT INSURANCE',
      'name': 'Personal Accident Cover',
      'insurerName': 'BAJAJ FINANCE',
      'description': 'Accident cover',
      'documentBase64': 'data:application/pdf;base64,AAA',
    });
    expect(message, 'Insurance plan created successfully.');
  });

  test('updateInsurerData puts plan payload to /updateInsurerData/{planId}',
      () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'));
    late RequestOptions captured;

    dio.httpClientAdapter = JsonAdapter((options) async {
      captured = options;
      return jsonBody({
        'status': true,
        'message': 'Insurance plan updated successfully.',
        'data': {'publicId': 'plan-1'},
      });
    });

    final message = await InsuranceRepository(ApiClient(dio)).updateInsurerData(
      planId: 'plan-1',
      code: 'ACCIDENT',
      category: 'ACCIDENT INSURANCE',
      name: 'Personal Accident Cover',
      insurerName: 'BAJAJ FINANCE',
      description: 'Accident cover',
      documentBase64: 'data:application/pdf;base64,AAA',
    );

    expect(captured.path, ApiEndpoints.updateInsurerData('plan-1'));
    expect(captured.method, 'PUT');
    expect(captured.data, {
      'code': 'ACCIDENT',
      'category': 'ACCIDENT INSURANCE',
      'name': 'Personal Accident Cover',
      'insurerName': 'BAJAJ FINANCE',
      'description': 'Accident cover',
      'documentBase64': 'data:application/pdf;base64,AAA',
    });
    expect(message, 'Insurance plan updated successfully.');
  });
}
