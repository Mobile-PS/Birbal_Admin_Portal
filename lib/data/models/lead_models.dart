import '../../core/utils/json_utils.dart';

enum LeadStage {
  newLead('NEW_LEAD', 'New Lead'),
  contacted('CONTACTED', 'Contacted'),
  followUp('FOLLOW_UP', 'Follow Up'),
  documentsPending('DOCUMENTS_PENDING', 'Documents Pending'),
  policyIssued('POLICY_ISSUED', 'Policy Issued'),
  lost('LOST', 'Lost');

  const LeadStage(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static LeadStage fromApi(String? raw) {
    final value = (raw ?? '').trim().toUpperCase().replaceAll('-', '_');
    for (final stage in LeadStage.values) {
      if (stage.apiValue == value) return stage;
    }
    return LeadStage.newLead;
  }
}

class SalesAssignee {
  const SalesAssignee({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory SalesAssignee.fromJson(Map<String, dynamic> json) {
    final first = jsonNullableString(json['firstName'] ?? json['first_name']);
    final last = jsonNullableString(json['lastName'] ?? json['last_name']);
    final composed = [
      ?first,
      ?last,
    ].join(' ').trim();

    return SalesAssignee(
      id: jsonString(
        json['publicId'] ?? json['userPublicId'] ?? json['id'],
      ),
      name: composed.isNotEmpty
          ? composed
          : jsonString(
              json['name'] ?? json['fullName'] ?? json['full_name'],
              fallback: 'Sales user',
            ),
    );
  }
}

class LeadActivity {
  const LeadActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.createdAt,
    this.detail,
    this.createdBy,
    this.oldValue,
    this.newValue,
  });

  final String id;
  final String type;
  final String title;
  final DateTime createdAt;
  final String? detail;
  final String? createdBy;
  final String? oldValue;
  final String? newValue;

  factory LeadActivity.fromJson(Map<String, dynamic> json) {
    final createdAt =
        LeadSummary.parseDate(json['createdAt'] ?? json['created_at']) ??
            DateTime.now();
    final type = jsonString(
      json['activityType'] ?? json['type'],
      fallback: 'ACTIVITY',
    );
    final title = jsonString(
      json['description'] ?? json['title'],
      fallback: type,
    );
    final oldValue = jsonNullableString(json['oldValue']);
    final newValue = jsonNullableString(json['newValue']);

    final createdByRaw = json['createdBy'];
    final createdByMap = createdByRaw is Map
        ? Map<String, dynamic>.from(createdByRaw)
        : const <String, dynamic>{};
    final first = jsonNullableString(
      createdByMap['firstName'] ?? createdByMap['first_name'],
    );
    final last = jsonNullableString(
      createdByMap['lastName'] ?? createdByMap['last_name'],
    );
    final composed = [
      ?first,
      ?last,
    ].join(' ').trim();

    return LeadActivity(
      id: jsonString(
        json['publicId'] ?? json['id'],
        fallback: '${type}_${createdAt.toUtc().toIso8601String()}',
      ),
      type: type,
      title: title,
      createdAt: createdAt,
      detail: _detailFor(type: type, oldValue: oldValue, newValue: newValue),
      createdBy: composed.isNotEmpty
          ? composed
          : jsonNullableString(
              json['createdByName'] ??
                  createdByMap['name'] ??
                  createdByMap['fullName'] ??
                  (createdByRaw is String ? createdByRaw : null),
            ),
      oldValue: oldValue,
      newValue: newValue,
    );
  }

  static String? _detailFor({
    required String type,
    String? oldValue,
    String? newValue,
  }) {
    final normalized = type.trim().toUpperCase();
    final hideRawIds = normalized == 'FOLLOW_UP_ADDED' ||
        normalized == 'ASSIGNED' ||
        normalized == 'LEAD_CREATED';

    String display(String value) {
      if (normalized == 'STAGE_CHANGED') {
        return LeadStage.fromApi(value).label;
      }
      return value;
    }

    if (oldValue != null && newValue != null) {
      return '${display(oldValue)} → ${display(newValue)}';
    }
    if (newValue != null && !hideRawIds) {
      return display(newValue);
    }
    return null;
  }
}

class LeadFollowUp {
  const LeadFollowUp({
    required this.id,
    required this.note,
    required this.reminderAt,
    required this.createdAt,
    this.contactedAt,
    this.createdBy,
  });

  final String id;
  final String note;
  final DateTime reminderAt;
  final DateTime createdAt;
  final DateTime? contactedAt;
  final String? createdBy;

  factory LeadFollowUp.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final createdByRaw = json['createdBy'];
    final createdByMap = createdByRaw is Map
        ? Map<String, dynamic>.from(createdByRaw)
        : const <String, dynamic>{};
    final first = jsonNullableString(
      createdByMap['firstName'] ?? createdByMap['first_name'],
    );
    final last = jsonNullableString(
      createdByMap['lastName'] ?? createdByMap['last_name'],
    );
    final composed = [
      ?first,
      ?last,
    ].join(' ').trim();

    final contactedAt = LeadSummary.parseDate(json['contactedAt']);
    final createdAt =
        LeadSummary.parseDate(json['createdAt'] ?? json['created_at']) ??
            contactedAt ??
            now;

