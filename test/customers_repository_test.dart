import 'package:birbal_advice_admin_portal/core/constants/api_endpoints.dart';
import 'package:birbal_advice_admin_portal/core/network/api_client.dart';
import 'package:birbal_advice_admin_portal/core/network/api_exception.dart';
import 'package:birbal_advice_admin_portal/data/repositories/customers_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/json_adapter.dart';

void main() {
  test('getCustomerApplication gets /customers/{id} and parses payload',
      () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'));
    late RequestOptions captured;

    dio.httpClientAdapter = JsonAdapter((options) async {
      captured = options;
      return jsonBody({
        'status': true,
        'message': 'Operation completed successfully',
        'data': {
          'applicationId': 'app-1',
          'applicationNumber': 'BA-PL-2026-00004',
          'applicationType': 'NEW_POLICY',
          'completionStatus': 'SUBMITTED',
          'processingStatus': 'PENDING',
          'policyCategory': 'HEALTH',
          'proposer': {
            'fullName': 'Test Chavarkar',
            'mobile': '8356962625',
            'email': 'test@example.com',
          },
          'insuredMembers': [
            {
              'fullName': 'Test Chavarkar',
              'memberNumber': 1,
              'memberType': 'SELF',
              'relationship': 'SELF',
              'medicalConditions': [],
              'lifestyle': {
                'alcohol': false,
                'cigarettes': false,
                'panMasala': false,
              },
              'pregnancy': {'applicable': false},
              'documents': {
                'aadhaarCard': null,
                'panCard': null,
                'medicalDocuments': [],
              },
            },
          ],
          'nominee': {
            'fullName': 'B. Jvj',
            'relationship': 'SPOUSE',
            'isMinor': false,
            'dateOfBirth': '01/01/1990',
          },
          'bankDetails': {
            'accountHolderFullName': 'Test Chavarkar',
            'accountNumber': '9632589631',
            'accountType': 'SAVINGS',
            'bankName': 'icici',
            'branchName': 'MH',
            'ifscCode': 'ICICI000248',
          },
          'proposerDocuments': {
            'aadhaarCard': null,
            'panCard': null,
            'digitalSignature': null,
            'medicalDocuments': [],
          },
        },
      });
    });

    final application =
        await CustomersRepository(ApiClient(dio)).getCustomerApplication(
      '8e1de628-7d79-418b-a069-17e7cb380952',
    );

    expect(
      captured.path,
      ApiEndpoints.customer('8e1de628-7d79-418b-a069-17e7cb380952'),
    );
    expect(captured.method, 'GET');
    expect(application.applicationNumber, 'BA-PL-2026-00004');
    expect(application.proposer.fullName, 'Test Chavarkar');
    expect(application.insuredMembers, hasLength(1));
    expect(application.nominee?.relationship, 'SPOUSE');
    expect(application.bankDetails?.ifscCode, 'ICICI000248');
  });

  test('getCustomerApplication throws when status is false', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'));
    dio.httpClientAdapter = JsonAdapter((options) async {
      return jsonBody({
        'status': false,
        'message': 'Customer application not found.',
      });
    });

    expect(
      () => CustomersRepository(ApiClient(dio)).getCustomerApplication('c-1'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'Customer application not found.',
        ),
      ),
    );
  });
}
