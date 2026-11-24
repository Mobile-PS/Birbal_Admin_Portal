import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../app/theme/app_colors.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/document_picker.dart';
import '../../core/utils/policy_document_viewer.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/models/customer_summary.dart';
import '../../data/models/insurance_plan_model.dart';
import '../../data/models/product_entry.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/repositories/insurance_repository.dart';
import '../../data/repositories/policies_repository.dart';

class AddPolicyPage extends StatefulWidget {
  const AddPolicyPage({
    required this.customer,
    this.policy,
    super.key,
  });

  final CustomerSummary customer;
  final CustomerPolicySummary? policy;

  bool get isEditing => policy != null;

  @override
  State<AddPolicyPage> createState() => _AddPolicyPageState();
}

class _AddPolicyPageState extends State<AddPolicyPage> {
  static const _accent = Color(0xFF2F6BFF);

  final _formKey = GlobalKey<FormState>();
  final _policyNumberController = TextEditingController();
  final _premiumController = TextEditingController();
  final _sumInsuredController = TextEditingController();
  final _policyTermYearsController = TextEditingController(text: '1');
  final _insurerNameController = TextEditingController();

  List<ProductEntry> _categories = const [];
  List<InsurancePlanModel> _plans = const [];
  String? _selectedCategoryCode;
  String? _selectedPlanId;

  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _firstPolicyInceptionDate;
  DateTime? _renewalDate;

