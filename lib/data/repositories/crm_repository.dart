import 'package:flutter/foundation.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/api_response.dart';
import '../../core/utils/json_utils.dart';
import '../models/lead_models.dart';

/// CRM repository.
///
/// List/create/update/follow-up use live APIs. Detail still uses a local
/// cache (hydrated from list/create/update/follow-up) until a detail endpoint
/// is wired.
class CrmRepository {
  CrmRepository(this._client);

  final ApiClient _client;

  static final List<LeadSummary> _leads = [];
  static var _sequence = 0;

  @visibleForTesting
  static void resetForTest() {
    _leads.clear();
    _sequence = 0;
  }

  /// Loads staff users for the assignee dropdown via `GET /users/staff-directory`.
  Future<List<SalesAssignee>> fetchSalesAssignees() async {
    final data = await _client.get(ApiEndpoints.usersStaffDirectory);

    if (data is! Map) {
      throw const ApiException(
        'Unexpected response while loading sales users.',
      );
    }

    final body = Map<String, dynamic>.from(data);
    ApiResponse.ensureSuccess(body);

    return ApiResponse.dataList(body)
        .map(SalesAssignee.fromJson)
        .where((user) => user.id.isNotEmpty)
        .toList(growable: false);
  }

  String _nextId() {
    _sequence += 1;
    return 'lead-local-$_sequence';
  }

  void _upsertLead(LeadSummary lead) {
    final index = _leads.indexWhere((item) => item.id == lead.id);
    if (index < 0) {
      _leads.insert(0, lead);
      return;
    }

    final existing = _leads[index];
    _leads[index] = lead.copyWith(
      notes: lead.notes ?? existing.notes,
      followUps: lead.followUps.isNotEmpty ? lead.followUps : existing.followUps,
      activities:
          lead.activities.isNotEmpty ? lead.activities : existing.activities,
    );
  }

  /// Loads leads via `GET /crm/leads`.
  Future<LeadsPage> fetchLeads({
    LeadStage? stage,
    int page = 0,
    int size = 20,
  }) async {
    final data = await _client.get(
      ApiEndpoints.crmLeads,
      queryParameters: {
        'stage': stage?.apiValue ?? '',
        'page': page,
        'size': size,
      },
    );

    if (data is! Map) {
      throw const ApiException('Unexpected response while loading leads.');
    }

    final body = Map<String, dynamic>.from(data);
    ApiResponse.ensureSuccess(body);

    final pageData = LeadsPage.fromJson(ApiResponse.dataMap(body));
    for (final lead in pageData.content) {
      _upsertLead(lead);
    }
    return pageData;
  }

  Future<LeadSummary?> getLead(String id) async {
    for (final lead in _leads) {
      if (lead.id == id) return lead;
    }
    return null;
  }

  /// Loads follow-ups via `GET /crm/leads/{leadId}/follow-ups`.
  Future<List<LeadFollowUp>> fetchFollowUps(String leadId) async {
    final data = await _client.get(ApiEndpoints.crmLeadFollowUps(leadId));

    if (data is! Map) {
      throw const ApiException(
        'Unexpected response while loading follow-ups.',
      );
    }

    final body = Map<String, dynamic>.from(data);
    ApiResponse.ensureSuccess(body);

    final followUps = ApiResponse.dataList(body)
        .map(LeadFollowUp.fromJson)
        .toList(growable: false);

    final existing = await getLead(leadId);
    if (existing != null) {
      _upsertLead(existing.copyWith(followUps: followUps));
    }
    return followUps;
  }

  /// Loads activities via `GET /crm/leads/{leadId}/activities`.
  Future<List<LeadActivity>> fetchActivities(String leadId) async {
    final data = await _client.get(ApiEndpoints.crmLeadActivities(leadId));

    if (data is! Map) {
      throw const ApiException(
        'Unexpected response while loading activities.',
      );
    }

    final body = Map<String, dynamic>.from(data);
    ApiResponse.ensureSuccess(body);

    final activities = ApiResponse.dataList(body)
        .map(LeadActivity.fromJson)
        .toList(growable: false);

    final existing = await getLead(leadId);
    if (existing != null) {
      _upsertLead(existing.copyWith(activities: activities));
    }
    return activities;
  }

