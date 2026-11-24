import 'package:birbal_advice_admin_portal/core/constants/api_endpoints.dart';
import 'package:birbal_advice_admin_portal/core/network/api_client.dart';
import 'package:birbal_advice_admin_portal/data/models/customer_list_filter.dart';
import 'package:birbal_advice_admin_portal/data/repositories/dashboard_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/json_adapter.dart';
import 'support/test_app.dart';

void main() {
  test('fetchDashboard maps count fields from /admin/dashboard', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'));
    late RequestOptions captured;

    dio.httpClientAdapter = JsonAdapter((options) async {
      captured = options;
      return jsonBody(sampleDashboardBody());
    });

    final summary = await DashboardRepository(ApiClient(dio)).fetchDashboard();

    expect(captured.path, ApiEndpoints.adminDashboard);
    expect(captured.method, 'GET');
    expect(summary.activePolicies, 2);
    expect(summary.inactivePolicies, 0);
    expect(summary.totalCustomers, 2);
    expect(summary.totalInquiries, 1);
    expect(summary.totalPlans, 8);
    expect(summary.totalPolicies, 2);
    expect(summary.totalUsers, 2);
  });

  test('fetchCategories maps list items from /admin/dashboard/categories',
      () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'));
    late RequestOptions captured;

    dio.httpClientAdapter = JsonAdapter((options) async {
      captured = options;
      return jsonBody(sampleCategoriesBody());
    });

    final categories =
        await DashboardRepository(ApiClient(dio)).fetchCategories();

    expect(captured.path, ApiEndpoints.adminDashboardCategories);
    expect(captured.method, 'GET');
    expect(categories, hasLength(3));
    expect(categories.first.id, 'ACCIDENT');
    expect(categories.first.productCategory, 'ACCIDENT INSURANCE');
    expect(categories.first.isEnabled, isTrue);
    expect(categories.first.planCount, 1);
    expect(categories.first.hasIcon, isTrue);
    expect(categories.first.documentFileName, 'accident.png');
    expect(
      categories.firstWhere((item) => item.id == 'MOTOR').isEnabled,
      isFalse,
    );
  });

  test('toggleCategory patches /admin/dashboard/categories/{code}/toggle',
      () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'));
    late RequestOptions captured;

    dio.httpClientAdapter = JsonAdapter((options) async {
      captured = options;
      return jsonBody({
        'status': true,
        'message': 'Category deactivated',
        'data': {
          'code': 'HEALTH',
          'category': 'Health',
          'active': false,
          'displayOrder': 0,
          'planCount': 3,
        },
      });
    });

    final updated =
        await DashboardRepository(ApiClient(dio)).toggleCategory('HEALTH');

    expect(
      captured.path,
      ApiEndpoints.adminDashboardCategoryToggle('HEALTH'),
    );
    expect(captured.method, 'PATCH');
    expect(updated.id, 'HEALTH');
    expect(updated.productCategory, 'Health');
    expect(updated.isEnabled, isFalse);
    expect(updated.planCount, 3);
  });

  test('createInsuranceCategory posts code, category and documentBase64',
      () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'));
    late RequestOptions captured;

    dio.httpClientAdapter = JsonAdapter((options) async {
      captured = options;
      return jsonBody({
        'status': true,
        'message': 'Insurance category created successfully',
        'data': {
          'code': 'TEST',
          'category': 'Test Category',
          'active': true,
          'displayOrder': 0,
          'planCount': 0,
        },
      });
    });

    final created = await DashboardRepository(ApiClient(dio))
        .createInsuranceCategory(
      code: 'TEST',
      category: 'Test Category',
      documentBase64: 'data:image/png;base64,AAA',
    );

    expect(captured.path, ApiEndpoints.createInsuranceCategory);
    expect(captured.method, 'POST');
    expect(captured.data, {
      'code': 'TEST',
      'category': 'Test Category',
      'documentBase64': 'data:image/png;base64,AAA',
    });
    expect(created.id, 'TEST');
    expect(created.productCategory, 'Test Category');
    expect(created.isEnabled, isTrue);
  });

  test('updateInsuranceCategory puts code, category and documentBase64',
      () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'));
    late RequestOptions captured;

    dio.httpClientAdapter = JsonAdapter((options) async {
      captured = options;
      return jsonBody({
        'status': true,
        'message': 'Insurance category updated successfully',
        'data': {
          'code': 'HEALTH',
          'category': 'Health Insurance',
          'active': true,
          'displayOrder': 1,
          'planCount': 4,
        },
      });
    });

    final updated = await DashboardRepository(ApiClient(dio))
        .updateInsuranceCategory(
      code: 'HEALTH',
      category: 'Health Insurance',
      documentBase64: 'data:image/png;base64,AAA',
    );

    expect(captured.path, ApiEndpoints.updateInsuranceCategory('HEALTH'));
    expect(captured.method, 'PUT');
    expect(captured.data, {
      'code': 'HEALTH',
      'category': 'Health Insurance',
      'documentBase64': 'data:image/png;base64,AAA',
    });
    expect(updated.id, 'HEALTH');
    expect(updated.productCategory, 'Health Insurance');
    expect(updated.planCount, 4);
  });

  test('fetchUserDetails posts filter/page/size to userDetails', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'));
    late RequestOptions captured;

    dio.httpClientAdapter = JsonAdapter((options) async {
      captured = options;
      return jsonBody(sampleUserDetailsBody());
    });

    final page = await DashboardRepository(ApiClient(dio)).fetchUserDetails(
      filter: CustomerListFilter.active,
      page: 0,
      size: 20,
    );

    expect(captured.path, ApiEndpoints.adminDashboardUserDetails);
    expect(captured.method, 'GET');
    expect(captured.queryParameters['filter'], 'active');
    expect(captured.queryParameters['page'], 0);
    expect(captured.queryParameters['size'], 20);
    expect(page.totalElements, 2);
    expect(page.content, hasLength(2));
    expect(page.content.first.name, 'Pritesh Chavarkar');
    expect(page.content.first.firstName, 'Pritesh');
    expect(page.content.first.lastName, 'Chavarkar');
    expect(page.content.first.policyCount, 1);
    expect(page.content.first.policies, hasLength(1));
    expect(page.content.first.policies.first.policyNumber, 'BA-POL-2026-00002');
    expect(page.content.first.policies.first.planCategory, 'MOTOR');
    expect(page.content.first.policies.first.hasDocument, isTrue);
    expect(
      page.content.first.policies.first.documentDisplayName,
      'bajaj-policy.pdf',
    );
    expect(page.content[1].policies, hasLength(2));
  });
}
