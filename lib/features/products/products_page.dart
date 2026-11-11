import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../data/models/product_entry.dart';
import '../../data/sample/sample_products.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  static const _accent = Color(0xFF2F6BFF);

  Future<void> _openAddProduct() async {
    final added = await context.push<bool>('/products/add');
    if (added == true && mounted) setState(() {});
  }

  void _toggleProduct(ProductEntry product, bool enabled) {
    setState(() => product.isEnabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    final products = List<ProductEntry>.from(sampleProducts);

    return ColoredBox(
      color: const Color(0xFFF7F8FC),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = constraints.maxWidth >= 720 ? 28.0 : 16.0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(padding, padding, padding, 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Product',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _openAddProduct,
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(0, 44),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(
                        'Add Product',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: products.isEmpty
                    ? const Center(
                        child: Text(
                          'No products yet. Tap Add Product to create one.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          padding,
                          4,
                          padding,
                          padding + 16,
                        ),
                        itemCount: products.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                          color: Color(0xFFE8ECF2),
                        ),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return _ProductTile(
                            product: product,
                            accent: _accent,
                            onChanged: (enabled) =>
                                _toggleProduct(product, enabled),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.accent,
    required this.onChanged,
  });

  final ProductEntry product;
  final Color accent;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final enabled = product.isEnabled;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: enabled
                  ? const Color(0xFFE8F0FF)
                  : const Color(0xFFF1F3F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              color: enabled ? accent : AppColors.textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productCategory,
                  style: TextStyle(
                    color: enabled ? AppColors.navy : AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  enabled ? 'Enabled' : 'Disabled',
                  style: TextStyle(
                    color: enabled
                        ? const Color(0xFF12B76A)
                        : AppColors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: enabled,
            activeThumbColor: Colors.white,
            activeTrackColor: accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
