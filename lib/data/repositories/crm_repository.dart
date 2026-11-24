import '../models/lead_models.dart';

/// Local CRM store used until lead / follow-up APIs are available.
///
/// Replace method bodies with Dio calls once endpoints are ready. Keep the
/// public method signatures so UI wiring stays stable.
class CrmRepository {
  CrmRepository._();

  static final CrmRepository instance = CrmRepository._();

  static const assignees = <SalesAssignee>[
    SalesAssignee(id: 'sales-1', name: 'Anita Sharma'),
    SalesAssignee(id: 'sales-2', name: 'Rahul Mehta'),
    SalesAssignee(id: 'sales-3', name: 'Priya Nair'),
  ];

  final List<LeadSummary> _leads = [];
  var _seeded = false;
  var _sequence = 0;

  void _ensureSeeded() {
    if (_seeded) return;
    _seeded = true;
    final now = DateTime.now();

    _leads.addAll([
      LeadSummary(
        id: _nextId(),
        name: 'Sneha Patil',
        mobile: '9876543210',
        productInterest: 'Health Insurance',
        stage: LeadStage.newLead,
        assignedUserId: 'sales-1',
        assignedUserName: 'Anita Sharma',
        nextFollowUpAt: now.add(const Duration(days: 1)),
        notes: 'Inbound WhatsApp enquiry about family floater.',
        createdAt: now.subtract(const Duration(hours: 5)),
        updatedAt: now.subtract(const Duration(hours: 5)),
        activities: [
          LeadActivity(
            id: _nextId(),
            type: 'CREATED',
            title: 'Lead created',
            detail: 'Source: WhatsApp enquiry',
            createdAt: now.subtract(const Duration(hours: 5)),
            createdBy: 'System',
          ),
        ],
      ),
      LeadSummary(
        id: _nextId(),
        name: 'Vikram Desai',
        mobile: '9123456780',
        productInterest: 'Term Life',
        stage: LeadStage.followUp,
        assignedUserId: 'sales-2',
        assignedUserName: 'Rahul Mehta',
        nextFollowUpAt: now.add(const Duration(hours: 6)),
        notes: 'Asked for comparison between two term plans.',
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(hours: 8)),
        followUps: [
          LeadFollowUp(
            id: _nextId(),
            note: 'Shared brochure. Waiting for nominee details.',
            reminderAt: now.add(const Duration(hours: 6)),
            createdAt: now.subtract(const Duration(hours: 8)),
            createdBy: 'Rahul Mehta',
          ),
        ],
        activities: [
          LeadActivity(
            id: _nextId(),
            type: 'CREATED',
            title: 'Lead created',
            createdAt: now.subtract(const Duration(days: 2)),
            createdBy: 'System',
          ),
          LeadActivity(
            id: _nextId(),
            type: 'STAGE',
            title: 'Stage updated to Contacted',
            createdAt: now.subtract(const Duration(days: 1, hours: 4)),
            createdBy: 'Rahul Mehta',
          ),
          LeadActivity(
            id: _nextId(),
            type: 'FOLLOW_UP',
            title: 'Follow-up logged',
            detail: 'Shared brochure. Waiting for nominee details.',
            createdAt: now.subtract(const Duration(hours: 8)),
            createdBy: 'Rahul Mehta',
          ),
          LeadActivity(
            id: _nextId(),
            type: 'STAGE',
            title: 'Stage updated to Follow Up',
            createdAt: now.subtract(const Duration(hours: 8)),
            createdBy: 'Rahul Mehta',
          ),
        ],
      ),
      LeadSummary(
        id: _nextId(),
        name: 'Meera Joshi',
        mobile: '9988776655',
        productInterest: 'Motor Insurance',
        stage: LeadStage.documentsPending,
        assignedUserId: 'sales-3',
        assignedUserName: 'Priya Nair',
        nextFollowUpAt: now.add(const Duration(days: 2)),
        notes: 'RC copy pending from customer.',
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(days: 1)),
        activities: [
          LeadActivity(
            id: _nextId(),
            type: 'CREATED',
            title: 'Lead created',
            createdAt: now.subtract(const Duration(days: 4)),
            createdBy: 'System',
          ),
          LeadActivity(
            id: _nextId(),
            type: 'STAGE',
            title: 'Stage updated to Documents Pending',
            detail: 'Awaiting RC and previous policy copy',
            createdAt: now.subtract(const Duration(days: 1)),
            createdBy: 'Priya Nair',
          ),
        ],
      ),
    ]);
  }

  String _nextId() {
    _sequence += 1;
    return 'lead-local-$_sequence';
  }

  Future<List<LeadSummary>> fetchLeads({LeadStage? stage}) async {
    _ensureSeeded();
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final items = List<LeadSummary>.from(_leads);
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (stage == null) return items;
    return items.where((lead) => lead.stage == stage).toList(growable: false);
  }

  Future<LeadSummary?> getLead(String id) async {
    _ensureSeeded();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    for (final lead in _leads) {
      if (lead.id == id) return lead;
    }
    return null;
  }

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
    _ensureSeeded();
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final now = DateTime.now();
    final lead = LeadSummary(
      id: _nextId(),
      name: name.trim(),
      mobile: mobile.trim(),
      productInterest: productInterest.trim(),
      stage: stage,
      assignedUserId: assignedUserId,
      assignedUserName: assignedUserName,
      nextFollowUpAt: nextFollowUpAt,
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      createdAt: now,
      updatedAt: now,
      activities: [
        LeadActivity(
          id: _nextId(),
          type: 'CREATED',
          title: 'Lead created',
          detail: notes?.trim().isNotEmpty == true ? notes!.trim() : null,
          createdAt: now,
          createdBy: assignedUserName ?? 'Admin',
        ),
      ],
    );
    _leads.insert(0, lead);
    return lead;
  }

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
    _ensureSeeded();
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final index = _leads.indexWhere((lead) => lead.id == id);
    if (index < 0) {
      throw StateError('Lead not found.');
    }

    final existing = _leads[index];
    final now = DateTime.now();
    final activities = List<LeadActivity>.from(existing.activities);

    if (existing.stage != stage) {
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

    final cleanedNotes = notes?.trim();
    if ((cleanedNotes ?? '') != (existing.notes ?? '')) {
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

    final updated = existing.copyWith(
      name: name.trim(),
      mobile: mobile.trim(),
      productInterest: productInterest.trim(),
      stage: stage,
      assignedUserId: assignedUserId,
      assignedUserName: assignedUserName,
      nextFollowUpAt: nextFollowUpAt,
      notes: cleanedNotes?.isEmpty == true ? null : cleanedNotes,
      clearAssignee: assignedUserId == null,
      clearNextFollowUp: nextFollowUpAt == null,
      clearNotes: cleanedNotes == null || cleanedNotes.isEmpty,
      updatedAt: now,
      activities: activities,
    );
    _leads[index] = updated;
    return updated;
  }

  Future<LeadSummary> addFollowUp({
    required String leadId,
    required String note,
    required DateTime reminderAt,
    String? createdBy,
  }) async {
    _ensureSeeded();
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final index = _leads.indexWhere((lead) => lead.id == leadId);
    if (index < 0) {
      throw StateError('Lead not found.');
    }

    final existing = _leads[index];
    final now = DateTime.now();
    final followUp = LeadFollowUp(
      id: _nextId(),
      note: note.trim(),
      reminderAt: reminderAt,
      createdAt: now,
      createdBy: createdBy ?? existing.assignedUserName ?? 'Admin',
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
      ...existing.activities,
    ];

    final updated = existing.copyWith(
      nextFollowUpAt: reminderAt,
      stage: existing.stage == LeadStage.newLead
          ? LeadStage.followUp
          : existing.stage,
      updatedAt: now,
      followUps: [followUp, ...existing.followUps],
      activities: activities,
    );
    _leads[index] = updated;
    return updated;
  }

  Future<LeadSummary> updateStage({
    required String leadId,
    required LeadStage stage,
  }) async {
    _ensureSeeded();
    final existing = await getLead(leadId);
    if (existing == null) {
      throw StateError('Lead not found.');
    }
    return updateLead(
      id: existing.id,
      name: existing.name,
      mobile: existing.mobile,
      productInterest: existing.productInterest,
      stage: stage,
      assignedUserId: existing.assignedUserId,
      assignedUserName: existing.assignedUserName,
      nextFollowUpAt: existing.nextFollowUpAt,
      notes: existing.notes,
    );
  }
}
