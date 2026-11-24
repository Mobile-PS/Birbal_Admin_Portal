import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../app/theme/app_colors.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/document_base64.dart';
import '../../core/utils/document_picker.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/models/product_entry.dart';
import '../../data/repositories/dashboard_repository.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({this.product, super.key});

  /// When set, the page edits an existing product (code is read-only).
  final ProductEntry? product;

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  static const _accent = Color(0xFF2F6BFF);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _categoryController;

  String? _documentBase64;
  String? _documentName;
  bool _isSaving = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _codeController = TextEditingController(text: product?.id ?? '');
    _categoryController = TextEditingController(
      text: product?.productCategory ?? '',
    );
    final existingIcon = product?.imageDataUri;
    if (existingIcon != null && existingIcon.isNotEmpty) {
      _documentBase64 = existingIcon;
      _documentName = product?.documentFileName?.trim().isNotEmpty == true
          ? product!.documentFileName
          : 'Current icon';
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  String? _validateCode(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Code is required';
    if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(text)) {
      return 'Use letters, numbers, or underscore only';
    }
    return null;
  }

  String? _validateCategory(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Product category is required';
    return null;
  }

  Future<void> _pickAttachment() async {
    try {
      final picked = await pickImageAsBase64DataUri();
      if (!mounted || picked == null) return;
      setState(() {
        _documentBase64 = picked.dataUri;
        _documentName = picked.fileName;
      });
    } catch (_) {
      if (!mounted) return;
      showAppMessage(
        context,
        'Unable to attach image',
        'Please try another image file.',
      );
    }
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final document = DocumentBase64.normalize(_documentBase64) ?? '';
    if (document.isEmpty) {
      showAppMessage(
        context,
        'Attachment required',
        _isEditing
            ? 'Please keep or attach a product icon image.'
            : 'Please attach a product icon image.',
      );
      return;
    }

    final code = _codeController.text.trim().toUpperCase();
    final category = _categoryController.text.trim();
    final repository = DashboardRepository(AppScope.of(context).apiClient);

    setState(() => _isSaving = true);
    try {
      if (_isEditing) {
        await repository.updateInsuranceCategory(
          code: code,
          category: category,
          documentBase64: document,
        );
      } else {
        await repository.createInsuranceCategory(
          code: code,
          category: category,
          documentBase64: document,
        );
      }
      if (!mounted) return;
      showAppMessage(
        context,
        _isEditing ? 'Product updated' : 'Product saved',
        _isEditing
            ? 'Insurance category updated successfully'
            : 'Insurance category created successfully',
      );
      context.pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppMessage(
        context,
        _isEditing ? 'Unable to update product' : 'Unable to add product',
        error.message,
      );
    } catch (_) {
      if (!mounted) return;
      showAppMessage(
        context,
        _isEditing ? 'Unable to update product' : 'Unable to add product',
        'Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final title = _isEditing ? 'Edit Product' : 'Add Product';
    final actionLabel = _isEditing ? 'Update Product' : 'Add Product';

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
                          key: const ValueKey('add-product-code'),
                          controller: _codeController,
                          enabled: !_isEditing,
                          readOnly: _isEditing,
                          textCapitalization: TextCapitalization.characters,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Za-z0-9_]'),
                            ),
                          ],
                          decoration: _inputDecoration(
                            'Enter code (e.g. HEALTH)',
                            filled: _isEditing,
                          ),
                          validator: _validateCode,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _LabeledField(
                        label: 'Product category',
                        child: TextFormField(
                          key: const ValueKey('add-product-category'),
                          controller: _categoryController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _save(),
                          decoration: _inputDecoration(
                            'Enter product category',
                          ),
                          validator: _validateCategory,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _LabeledField(
                        label: 'Attachment',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            OutlinedButton.icon(
                              key: const ValueKey('add-product-attachment'),
                              onPressed: _isSaving ? null : _pickAttachment,
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
                              icon: const Icon(Icons.image_outlined),
                              label: Text(
                                _documentName ??
                                    (_isEditing
                                        ? 'Replace icon image'
                                        : 'Attach icon image'),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_documentBase64 != null) ...[
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: _IconPreview(dataUri: _documentBase64!),
                              ),
                              if (_isEditing) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _documentName == 'Current icon'
                                      ? 'Showing the current product icon. Attach a new image to replace it.'
                                      : 'New icon selected. Save to apply the change.',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ],
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

  InputDecoration _inputDecoration(String hint, {bool filled = false}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9AA6B2), fontSize: 14),
      filled: true,
      fillColor: filled ? const Color(0xFFF7F8FC) : Colors.white,
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

class _IconPreview extends StatelessWidget {
  const _IconPreview({required this.dataUri});

  final String dataUri;

  @override
  Widget build(BuildContext context) {
    final decoded = decodeDataUri(DocumentBase64.normalize(dataUri));
    if (decoded == null || !decoded.isImage) {
      return const SizedBox.shrink();
    }

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.memory(decoded.bytes, fit: BoxFit.cover),
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