  String? _documentBase64;
  String? _documentName;
  bool _isLoadingCategories = true;
  bool _isLoadingPlans = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _bootstrap();
    });
  }

  @override
  void dispose() {
    _policyNumberController.dispose();
    _premiumController.dispose();
    _sumInsuredController.dispose();
    _policyTermYearsController.dispose();
    _insurerNameController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _loadCategories();
    if (!mounted || widget.policy == null) return;
    await _prefillFromPolicy(widget.policy!);
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final categories = await DashboardRepository(
        AppScope.of(context).apiClient,
      ).fetchCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _isLoadingCategories = false);
      showAppMessage(context, 'Unable to load categories', error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingCategories = false);
      showAppMessage(
        context,
        'Unable to load categories',
        'Please try again.',
      );
    }
  }

  DateTime? _parseApiDate(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  Future<void> _prefillFromPolicy(CustomerPolicySummary policy) async {
    final policyNumber =
        policy.policyNumber.trim() == '—' ? '' : policy.policyNumber.trim();
    _policyNumberController.text = policyNumber;
    _premiumController.text =
        policy.premium == null ? '' : policy.premium.toString();
    _sumInsuredController.text =
        policy.sumInsured == null ? '' : policy.sumInsured.toString();
    _policyTermYearsController.text =
        (policy.policyTermYears ?? 1).toString();
    _insurerNameController.text = policy.insurerName?.trim() ?? '';
    _startDate = _parseApiDate(policy.startDate);
    _endDate = _parseApiDate(policy.endDate);
    _firstPolicyInceptionDate = _parseApiDate(policy.firstPolicyInceptionDate);
    _renewalDate = _parseApiDate(policy.renewalDate);
    if (policy.hasDocument) {
      _documentBase64 = policy.policyDocumentBase64;
      _documentName = policy.documentDisplayName;
    }

    final categoryCode = policy.planCategory?.trim();
    if (categoryCode != null && categoryCode.isNotEmpty) {
      ProductEntry? matchedCategory;
      for (final category in _categories) {
        if (category.id.toUpperCase() == categoryCode.toUpperCase() ||
            category.productCategory.toUpperCase() ==
                categoryCode.toUpperCase()) {
          matchedCategory = category;
          break;
        }
      }
      final code = matchedCategory?.id ?? categoryCode.toUpperCase();
      await _onCategoryChanged(code);
      if (!mounted) return;

      InsurancePlanModel? matchedPlan;
      for (final plan in _plans) {
        if (plan.name.trim().toLowerCase() ==
            policy.planName.trim().toLowerCase()) {
          matchedPlan = plan;
          break;
        }
      }
      if (matchedPlan != null) {
        final plan = matchedPlan;
        setState(() {
          _selectedPlanId = plan.publicId;
          if (_insurerNameController.text.trim().isEmpty) {
            _insurerNameController.text = plan.insurerName?.trim() ?? '';
          }
        });
      }
    }

    if (mounted) setState(() {});
  }

  ProductEntry? get _selectedCategory {
    for (final category in _categories) {
      if (category.id == _selectedCategoryCode) return category;
    }
    return null;
  }

  InsurancePlanModel? get _selectedPlan {
    for (final plan in _plans) {
      if (plan.publicId == _selectedPlanId) return plan;
    }
    return null;
  }

  Future<void> _onCategoryChanged(String? categoryCode) async {
    setState(() {
      _selectedCategoryCode = categoryCode;
      _selectedPlanId = null;
      _plans = const [];
      _insurerNameController.clear();
      _isLoadingPlans = categoryCode != null;
    });
    if (categoryCode == null) return;

    try {
      final page = await InsuranceRepository(
        AppScope.of(context).apiClient,
      ).fetchPlans(category: categoryCode);
      if (!mounted) return;
      setState(() {
        _plans = page.content;
        _isLoadingPlans = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _isLoadingPlans = false);
      showAppMessage(context, 'Unable to load products', error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingPlans = false);
      showAppMessage(
        context,
        'Unable to load products',
        'Please try again.',
      );
    }
  }

  void _onPlanChanged(String? planId) {
    setState(() {
      _selectedPlanId = planId;
      final plan = _selectedPlan;
      _insurerNameController.text = plan?.insurerName?.trim() ?? '';
    });
  }

  Future<void> _pickDate({
    required DateTime? current,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) onPicked(picked);
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
        'Please try another PDF.',
      );
    }
  }

  String? _requiredText(String? value, String label) {
    if ((value ?? '').trim().isEmpty) return '$label is required';
    return null;
  }

  String? _requiredNumber(String? value, String label) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$label is required';
    if (num.tryParse(text) == null) return 'Enter a valid $label';
    return null;
  }

  String _formatApiDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatDisplayDate(DateTime? date) {
    if (date == null) return 'Select date';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final selectedCategory = _selectedCategory;
    final selectedPlan = _selectedPlan;
    if (selectedCategory == null) {
      showAppMessage(context, 'Category required', 'Please select a plan category.');
      return;
    }
    if (selectedPlan == null) {
      showAppMessage(context, 'Product required', 'Please select a product.');
      return;
    }
    if (_startDate == null ||
        _endDate == null ||
        _firstPolicyInceptionDate == null ||
        _renewalDate == null) {
      showAppMessage(
        context,
        'Dates required',
        'Please select all policy dates.',
      );
      return;
    }
    final document = _documentBase64?.trim() ?? '';
    if (document.isEmpty) {
      showAppMessage(
        context,
        'Document required',
        'Please attach a policy PDF.',
      );
      return;
    }

    final userPublicId =
        (widget.customer.userPublicId ?? widget.customer.id).trim();
    final customerId = widget.customer.id.trim();
    if (userPublicId.isEmpty || customerId.isEmpty) {
      showAppMessage(
        context,
        'Customer missing',
        'Selected customer is missing required IDs.',
      );
      return;
    }

    final policyNumber = _policyNumberController.text.trim();
    if (widget.isEditing && policyNumber.isEmpty) {
      showAppMessage(
        context,
        'Policy number required',
        'Please enter the policy number.',
      );
      return;
    }

    final policyId = widget.policy?.policyPublicId.trim() ?? '';
    if (widget.isEditing && policyId.isEmpty) {
      showAppMessage(
        context,
        'Unable to update policy',
        'Policy id is missing.',
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repository = PoliciesRepository(AppScope.of(context).apiClient);
      final String message;
      if (widget.isEditing) {
        message = await repository.updatePolicy(
          policyId: policyId,
          userPublicId: userPublicId,
          customerId: customerId,
          planCategory: selectedCategory.id,
          productName: selectedPlan.name,
          insurerName: _insurerNameController.text.trim(),
          policyNumber: policyNumber,
          startDate: _formatApiDate(_startDate!),
          endDate: _formatApiDate(_endDate!),
          firstPolicyInceptionDate: _formatApiDate(_firstPolicyInceptionDate!),
          renewalDate: _formatApiDate(_renewalDate!),
          premium: num.parse(_premiumController.text.trim()),
          sumInsured: num.parse(_sumInsuredController.text.trim()),
          policyTermYears: int.parse(_policyTermYearsController.text.trim()),
          policyDocumentBase64: document,
        );
      } else {
        message = await repository.createPolicy(
          userPublicId: userPublicId,
          customerId: customerId,
          planCategory: selectedCategory.id,
          productName: selectedPlan.name,
          insurerName: _insurerNameController.text.trim(),
          startDate: _formatApiDate(_startDate!),
          endDate: _formatApiDate(_endDate!),
          firstPolicyInceptionDate: _formatApiDate(_firstPolicyInceptionDate!),
          renewalDate: _formatApiDate(_renewalDate!),
          premium: num.parse(_premiumController.text.trim()),
          sumInsured: num.parse(_sumInsuredController.text.trim()),
          policyTermYears: int.parse(_policyTermYearsController.text.trim()),
          policyDocumentBase64: document,
        );
      }
      if (!mounted) return;
      showAppMessage(
        context,
        widget.isEditing ? 'Policy updated' : 'Policy saved',
        message,
      );
      context.pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppMessage(
        context,
        widget.isEditing ? 'Unable to update policy' : 'Unable to add policy',
        error.message,
      );
    } catch (_) {
      if (!mounted) return;
      showAppMessage(
        context,
        widget.isEditing ? 'Unable to update policy' : 'Unable to add policy',
        'Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

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
                      widget.isEditing ? 'Edit Policy' : 'Add Policy',
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
              child: _isLoadingCategories
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        8,
                        20,
                        20 + bottomInset,
                      ),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Customer: ${widget.customer.name}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (widget.isEditing) ...[
                              const SizedBox(height: 18),
                              _LabeledField(
                                label: 'Policy number',
                                child: TextFormField(
                                  key: const ValueKey('edit-policy-number'),
                                  controller: _policyNumberController,
                                  textInputAction: TextInputAction.next,
                                  decoration: _inputDecoration(
                                    'Enter policy number',
                                  ),
                                  validator: (value) =>
                                      _requiredText(value, 'Policy number'),
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            _LabeledField(
                              label: 'Plan category',
                              child: DropdownButtonFormField<String>(
                                key: ValueKey(
                                  'add-policy-category-${_selectedCategoryCode ?? 'none'}',
                                ),
                                initialValue: _selectedCategoryCode,
                                decoration: _inputDecoration(
                                  'Select plan category',
                                ),
                                items: _categories
                                    .map(
                                      (category) => DropdownMenuItem(
                                        value: category.id,
                                        child: Text(category.productCategory),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _isSaving ? null : _onCategoryChanged,
                                validator: (value) => value == null
                                    ? 'Plan category is required'
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _LabeledField(
                              label: 'Product name',
                              child: _isLoadingPlans
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Center(
                                        child: SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                          ),
                                        ),
                                      ),
                                    )
                                  : DropdownButtonFormField<String>(
                                      key: ValueKey(
                                        'add-policy-product-${_selectedCategoryCode ?? 'none'}',
                                      ),
                                      initialValue: _selectedPlanId,
                                      decoration: _inputDecoration(
                                        _selectedCategoryCode == null
                                            ? 'Select category first'
                                            : 'Select product',
                                      ),
                                      items: _plans
                                          .map(
                                            (plan) => DropdownMenuItem(
                                              value: plan.publicId,
                                              child: Text(plan.name),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: _isSaving ||
                                              _selectedCategoryCode == null
                                          ? null
                                          : _onPlanChanged,
                                      validator: (value) => value == null
                                          ? 'Product name is required'
                                          : null,
                                    ),
                            ),
                            const SizedBox(height: 18),
                            _LabeledField(
                              label: 'Insurer name',
                              child: TextFormField(
                                key: const ValueKey('add-policy-insurer'),
                                controller: _insurerNameController,
                                enabled: false,
                                decoration: _inputDecoration(
                                  'Select a product to fill insurer',
                                ),
                                validator: (value) =>
                                    _requiredText(value, 'Insurer name'),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _LabeledField(
                              label: 'Start date',
                              child: _DateField(
                                key: const ValueKey('add-policy-start'),
                                label: _formatDisplayDate(_startDate),
                                onTap: _isSaving
                                    ? null
                                    : () => _pickDate(
                                        current: _startDate,
                                        onPicked: (date) => setState(
                                          () => _startDate = date,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _LabeledField(
                              label: 'End date',
                              child: _DateField(
                                key: const ValueKey('add-policy-end'),
                                label: _formatDisplayDate(_endDate),
                                onTap: _isSaving
                                    ? null
                                    : () => _pickDate(
                                        current: _endDate,
                                        onPicked: (date) => setState(
                                          () => _endDate = date,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _LabeledField(
                              label: 'First policy inception date',
                              child: _DateField(
                                key: const ValueKey('add-policy-inception'),
                                label: _formatDisplayDate(
                                  _firstPolicyInceptionDate,
                                ),
                                onTap: _isSaving
                                    ? null
                                    : () => _pickDate(
                                        current: _firstPolicyInceptionDate,
                                        onPicked: (date) => setState(
                                          () =>
                                              _firstPolicyInceptionDate = date,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _LabeledField(
                              label: 'Renewal date',
                              child: _DateField(
                                key: const ValueKey('add-policy-renewal'),
                                label: _formatDisplayDate(_renewalDate),
                                onTap: _isSaving
                                    ? null
                                    : () => _pickDate(
                                        current: _renewalDate,
                                        onPicked: (date) => setState(
                                          () => _renewalDate = date,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _LabeledField(
                              label: 'Premium',
                              child: TextFormField(
                                key: const ValueKey('add-policy-premium'),
                                controller: _premiumController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.]'),
                                  ),
                                ],
                                textInputAction: TextInputAction.next,
                                decoration: _inputDecoration('Enter premium'),
                                validator: (value) =>
                                    _requiredNumber(value, 'premium'),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _LabeledField(
                              label: 'Sum insured',
                              child: TextFormField(
                                key: const ValueKey('add-policy-sum'),
                                controller: _sumInsuredController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.]'),
                                  ),
                                ],
                                textInputAction: TextInputAction.next,
                                decoration: _inputDecoration(
                                  'Enter sum insured',
                                ),
                                validator: (value) =>
                                    _requiredNumber(value, 'sum insured'),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _LabeledField(
                              label: 'Policy term (years)',
                              child: TextFormField(
                                key: const ValueKey('add-policy-term'),
                                controller: _policyTermYearsController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                textInputAction: TextInputAction.done,
                                decoration: _inputDecoration(
                                  'Enter policy term years',
                                ),
                                validator: (value) {
                                  final text = value?.trim() ?? '';
                                  if (text.isEmpty) {
                                    return 'Policy term is required';
                                  }
                                  final years = int.tryParse(text);
                                  if (years == null || years <= 0) {
                                    return 'Enter a valid policy term';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 18),
                            _LabeledField(
                              label: 'Policy document',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if ((_documentBase64?.trim().isNotEmpty ??
                                      false)) ...[
                                    Material(
                                      color: const Color(0xFFF4F8F7),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          14,
                                          10,
                                          8,
                                          10,
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.picture_as_pdf_rounded,
                                              color: Color(0xFF2F6BFF),
                                              size: 22,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                _documentName ??
                                                    'Policy document',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: AppColors.navy,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13.5,
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              key: const ValueKey(
                                                'view-policy-document',
                                              ),
                                              onPressed: _isSaving
                                                  ? null
                                                  : () => openBase64Document(
                                                        context,
                                                        documentBase64:
                                                            _documentBase64,
                                                        title: _documentName ??
                                                            'Policy document',
                                                        fileName: _documentName,
                                                        unavailableMessage:
                                                            'No policy document is available.',
                                                      ),
                                              child: const Text('View'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                  OutlinedButton.icon(
                                    key: const ValueKey('add-policy-document'),
                                    onPressed:
                                        _isSaving ? null : _pickDocument,
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
                                      (_documentBase64?.trim().isNotEmpty ??
                                              false)
                                          ? 'Replace PDF'
                                          : 'Attach PDF',
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
                                    : Text(
                                        widget.isEditing
                                            ? 'Update Policy'
                                            : 'Save Policy',
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
      disabledBorder: border,
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.onTap,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.navy,
        minimumSize: const Size.fromHeight(52),
        alignment: Alignment.centerLeft,
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: label == 'Select date'
                    ? const Color(0xFF9AA6B2)
                    : AppColors.navy,
                fontSize: 15,
              ),
            ),
          ),
          const Icon(Icons.calendar_today_rounded, size: 18),
        ],
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