  /// Creates a lead via `POST /crm/leads`.
  Future<LeadSummary> createLead({
    required String name,
    required String mobile,
    required String productInterest,
    required LeadStage stage,
    String? assignedUserId,
    String? assignedUserName,
    DateTime? nextFollowUpAt,
    String? notes,
  }) async {
    final cleanedNotes = notes?.trim();
    final payload = <String, dynamic>{
      'name': name.trim(),
      'mobile': mobile.trim(),
      'productInterest': productInterest.trim(),
      'stage': stage.apiValue,
      if (assignedUserId != null && assignedUserId.trim().isNotEmpty)
        'assignedUserPublicId': assignedUserId.trim(),
      if (nextFollowUpAt != null)
        'nextFollowUpAt': nextFollowUpAt.toUtc().toIso8601String(),
      if (cleanedNotes != null && cleanedNotes.isNotEmpty) 'notes': cleanedNotes,
    };

    final data = await _client.post(ApiEndpoints.crmLeads, data: payload);

    if (data is! Map) {
      throw const ApiException('Unexpected response while creating lead.');
    }

    final body = Map<String, dynamic>.from(data);
    ApiResponse.ensureSuccess(body);

    final now = DateTime.now();
    final responseData = ApiResponse.dataMap(body);
    final createdActivity = LeadActivity(
      id: _nextId(),
      type: 'CREATED',
      title: 'Lead created',
      detail: cleanedNotes,
      createdAt: now,
      createdBy: assignedUserName ?? 'Admin',
    );
    final lead = responseData.isEmpty
        ? LeadSummary(
            id: _nextId(),
            name: name.trim(),
            mobile: mobile.trim(),
            productInterest: productInterest.trim(),
            stage: stage,
            assignedUserId: assignedUserId,
            assignedUserName: assignedUserName,
            nextFollowUpAt: nextFollowUpAt,
            notes: (cleanedNotes == null || cleanedNotes.isEmpty)
                ? null
                : cleanedNotes,
            createdAt: now,
            updatedAt: now,
            activities: [createdActivity],
          )
        : LeadSummary.fromJson(responseData).copyWith(
            assignedUserName: assignedUserName,
            activities: [createdActivity],
          );

    _upsertLead(lead);
    return lead;
  }

  /// Updates a lead via `PUT /crm/leads/{leadId}`.
  ///
  /// Stage is applied separately via `PATCH /crm/leads/{leadId}/stage` when it
  /// changes.
  Future<LeadSummary> updateLead({
    required String id,
    required String name,
    required String mobile,
    required String productInterest,
    required LeadStage stage,
    String? assignedUserId,
    String? assignedUserName,
    DateTime? nextFollowUpAt,
    String? notes,
  }) async {
    final cleanedNotes = notes?.trim();
    final payload = <String, dynamic>{
      'name': name.trim(),
      'mobile': mobile.trim(),
      'productInterest': productInterest.trim(),
      if (assignedUserId != null && assignedUserId.trim().isNotEmpty)
        'assignedUserPublicId': assignedUserId.trim(),
      if (nextFollowUpAt != null)
        'nextFollowUpAt': nextFollowUpAt.toUtc().toIso8601String(),
      if (cleanedNotes != null && cleanedNotes.isNotEmpty) 'notes': cleanedNotes,
    };

    final data = await _client.put(ApiEndpoints.crmLead(id), data: payload);

    if (data is! Map) {
      throw const ApiException('Unexpected response while updating lead.');
    }

    final body = Map<String, dynamic>.from(data);
    ApiResponse.ensureSuccess(body);

    final now = DateTime.now();
    final existing = await getLead(id);
    final responseData = ApiResponse.dataMap(body);
    final activities = List<LeadActivity>.from(existing?.activities ?? const []);

    if (existing != null && existing.stage != stage) {
      activities.insert(
        0,
        LeadActivity(
          id: _nextId(),
          type: 'STAGE',
          title: 'Stage updated to ${stage.label}',
          createdAt: now,
          createdBy: assignedUserName ?? existing.assignedUserName ?? 'Admin',
        ),
      );
    }

    if (existing != null &&
        (cleanedNotes ?? '') != (existing.notes ?? '')) {
      activities.insert(
        0,
        LeadActivity(
          id: _nextId(),
          type: 'NOTE',
          title: 'Notes updated',
          detail: cleanedNotes?.isEmpty == true ? null : cleanedNotes,
          createdAt: now,
          createdBy: assignedUserName ?? existing.assignedUserName ?? 'Admin',
        ),
      );
    }

    final parsed = responseData.isEmpty
        ? null
        : LeadSummary.fromJson(responseData);
    final updated = (parsed ??
            existing ??
            LeadSummary(
              id: id,
              name: name.trim(),
              mobile: mobile.trim(),
              productInterest: productInterest.trim(),
              stage: stage,
              createdAt: now,
              updatedAt: now,
            ))
        .copyWith(
          name: name.trim(),
          mobile: mobile.trim(),
          productInterest: productInterest.trim(),
          stage: stage,
          assignedUserId: assignedUserId ?? parsed?.assignedUserId,
          assignedUserName: assignedUserName ?? parsed?.assignedUserName,
          nextFollowUpAt: nextFollowUpAt ?? parsed?.nextFollowUpAt,
          notes: cleanedNotes?.isEmpty == true
              ? null
              : (cleanedNotes ?? parsed?.notes ?? existing?.notes),
          clearAssignee: assignedUserId == null && parsed?.assignedUserId == null,
          clearNextFollowUp:
              nextFollowUpAt == null && parsed?.nextFollowUpAt == null,
          clearNotes: cleanedNotes == null || cleanedNotes.isEmpty,
          updatedAt: now,
          activities: activities,
          followUps: existing?.followUps ?? parsed?.followUps,
        );

    _upsertLead(updated);

    if (existing != null && existing.stage != stage) {
      return updateStage(leadId: id, stage: stage);
    }
    return updated;
  }

