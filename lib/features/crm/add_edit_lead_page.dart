import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/models/lead_models.dart';
import '../../data/repositories/crm_repository.dart';

class AddEditLeadPage extends StatefulWidget {
  const AddEditLeadPage({this.leadId, super.key});

  final String? leadId;

  @override
  State<AddEditLeadPage> createState() => _AddEditLeadPageState();
}

class _AddEditLeadPageState extends State<AddEditLeadPage> {
  static const _accent = Color(0xFF2F6BFF);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _productController = TextEditingController();
  final _notesController = TextEditingController();

  LeadStage _stage = LeadStage.newLead;
  String? _assigneeId;
  DateTime? _nextFollowUpAt;
  bool _isLoading = false;
  bool _isSaving = false;
  LeadSummary? _existing;

  bool get _isEditing => widget.leadId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadLead();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _productController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadLead() async {
    setState(() => _isLoading = true);
    try {
      final lead = await CrmRepository.instance.getLead(widget.leadId!);
      if (!mounted) return;
      if (lead == null) {
        showAppMessage(context, 'Unavailable', 'Lead could not be found.');
        context.pop(false);
        return;
      }
      setState(() {
        _existing = lead;
        _nameController.text = lead.name;
        _mobileController.text = lead.mobile;
        _productController.text = lead.productInterest;
        _notesController.text = lead.notes ?? '';
        _stage = lead.stage;
        _assigneeId = lead.assignedUserId;
        _nextFollowUpAt = lead.nextFollowUpAt;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showAppMessage(context, 'Unable to load lead', 'Please try again.');
    }
  }

  String? _required(String? value, String label) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$label is required';
    return null;
  }

  String? _validateMobile(String? value) {
    final mobile = value?.trim() ?? '';
    if (mobile.isEmpty) return 'Mobile number is required';
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(mobile)) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  Future<void> _pickFollowUpDate() async {
    final now = DateTime.now();
    final initial = _nextFollowUpAt ?? now.add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    setState(() {
      _nextFollowUpAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    SalesAssignee? assignee;
    for (final item in CrmRepository.assignees) {
      if (item.id == _assigneeId) {
        assignee = item;
        break;
      }
    }

    setState(() => _isSaving = true);
    try {
      if (_isEditing) {
        await CrmRepository.instance.updateLead(
          id: widget.leadId!,
          name: _nameController.text,
          mobile: _mobileController.text,
          productInterest: _productController.text,
          stage: _stage,
          assignedUserId: assignee?.id,
          assignedUserName: assignee?.name,
          nextFollowUpAt: _nextFollowUpAt,
          notes: _notesController.text,
        );
      } else {
        await CrmRepository.instance.createLead(
          name: _nameController.text,
          mobile: _mobileController.text,
          productInterest: _productController.text,
          stage: _stage,
          assignedUserId: assignee?.id,
          assignedUserName: assignee?.name,
          nextFollowUpAt: _nextFollowUpAt,
          notes: _notesController.text,
        );
      }
      if (!mounted) return;
      showAppMessage(
        context,
        _isEditing ? 'Lead updated' : 'Lead created',
        _isEditing
            ? 'Lead details saved locally.'
            : 'Lead added to the CRM list.',
      );
      context.pop(true);
    } catch (_) {
      if (!mounted) return;
      showAppMessage(
        context,
        _isEditing ? 'Unable to update lead' : 'Unable to create lead',
        'Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final title = _isEditing ? 'Edit Lead' : 'Add Lead';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _isSaving ? null : () => context.pop(false),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.navy,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        8,
                        20,
                        20 + bottomInset,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _LabeledField(
                              label: 'Name',
                              child: TextFormField(
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                decoration: _inputDecoration('Lead / prospect name'),
                                validator: (value) => _required(value, 'Name'),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _LabeledField(
                              label: 'Mobile',
                              child: TextFormField(
                                controller: _mobileController,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                decoration: _inputDecoration('10-digit mobile'),
                                validator: _validateMobile,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _LabeledField(
                              label: 'Product Interest',
                              child: TextFormField(
                                controller: _productController,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                decoration: _inputDecoration(
                                  'e.g. Health Insurance',
                                ),
                                validator: (value) =>
                                    _required(value, 'Product interest'),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _LabeledField(
                              label: 'Stage',
                              child: DropdownButtonFormField<LeadStage>(
                                key: ValueKey('lead-stage-$_stage'),
                                initialValue: _stage,
                                decoration: _inputDecoration('Select stage'),
                                items: [
                                  for (final stage in LeadStage.values)
                                    DropdownMenuItem(
                                      value: stage,
                                      child: Text(stage.label),
                                    ),
                                ],
                                onChanged: _isSaving
                                    ? null
                                    : (value) {
                                        if (value == null) return;
                                        setState(() => _stage = value);
                                      },
                              ),
                            ),
                            const SizedBox(height: 18),
                            _LabeledField(
                              label: 'Assigned User',
                              required: false,
                              child: DropdownButtonFormField<String?>(
                                key: ValueKey(
                                  'lead-assignee-${_assigneeId ?? 'none'}',
                                ),
                                initialValue: _assigneeId,
                                decoration: _inputDecoration(
                                  'Select sales user',
                                ),
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('Unassigned'),
                                  ),
                                  for (final user in CrmRepository.assignees)
                                    DropdownMenuItem(
                                      value: user.id,
                                      child: Text(user.name),
                                    ),
                                ],
                                onChanged: _isSaving
                                    ? null
                                    : (value) {
                                        setState(() => _assigneeId = value);
                                      },
                              ),
                            ),
                            const SizedBox(height: 18),
                            _LabeledField(
                              label: 'Next Follow-up',
                              required: false,
                              child: OutlinedButton.icon(
                                onPressed: _isSaving ? null : _pickFollowUpDate,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.navy,
                                  minimumSize: const Size.fromHeight(52),
                                  side: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.event_rounded),
                                label: Text(
                                  _nextFollowUpAt == null
                                      ? 'Pick date & time'
                                      : _formatDateTime(_nextFollowUpAt!),
                                ),
                              ),
                            ),
                            if (_nextFollowUpAt != null) ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: _isSaving
                                      ? null
                                      : () => setState(
                                            () => _nextFollowUpAt = null,
                                          ),
                                  child: const Text('Clear follow-up'),
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            _LabeledField(
                              label: 'Notes',
                              required: false,
                              child: TextFormField(
                                controller: _notesController,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                minLines: 3,
                                maxLines: 5,
                                decoration: _inputDecoration(
                                  'Free-text notes',
                                ),
                              ),
                            ),
                            if (_existing != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Created ${_formatDateTime(_existing!.createdAt)}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                            const SizedBox(height: 28),
                            SizedBox(
                              height: 52,
                              child: FilledButton(
                                onPressed: _isSaving ? null : _save,
                                style: FilledButton.styleFrom(
                                  backgroundColor: _accent,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: _accent.withValues(
                                    alpha: 0.45,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _isEditing ? 'Update Lead' : 'Save Lead',
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9AA6B2), fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: Color(0xFF2F6BFF), width: 1.4),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.required = true,
  });

  final String label;
  final Widget child;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: const TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            children: [
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Color(0xFFE53935),
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
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
