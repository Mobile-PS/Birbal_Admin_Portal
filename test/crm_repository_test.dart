import 'package:birbal_advice_admin_portal/core/constants/api_endpoints.dart';
import 'package:birbal_advice_admin_portal/core/network/api_client.dart';
import 'package:birbal_advice_admin_portal/data/models/lead_models.dart';
import 'package:birbal_advice_admin_portal/data/repositories/crm_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/json_adapter.dart';

void main() {
  setUp(CrmRepository.resetForTest);

  test('fetchSalesAssignees loads staff from /users/staff-directory', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'));
    late RequestOptions captured;

    dio.httpClientAdapter = JsonAdapter((options) async {
      captured = options;
      return jsonBody({
        'status': true,
        'message': 'Operation completed successfully',
        'data': [
          {
            'publicId': '492dca7a-513f-46ea-a8c2-19c91cfb1db8',
            'firstName': 'Shubham',
            'lastName': 'Rai',
            'email': 'sr35285@gmail.com',
            'mobile': '8087701542',
            'roles': ['COMPANY_ADMIN'],
            'status': 'ACTIVE',
          },
          {
            'publicId': 'e49ab081-c21b-4d0e-863f-5f9e3d80a44d',
            'firstName': 'Sales',
            'lastName': 'Sales',
            'email': 'sales@gmail.com',
            'mobile': '9632587412',
            'roles': ['SALES'],
            'status': 'ACTIVE',
          },
        ],
      });
    });

    final users = await CrmRepository(ApiClient(dio)).fetchSalesAssignees();

    expect(captured.path, ApiEndpoints.usersStaffDirectory);
    expect(captured.method, 'GET');
    expect(users, hasLength(2));
    expect(users.first.id, '492dca7a-513f-46ea-a8c2-19c91cfb1db8');
    expect(users.first.name, 'Shubham Rai');
    expect(users.last.id, 'e49ab081-c21b-4d0e-863f-5f9e3d80a44d');
    expect(users.last.name, 'Sales Sales');
  });

  test('fetchLeads loads paged content from /crm/leads', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'));
    late RequestOptions captured;

    dio.httpClientAdapter = JsonAdapter((options) async {
      captured = options;
      return jsonBody({
        'status': true,
        'message': 'Operation completed successfully',
        'data': {
          'content': [
            {
              'leadPublicId': 'f101fad4-06f0-488d-af5e-9bf94f582995',
              'name': 'Test Sales',
              'mobile': '9638388338',
              'productInterest': 'ICICI Insurance Name',
              'stage': 'NEW_LEAD',
              'assignedEmployee': {
                'publicId': '492dca7a-513f-46ea-a8c2-19c91cfb1db8',
                'firstName': 'Shubham',
                'lastName': 'Rai',
                'email': 'sr35285@gmail.com',
              },
              'nextFollowUpAt': '2026-11-28T14:37:00Z',
              'createdAt': '2026-11-26T14:38:15.951689Z',
            },
          ],
          'last': true,
          'page': 0,
          'size': 20,
          'totalElements': 4,
          'totalPages': 1,
        },
      });
    });

    final page = await CrmRepository(ApiClient(dio)).fetchLeads(
      stage: LeadStage.newLead,
    );

    expect(captured.path, ApiEndpoints.crmLeads);
    expect(captured.method, 'GET');
    expect(captured.queryParameters['stage'], 'NEW_LEAD');
    expect(captured.queryParameters['page'], 0);
    expect(captured.queryParameters['size'], 20);
    expect(page.totalElements, 4);
    expect(page.content, hasLength(1));
    expect(page.content.first.id, 'f101fad4-06f0-488d-af5e-9bf94f582995');
    expect(page.content.first.name, 'Test Sales');
    expect(page.content.first.assignedUserName, 'Shubham Rai');
    expect(page.content.first.stage, LeadStage.newLead);
  });

  test('updateLead puts to /crm/leads/{leadId}', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'));
    late RequestOptions captured;
    final followUp = DateTime.utc(2026, 11, 26, 14, 50, 24, 318);

    dio.httpClientAdapter = JsonAdapter((options) async {
      captured = options;
      return jsonBody({
        'status': true,
        'message': 'Lead updated',
        'data': {
          'leadPublicId': 'lead-api-1',
          'name': 'Asha Verma',
          'mobile': '9876501234',
          'productInterest': 'Health Insurance',
          'stage': 'NEW_LEAD',
          'assignedEmployee': {
            'publicId': 'sales-1',
            'firstName': 'Anita',
            'lastName': 'Sharma',
          },
          'nextFollowUpAt': followUp.toIso8601String(),
          'notes': 'Updated notes',
          'createdAt': '2026-11-26T10:00:00.000Z',
          'updatedAt': '2026-11-26T15:00:00.000Z',
        },
      });
    });

    final lead = await CrmRepository(ApiClient(dio)).updateLead(
      id: 'lead-api-1',
      name: 'Asha Verma',
      mobile: '9876501234',
      productInterest: 'Health Insurance',
      stage: LeadStage.newLead,
      assignedUserId: 'sales-1',
      assignedUserName: 'Anita Sharma',
      nextFollowUpAt: followUp,
      notes: 'Updated notes',
    );

    expect(captured.path, ApiEndpoints.crmLead('lead-api-1'));
    expect(captured.method, 'PUT');
    expect(captured.data, {
      'name': 'Asha Verma',
      'mobile': '9876501234',
      'productInterest': 'Health Insurance',
      'assignedUserPublicId': 'sales-1',
      'nextFollowUpAt': followUp.toIso8601String(),
      'notes': 'Updated notes',
    });
    expect(lead.id, 'lead-api-1');
    expect(lead.stage, LeadStage.newLead);
    expect(lead.assignedUserName, 'Anita Sharma');
  });

  test('fetchActivities loads list from /crm/leads/{leadId}/activities', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'));
    late RequestOptions captured;

    dio.httpClientAdapter = JsonAdapter((options) async {
      captured = options;
      return jsonBody({
        'status': true,
        'message': 'Operation completed successfully',
        'data': [
          {
            'activityType': 'STAGE_CHANGED',
            'description': 'Lead stage changed',
            'oldValue': 'NEW_LEAD',
            'newValue': 'CONTACTED',
            'createdBy': {
              'publicId': '492dca7a-513f-46ea-a8c2-19c91cfb1db8',
              'firstName': 'Shubham',
              'lastName': 'Rai',
              'email': 'sr35285@gmail.com',
            },
            'createdAt': '2026-11-26T15:08:35.057892Z',
          },
          {
            'activityType': 'LEAD_CREATED',
            'description': 'Lead created',
            'newValue': 'NEW_LEAD',
            'createdBy': {
              'publicId': '492dca7a-513f-46ea-a8c2-19c91cfb1db8',
              'firstName': 'Shubham',
              'lastName': 'Rai',
              'email': 'sr35285@gmail.com',
            },
            'createdAt': '2026-11-26T14:38:15.955638Z',
          },
        ],
      });
    });

    final activities = await CrmRepository(
      ApiClient(dio),
    ).fetchActivities('lead-api-1');

    expect(captured.path, ApiEndpoints.crmLeadActivities('lead-api-1'));
    expect(captured.method, 'GET');
    expect(activities, hasLength(2));
    expect(activities.first.type, 'STAGE_CHANGED');
    expect(activities.first.title, 'Lead stage changed');
    expect(activities.first.detail, 'New Lead → Contacted');
    expect(activities.first.createdBy, 'Shubham Rai');
    expect(activities.last.type, 'LEAD_CREATED');
    expect(activities.last.detail, isNull);
  });

  test('fetchFollowUps loads list from /crm/leads/{leadId}/follow-ups', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'));
    late RequestOptions captured;

    dio.httpClientAdapter = JsonAdapter((options) async {
      captured = options;
      return jsonBody({
        'status': true,
        'message': 'Operation completed successfully',
        'data': [
          {
            'publicId': '1b7f1279-fa18-4e15-b7d8-4d97ce04b847',
            'discussion': 'Jvjvjvvh',
            'contactedAt': '2026-11-26T18:17:48.778369Z',
            'nextFollowUpAt': '2026-11-30T18:17:00Z',
            'createdBy': {
              'publicId': '492dca7a-513f-46ea-a8c2-19c91cfb1db8',
              'firstName': 'Shubham',
              'lastName': 'Rai',
              'email': 'sr35285@gmail.com',
            },
            'createdAt': '2026-11-26T18:18:01.250979Z',
          },
        ],
      });
    });

    final followUps = await CrmRepository(
      ApiClient(dio),
    ).fetchFollowUps('lead-api-1');

    expect(captured.path, ApiEndpoints.crmLeadFollowUps('lead-api-1'));
    expect(captured.method, 'GET');
    expect(followUps, hasLength(1));
    expect(followUps.first.id, '1b7f1279-fa18-4e15-b7d8-4d97ce04b847');
    expect(followUps.first.note, 'Jvjvjvvh');
    expect(followUps.first.createdBy, 'Shubham Rai');
    expect(followUps.first.contactedAt, isNotNull);
  });

  test('updateStage patches /crm/leads/{leadId}/stage', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'));
    late RequestOptions captured;

    dio.httpClientAdapter = JsonAdapter((options) async {
      captured = options;
      return jsonBody({
        'status': true,
        'message': 'Stage updated',
        'data': {
          'leadPublicId': 'lead-api-1',
          'name': 'Test Sales',
          'mobile': '9638388338',
          'productInterest': 'HEALTH',
          'stage': 'CONTACTED',
          'createdAt': '2026-11-26T14:38:15.951689Z',
        },
      });
    });

    final lead = await CrmRepository(ApiClient(dio)).updateStage(
      leadId: 'lead-api-1',
      stage: LeadStage.contacted,
    );

    expect(captured.path, ApiEndpoints.crmLeadStage('lead-api-1'));
    expect(captured.method, 'PATCH');
    expect(captured.data, {'stage': 'CONTACTED'});
    expect(lead.id, 'lead-api-1');
    expect(lead.stage, LeadStage.contacted);
    expect(lead.activities.first.type, 'STAGE');
  });

  test('addFollowUp posts to /crm/leads/{leadId}/follow-ups', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'));
    late RequestOptions captured;
    final contactedAt = DateTime.utc(2026, 11, 26, 14, 59, 21, 282);
    final nextFollowUpAt = DateTime.utc(2026, 11, 27, 14, 59, 21, 282);

    dio.httpClientAdapter = JsonAdapter((options) async {
      captured = options;
      return jsonBody({
        'status': true,
        'message': 'Follow-up saved',
        'data': {
          'publicId': 'fu-1',
          'discussion': 'Spoke about premium options',
          'contactedAt': contactedAt.toIso8601String(),
          'nextFollowUpAt': nextFollowUpAt.toIso8601String(),
        },
      });
    });

    final lead = await CrmRepository(ApiClient(dio)).addFollowUp(
      leadId: 'lead-api-1',
      note: 'Spoke about premium options',
      contactedAt: contactedAt,
      reminderAt: nextFollowUpAt,
      createdBy: 'Anita Sharma',
    );

    expect(captured.path, ApiEndpoints.crmLeadFollowUps('lead-api-1'));
    expect(captured.method, 'POST');
    expect(captured.data, {
      'discussion': 'Spoke about premium options',
      'contactedAt': contactedAt.toIso8601String(),
      'nextFollowUpAt': nextFollowUpAt.toIso8601String(),
    });
    expect(lead.id, 'lead-api-1');
    expect(lead.followUps, hasLength(1));
    expect(lead.followUps.first.note, 'Spoke about premium options');
    expect(lead.nextFollowUpAt, nextFollowUpAt);
  });

  test('createLead posts to /crm/leads and maps response', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'));
    late RequestOptions captured;
    final followUp = DateTime.utc(2026, 11, 26, 10, 56, 51, 346);

    dio.httpClientAdapter = JsonAdapter((options) async {
      captured = options;
      return jsonBody({
        'status': true,
        'message': 'Lead created',
        'data': {
          'publicId': 'lead-api-1',
          'name': 'Asha Verma',
          'mobile': '9876501234',
          'productInterest': 'Health Insurance',
          'stage': 'NEW_LEAD',
          'assignedUserPublicId': 'sales-1',
          'nextFollowUpAt': followUp.toIso8601String(),
          'notes': 'Called from website form',
          'createdAt': '2026-11-26T10:00:00.000Z',
          'updatedAt': '2026-11-26T10:00:00.000Z',
        },
      });
    });

    final lead = await CrmRepository(ApiClient(dio)).createLead(
      name: 'Asha Verma',
      mobile: '9876501234',
      productInterest: 'Health Insurance',
      stage: LeadStage.newLead,
      assignedUserId: 'sales-1',
      assignedUserName: 'Anita Sharma',
      nextFollowUpAt: followUp,
      notes: 'Called from website form',
    );

    expect(captured.path, ApiEndpoints.crmLeads);
    expect(captured.method, 'POST');
    expect(captured.data, {
      'name': 'Asha Verma',
      'mobile': '9876501234',
      'productInterest': 'Health Insurance',
      'stage': 'NEW_LEAD',
      'assignedUserPublicId': 'sales-1',
      'nextFollowUpAt': followUp.toIso8601String(),
      'notes': 'Called from website form',
    });

    expect(lead.id, 'lead-api-1');
    expect(lead.name, 'Asha Verma');
    expect(lead.stage, LeadStage.newLead);
    expect(lead.assignedUserName, 'Anita Sharma');
    expect(lead.activities, hasLength(1));
    expect(lead.activities.first.type, 'CREATED');
  });
}
