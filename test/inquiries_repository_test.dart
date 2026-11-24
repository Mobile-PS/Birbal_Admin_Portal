import 'package:birbal_advice_admin_portal/core/constants/api_endpoints.dart';
import 'package:birbal_advice_admin_portal/core/network/api_client.dart';
import 'package:birbal_advice_admin_portal/data/repositories/inquiries_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/json_adapter.dart';
import 'support/test_app.dart';

void main() {
  test('fetchInquiries maps paged content from /inquiries', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'));
    late RequestOptions captured;

    dio.httpClientAdapter = JsonAdapter((options) async {
      captured = options;
      return jsonBody(sampleInquiriesBody());
    });

    final page = await InquiriesRepository(ApiClient(dio)).fetchInquiries(
      page: 0,
      size: 20,
    );

    expect(captured.path, ApiEndpoints.inquiries);
    expect(captured.method, 'GET');
    expect(captured.queryParameters['page'], 0);
    expect(captured.queryParameters['size'], 20);
    expect(page.totalElements, 1);
    expect(page.content, hasLength(1));
    expect(page.content.first.username, 'Pritesh Chavarkar');
    expect(page.content.first.status, 'NEW');
    expect(page.content.first.policyCategory, 'ACCIDENT INSURANCE');
  });
}