  /// Adds a follow-up via `POST /crm/leads/{leadId}/follow-ups`.
  Future<LeadSummary> addFollowUp({
    required String leadId,
    required String note,
    required DateTime contactedAt,
    required DateTime reminderAt,
    String? createdBy,
  }) async {
    final discussion = note.trim();
    final payload = <String, dynamic>{
      'discussion': discussion,
      'contactedAt': contactedAt.toUtc().toIso8601String(),
      'nextFollowUpAt': reminderAt.toUtc().toIso8601String(),
    };

    final data = await _client.post(
      ApiEndpoints.crmLeadFollowUps(leadId),
      data: payload,
    );

    if (data is! Map) {
      throw const ApiException('Unexpected response while saving follow-up.');
    }

    final body = Map<String, dynamic>.from(data);
    ApiResponse.ensureSuccess(body);

    final existing = await getLead(leadId);
    final now = DateTime.now();
    final responseData = ApiResponse.dataMap(body);

    final followUpId = jsonString(
      responseData['publicId'] ??
          responseData['followUpPublicId'] ??
          responseData['id'],
      fallback: _nextId(),
    );
    final followUp = LeadFollowUp(
      id: followUpId,
      note: jsonNullableString(responseData['discussion']) ?? discussion,
      reminderAt: _parseDate(responseData['nextFollowUpAt']) ?? reminderAt,
      createdAt: _parseDate(responseData['contactedAt']) ?? contactedAt,
      createdBy: createdBy ?? existing?.assignedUserName ?? 'Admin',
    );

    final activities = [
      LeadActivity(
        id: _nextId(),
        type: 'FOLLOW_UP',
        title: 'Follow-up logged',
        detail: followUp.note,
        createdAt: now,
        createdBy: followUp.createdBy,
      ),
      ...?existing?.activities,
    ];

    final base = existing ??
        LeadSummary(
          id: leadId,
          name: 'Lead',
          mobile: '',
          productInterest: '',
          stage: LeadStage.followUp,
          createdAt: now,
          updatedAt: now,
        );

    final updated = base.copyWith(
      nextFollowUpAt: followUp.reminderAt,
      stage: base.stage == LeadStage.newLead ? LeadStage.followUp : base.stage,
      updatedAt: now,
      followUps: [followUp, ...base.followUps],
      activities: activities,
    );
    _upsertLead(updated);
    return updated;
  }

  DateTime? _parseDate(Object? value) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  /// Updates lead stage via `PATCH /crm/leads/{leadId}/stage`.
  Future<LeadSummary> updateStage({
    required String leadId,
    required LeadStage stage,
  }) async {
    final data = await _client.patch(
      ApiEndpoints.crmLeadStage(leadId),
      data: {'stage': stage.apiValue},
    );

    if (data is! Map) {
      throw const ApiException('Unexpected response while updating stage.');
    }

    final body = Map<String, dynamic>.from(data);
    ApiResponse.ensureSuccess(body);

    final now = DateTime.now();
    final existing = await getLead(leadId);
    final responseData = ApiResponse.dataMap(body);
    final activities = List<LeadActivity>.from(existing?.activities ?? const []);

    if (existing == null || existing.stage != stage) {
      activities.insert(
        0,
        LeadActivity(
          id: _nextId(),
          type: 'STAGE',
          title: 'Stage updated to ${stage.label}',
          createdAt: now,
          createdBy: existing?.assignedUserName ?? 'Admin',
        ),
      );
    }

    final parsed =
        responseData.isEmpty ? null : LeadSummary.fromJson(responseData);
    final updated = (parsed ??
            existing ??
            LeadSummary(
              id: leadId,
              name: 'Lead',
              mobile: '',
              productInterest: '',
              stage: stage,
              createdAt: now,
              updatedAt: now,
            ))
        .copyWith(
          stage: stage,
          updatedAt: now,
          activities: activities,
          followUps: existing?.followUps ?? parsed?.followUps,
        );

    _upsertLead(updated);
    return updated;
  }
}
