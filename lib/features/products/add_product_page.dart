import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../data/models/product_entry.dart';
import '../../data/sample/sample_products.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  static const _accent = Color(0xFF2F6BFF);

  final _formKey = GlobalKey<FormState>();
  final _productCategoryController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _productCategoryController.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Product category is required';
    return null;
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _isSaving = true);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    sampleProducts.add(
      ProductEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        productCategory: _productCategoryController.text.trim(),
        isEnabled: true,
      ),
    );

    setState(() => _isSaving = false);
    context.pop(true);
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
                    onPressed: () => context.pop(false),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.navy,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Add Product',
                      textAlign: TextAlign.center,
                      style: TextStyle(
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
                        label: 'Product category',
                        child: TextFormField(
                          controller: _productCategoryController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _save(),
                          decoration: _inputDecoration(
                            'Enter product category',
                          ),
                          validator: _required,
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
                              : const Text('Add Product'),
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