    return LeadFollowUp(
      id: jsonString(
        json['publicId'] ?? json['followUpPublicId'] ?? json['id'],
      ),
      note: jsonString(
        json['discussion'] ?? json['note'],
        fallback: 'Follow-up',
      ),
      reminderAt: LeadSummary.parseDate(
            json['nextFollowUpAt'] ?? json['reminderAt'],
          ) ??
          createdAt,
      createdAt: createdAt,
      contactedAt: contactedAt,
      createdBy: composed.isNotEmpty
          ? composed
          : jsonNullableString(
              json['createdByName'] ??
                  createdByMap['name'] ??
                  createdByMap['fullName'] ??
                  (createdByRaw is String ? createdByRaw : null),
            ),
    );
  }
}

class LeadSummary {
  const LeadSummary({
    required this.id,
    required this.name,
    required this.mobile,
    required this.productInterest,
    required this.stage,
    required this.createdAt,
    required this.updatedAt,
    this.assignedUserId,
    this.assignedUserName,
    this.nextFollowUpAt,
    this.notes,
    this.followUps = const [],
    this.activities = const [],
  });

  final String id;
  final String name;
  final String mobile;
  final String productInterest;
  final LeadStage stage;
  final String? assignedUserId;
  final String? assignedUserName;
  final DateTime? nextFollowUpAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<LeadFollowUp> followUps;
  final List<LeadActivity> activities;

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  LeadSummary copyWith({
    String? id,
    String? name,
    String? mobile,
    String? productInterest,
    LeadStage? stage,
    String? assignedUserId,
    String? assignedUserName,
    DateTime? nextFollowUpAt,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<LeadFollowUp>? followUps,
    List<LeadActivity>? activities,
    bool clearNextFollowUp = false,
    bool clearAssignee = false,
    bool clearNotes = false,
  }) {
    return LeadSummary(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      productInterest: productInterest ?? this.productInterest,
      stage: stage ?? this.stage,
      assignedUserId:
          clearAssignee ? null : (assignedUserId ?? this.assignedUserId),
      assignedUserName:
          clearAssignee ? null : (assignedUserName ?? this.assignedUserName),
      nextFollowUpAt:
          clearNextFollowUp ? null : (nextFollowUpAt ?? this.nextFollowUpAt),
      notes: clearNotes ? null : (notes ?? this.notes),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      followUps: followUps ?? this.followUps,
      activities: activities ?? this.activities,
    );
  }

  factory LeadSummary.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final assigned = json['assignedEmployee'] ?? json['assignedUser'];
    final assignedMap = assigned is Map
        ? Map<String, dynamic>.from(assigned)
        : const <String, dynamic>{};
    final assignedName = () {
      final first = jsonNullableString(
        assignedMap['firstName'] ?? assignedMap['first_name'],
      );
      final last = jsonNullableString(
        assignedMap['lastName'] ?? assignedMap['last_name'],
      );
      final composed = [
        ?first,
        ?last,
      ].join(' ').trim();
      if (composed.isNotEmpty) return composed;
      return jsonNullableString(
        json['assignedUserName'] ??
            assignedMap['name'] ??
            assignedMap['fullName'],
      );
    }();
    final createdAt =
        parseDate(json['createdAt'] ?? json['created_at']) ?? now;

    return LeadSummary(
      id: jsonString(
        json['leadPublicId'] ?? json['publicId'] ?? json['id'],
        fallback: jsonString(json['leadId']),
      ),
      name: jsonString(json['name'], fallback: 'Lead'),
      mobile: jsonString(json['mobile']),
      productInterest: jsonString(
        json['productInterest'] ?? json['product_interest'],
      ),
      stage: LeadStage.fromApi(jsonNullableString(json['stage'])),
      assignedUserId: jsonNullableString(
        json['assignedUserPublicId'] ??
            json['assignedUserId'] ??
            assignedMap['publicId'] ??
            assignedMap['id'],
      ),
      assignedUserName: assignedName,
      nextFollowUpAt: parseDate(
        json['nextFollowUpAt'] ?? json['next_follow_up_at'],
      ),
      notes: jsonNullableString(json['notes']),
      createdAt: createdAt,
      updatedAt:
          parseDate(json['updatedAt'] ?? json['updated_at']) ?? createdAt,
    );
  }

  static DateTime? parseDate(Object? value) {
    final raw = jsonNullableString(value);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }
}

class LeadsPage {
  const LeadsPage({
    required this.content,
    required this.last,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  final List<LeadSummary> content;
  final bool last;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  factory LeadsPage.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'];
    final content = <LeadSummary>[];
    if (rawContent is List) {
      for (final item in rawContent) {
        if (item is Map) {
          content.add(LeadSummary.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return LeadsPage(
      content: content,
      last: json['last'] == true,
      page: jsonInt(json['page']),
      size: jsonInt(json['size'], fallback: 20),
      totalElements: jsonInt(json['totalElements']),
      totalPages: jsonInt(json['totalPages']),
    );
  }

  static const empty = LeadsPage(
    content: [],
    last: true,
    page: 0,
    size: 20,
    totalElements: 0,
    totalPages: 0,
  );
}
