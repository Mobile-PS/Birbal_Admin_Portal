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
}

class LeadActivity {
  const LeadActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.createdAt,
    this.detail,
    this.createdBy,
  });

  final String id;
  final String type;
  final String title;
  final DateTime createdAt;
  final String? detail;
  final String? createdBy;
}

class LeadFollowUp {
  const LeadFollowUp({
    required this.id,
    required this.note,
    required this.reminderAt,
    required this.createdAt,
    this.createdBy,
  });

  final String id;
  final String note;
  final DateTime reminderAt;
  final DateTime createdAt;
  final String? createdBy;
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
}
