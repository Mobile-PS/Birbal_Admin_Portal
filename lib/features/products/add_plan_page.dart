import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../app/theme/app_colors.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/document_base64.dart';
import '../../core/utils/document_picker.dart';
import '../../core/utils/policy_document_viewer.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/models/insurance_plan_model.dart';
import '../../data/repositories/insurance_repository.dart';

class AddPlanPage extends StatefulWidget {
  const AddPlanPage({
    required this.categoryCode,
    required this.categoryTitle,
    this.plan,
    super.key,
  });

  final String categoryCode;
  final String categoryTitle;

  /// When set, the page edits an existing plan.
  final InsurancePlanModel? plan;

  @override
  State<AddPlanPage> createState() => _AddPlanPageState();
}

class _AddPlanPageState extends State<AddPlanPage> {
  static const _accent = Color(0xFF2F6BFF);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _categoryController;
  late final TextEditingController _nameController;
  late final TextEditingController _insurerNameController;
  late final TextEditingController _descriptionController;

  String? _documentBase64;
  String? _documentName;
  bool _isSaving = false;

  bool get _isEditing => widget.plan != null;

  @override
  void initState() {
    super.initState();
    final plan = widget.plan;
    _codeController = TextEditingController(text: widget.categoryCode);
    _categoryController = TextEditingController(text: widget.categoryTitle);
    _nameController = TextEditingController(text: plan?.name ?? '');
    _insurerNameController = TextEditingController(text: plan?.insurerName ?? '');
    _descriptionController = TextEditingController(text: plan?.description ?? '');

    final existingDocument = DocumentBase64.normalize(
      plan?.documentBase64,
      fileName: plan?.documentFileName,
    );
    if (existingDocument != null && existingDocument.isNotEmpty) {
      _documentBase64 = existingDocument;
      _documentName = plan?.documentDisplayName;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _categoryController.dispose();
    _nameController.dispose();
    _insurerNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$label is required';
    return null;
  }

  String? _validateCode(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Code is required';
    if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(text)) {
      return 'Use letters, numbers, or underscore only';
    }
    return null;
  }

  Future<void> _pickDocument() async {
    try {
      final picked = await pickDocumentAsBase64DataUri();
      if (!mounted || picked == null) return;
      setState(() {
        _documentBase64 = picked.dataUri;
        _documentName = picked.fileName;
      });
    } catch (_) {
      if (!mounted) return;
      showAppMessage(
        context,
        'Unable to attach document',
        'Please try another file.',
      );
    }
  }

  Future<void> _viewDocument() async {
    final document = DocumentBase64.normalize(
      _documentBase64,
      fileName: _documentName,
    );
    await openBase64Document(
      context,
      documentBase64: document,
      title: _documentName ?? 'Plan document',
      fileName: _documentName,
      unavailableMessage: 'No plan document is available.',
    );
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final document = DocumentBase64.normalize(_documentBase64) ?? '';
    if (document.isEmpty) {
      showAppMessage(
        context,
        'Document required',
        _isEditing
            ? 'Please keep or attach a plan document.'
            : 'Please attach a plan document.',
      );
      return;
    }

    final repository = InsuranceRepository(AppScope.of(context).apiClient);
    final code = _codeController.text.trim().toUpperCase();
    final category = _categoryController.text.trim();
    final name = _nameController.text.trim();
    final insurerName = _insurerNameController.text.trim();
    final description = _descriptionController.text.trim();

    setState(() => _isSaving = true);
    try {
      final message = _isEditing
          ? await repository.updateInsurerData(
              planId: widget.plan!.publicId,
              code: code,
              category: category,
              name: name,
              insurerName: insurerName,
              description: description,
              documentBase64: document,
            )
          : await repository.createInsurerData(
              code: code,
              category: category,
              name: name,
              insurerName: insurerName,
              description: description,
              documentBase64: document,
            );
      if (!mounted) return;
      showAppMessage(
        context,
        _isEditing ? 'Plan updated' : 'Plan saved',
        message,
      );
      context.pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppMessage(
        context,
        _isEditing ? 'Unable to update plan' : 'Unable to add plan',
        error.message,
      );
    } catch (_) {
      if (!mounted) return;
      showAppMessage(
        context,
        _isEditing ? 'Unable to update plan' : 'Unable to add plan',
        'Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final title = _isEditing ? 'Edit Plan' : 'Add Plan';
    final actionLabel = _isEditing ? 'Update Plan' : 'Save Plan';

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
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _LabeledField(
                        label: 'Code',
                        child: TextFormField(
                          key: const ValueKey('add-plan-code'),
                          controller: _codeController,
                          enabled: false,
                          decoration: _inputDecoration('Code'),
                          validator: _validateCode,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _LabeledField(
                        label: 'Category',
                        child: TextFormField(
                          key: const ValueKey('add-plan-category'),
                          controller: _categoryController,
                          enabled: false,
                          decoration: _inputDecoration('Category'),
                          validator: (value) => _required(value, 'Category'),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _LabeledField(
                        label: 'Insurance name',
                        child: TextFormField(
                          key: const ValueKey('add-plan-name'),
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(
                            'Enter insurance name',
                          ),
                          validator: (value) =>
                              _required(value, 'Insurance name'),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _LabeledField(
                        label: 'Insurer name',
                        child: TextFormField(
                          key: const ValueKey('add-plan-insurer'),
                          controller: _insurerNameController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration('Enter insurer name'),
                          validator: (value) =>
                              _required(value, 'Insurer name'),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _LabeledField(
                        label: 'Description',
                        child: TextFormField(
                          key: const ValueKey('add-plan-description'),
                          controller: _descriptionController,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.done,
                          minLines: 3,
                          maxLines: 5,
                          decoration: _inputDecoration('Enter description'),
                          validator: (value) =>
                              _required(value, 'Description'),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _LabeledField(
                        label: 'Document',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_documentBase64 != null) ...[
                              Material(
                                color: const Color(0xFFF4F8F7),
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    12,
                                    8,
                                    12,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F0FF),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.picture_as_pdf_rounded,
                                          color: Color(0xFF2F6BFF),
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _documentName ?? 'Plan document',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: AppColors.navy,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 13.5,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _isEditing &&
                                                      _documentName ==
                                                          widget
                                                              .plan
                                                              ?.documentDisplayName
                                                  ? 'Current document'
                                                  : 'Ready to upload',
                                              style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 12.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      TextButton(
                                        key: const ValueKey(
                                          'add-plan-view-document',
                                        ),
                                        onPressed:
                                            _isSaving ? null : _viewDocument,
                                        child: const Text('View'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            OutlinedButton.icon(
                              key: const ValueKey('add-plan-document'),
                              onPressed: _isSaving ? null : _pickDocument,
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
                              icon: const Icon(Icons.attach_file_rounded),
                              label: Text(
                                _documentBase64 == null
                                    ? 'Attach PDF'
                                    : (_isEditing
                                        ? 'Replace PDF document'
                                        : 'Change PDF'),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                            minimumSize: const Size.fromHeight(52),
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
                              : Text(actionLabel),
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
      disabledBorder: border,
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
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

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
            children: const [
              TextSpan(
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
