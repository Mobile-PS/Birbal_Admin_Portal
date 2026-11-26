import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../app/theme/app_colors.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/phone_launcher.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/models/lead_models.dart';
import '../../data/repositories/crm_repository.dart';

class LeadDetailPage extends StatefulWidget {
  const LeadDetailPage({required this.leadId, super.key});

  final String leadId;

  @override
  State<LeadDetailPage> createState() => _LeadDetailPageState();
}

class _LeadDetailPageState extends State<LeadDetailPage> {
  static const _accent = Color(0xFF2F6BFF);

  LeadSummary? _lead;
  String? _error;
  bool _isLoading = true;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final repository = CrmRepository(AppScope.of(context).apiClient);
    try {
      final lead = await repository.getLead(widget.leadId);
      if (!mounted) return;
      if (lead == null) {
        setState(() {
          _error = 'Lead could not be found.';
          _isLoading = false;
        });
        return;
      }

      List<LeadFollowUp> followUps = lead.followUps;
      List<LeadActivity> activities = lead.activities;
      try {
        final results = await Future.wait([
          repository.fetchFollowUps(widget.leadId),
          repository.fetchActivities(widget.leadId),
        ]);
        followUps = results[0] as List<LeadFollowUp>;
        activities = results[1] as List<LeadActivity>;
      } on ApiException {
        // Keep any cached timeline data if list calls fail.
      }

      if (!mounted) return;
      setState(() {
        _lead = lead.copyWith(
          followUps: followUps,
          activities: activities,
        );
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load lead details.';
        _isLoading = false;
      });
    }
  }

  Future<void> _editLead() async {
    final updated = await context.push<bool>(
      '/crm/edit',
      extra: widget.leadId,
    );
    if (updated == true && mounted) {
      _changed = true;
      await _load();
    }
  }

  Future<void> _addFollowUp() async {
    final result = await showModalBottomSheet<_FollowUpDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _AddFollowUpSheet(),
    );
    if (result == null || !mounted) return;

    try {
      final repository = CrmRepository(AppScope.of(context).apiClient);
      final updated = await repository.addFollowUp(
        leadId: widget.leadId,
        note: result.note,
        contactedAt: result.contactedAt,
        reminderAt: result.reminderAt,
        createdBy: _lead?.assignedUserName,
      );
      List<LeadFollowUp> followUps = updated.followUps;
      List<LeadActivity> activities = updated.activities;
      try {
        final results = await Future.wait([
          repository.fetchFollowUps(widget.leadId),
          repository.fetchActivities(widget.leadId),
        ]);
        followUps = results[0] as List<LeadFollowUp>;
        activities = results[1] as List<LeadActivity>;
      } on ApiException {
        // Keep the locally merged timeline if refresh fails.
      }
      if (!mounted) return;
      setState(() {
        _lead = updated.copyWith(
          followUps: followUps,
          activities: activities,
        );
        _changed = true;
      });
      showAppMessage(context, 'Follow-up saved', 'Follow-up logged successfully.');
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppMessage(context, 'Unable to save follow-up', error.message);
    } catch (_) {
      if (!mounted) return;
      showAppMessage(context, 'Unable to save follow-up', 'Please try again.');
    }
  }

  Future<void> _changeStage(LeadStage stage) async {
    if (_lead == null || _lead!.stage == stage) return;
    try {
      final repository = CrmRepository(AppScope.of(context).apiClient);
      final updated = await repository.updateStage(
        leadId: widget.leadId,
        stage: stage,
      );
      List<LeadActivity> activities = updated.activities;
      try {
        activities = await repository.fetchActivities(widget.leadId);
      } on ApiException {
        // Keep the locally merged activities if refresh fails.
      }
      if (!mounted) return;
      setState(() {
        _lead = updated.copyWith(activities: activities);
        _changed = true;
      });
      showAppMessage(context, 'Stage updated', updated.stage.label);
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppMessage(context, 'Unable to update stage', error.message);
    } catch (_) {
      if (!mounted) return;
      showAppMessage(context, 'Unable to update stage', 'Please try again.');
    }
  }

  Future<void> _callLead(String mobile) async {
    final launched = await launchPhoneCall(mobile);
    if (!mounted || launched) return;
    showAppMessage(
      context,
      'Unable to call',
      'Could not open the phone dialer.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(_changed),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: AppColors.navy,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Lead details',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit lead',
                      onPressed: _lead == null ? null : _editLead,
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildBody(bottomSafe)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(double bottomSafe) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _lead == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error ?? 'Lead unavailable',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final lead = _lead!;
    return ListView(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomSafe),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE6EEF0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFFE8F0FF),
                    child: Text(
                      lead.initials,
                      style: const TextStyle(
                        color: Color(0xFF2F6BFF),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lead.name,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lead.productInterest,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _InfoRow(label: 'Mobile', value: lead.mobile),
              _InfoRow(
                label: 'Assigned',
                value: lead.assignedUserName ?? 'Unassigned',
              ),
              _InfoRow(
                label: 'Next follow-up',
                value: lead.nextFollowUpAt == null
                    ? 'Not set'
                    : _formatDateTime(lead.nextFollowUpAt!),
              ),
              if (lead.notes != null && lead.notes!.isNotEmpty)
                _InfoRow(label: 'Notes', value: lead.notes!),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final stage in LeadStage.values)
                    ChoiceChip(
                      label: Text(stage.label),
                      selected: lead.stage == stage,
                      onSelected: (_) => _changeStage(stage),
                      selectedColor: _accent.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: lead.stage == stage
                            ? _accent
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                      side: BorderSide(
                        color: lead.stage == stage
                            ? _accent
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _callLead(lead.mobile),
                      icon: const Icon(Icons.call_outlined, size: 18),
                      label: const Text('Call'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _addFollowUp,
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.add_task_rounded, size: 18),
                      label: const Text('Add Follow-up'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Follow-ups',
          style: TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        if (lead.followUps.isEmpty)
          const _EmptyCard(message: 'No follow-ups logged yet.')
        else
          for (final item in lead.followUps) ...[
            _FollowUpCard(followUp: item),
            const SizedBox(height: 10),
          ],
        const SizedBox(height: 10),
        const Text(
          'Activity timeline',
          style: TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        if (lead.activities.isEmpty)
          const _EmptyCard(message: 'No activity yet.')
        else
          for (final activity in lead.activities) ...[
            _ActivityCard(activity: activity),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowUpCard extends StatelessWidget {
  const _FollowUpCard({required this.followUp});

  final LeadFollowUp followUp;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6EEF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            followUp.note,
            style: const TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          if (followUp.contactedAt != null) ...[
            const SizedBox(height: 6),
            Text(
              'Contacted: ${_formatDateTime(followUp.contactedAt!)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'Next follow-up: ${_formatDateTime(followUp.reminderAt)}',
            style: const TextStyle(
              color: Color(0xFFB54708),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Logged ${_formatDateTime(followUp.createdAt)}'
            '${followUp.createdBy == null ? '' : ' · ${followUp.createdBy}'}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});

  final LeadActivity activity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6EEF0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 5),
            decoration: const BoxDecoration(
              color: Color(0xFF2F6BFF),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
                if (activity.detail != null && activity.detail!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    activity.detail!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${_formatDateTime(activity.createdAt)}'
                  '${activity.createdBy == null ? '' : ' · ${activity.createdBy}'}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6EEF0)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

class _FollowUpDraft {
  const _FollowUpDraft({
    required this.note,
    required this.contactedAt,
    required this.reminderAt,
  });

  final String note;
  final DateTime contactedAt;
  final DateTime reminderAt;
}

class _AddFollowUpSheet extends StatefulWidget {
  const _AddFollowUpSheet();

  @override
  State<_AddFollowUpSheet> createState() => _AddFollowUpSheetState();
}

class _AddFollowUpSheetState extends State<_AddFollowUpSheet> {
  final _noteController = TextEditingController();
  DateTime _contactedAt = DateTime.now();
  DateTime? _reminderAt;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime({
    required DateTime initial,
    required DateTime firstDate,
  }) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return null;
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  Future<void> _pickContactedAt() async {
    final now = DateTime.now();
    final picked = await _pickDateTime(
      initial: _contactedAt,
      firstDate: now.subtract(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => _contactedAt = picked);
  }

  Future<void> _pickReminder() async {
    final now = DateTime.now();
    final picked = await _pickDateTime(
      initial: _reminderAt ?? now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
    );
    if (picked == null) return;
    setState(() => _reminderAt = picked);
  }

  void _submit() {
    final note = _noteController.text.trim();
    if (note.isEmpty) {
      showAppMessage(context, 'Discussion required', 'Enter what was discussed.');
      return;
    }
    if (_reminderAt == null) {
      showAppMessage(
        context,
        'Next follow-up required',
        'Pick the next follow-up date.',
      );
      return;
    }
    Navigator.of(context).pop(
      _FollowUpDraft(
        note: note,
        contactedAt: _contactedAt,
        reminderAt: _reminderAt!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Add Follow-up',
            style: TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _noteController,
            minLines: 3,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Discussion notes',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickContactedAt,
            icon: const Icon(Icons.call_rounded),
            label: Text('Contacted: ${_formatDateTime(_contactedAt)}'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickReminder,
            icon: const Icon(Icons.event_rounded),
            label: Text(
              _reminderAt == null
                  ? 'Pick next follow-up date & time'
                  : 'Next follow-up: ${_formatDateTime(_reminderAt!)}',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2F6BFF),
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Save Follow-up'),
          ),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '${local.day} ${months[local.month - 1]} ${local.year}, $hour:$minute $period';
}
