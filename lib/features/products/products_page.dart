import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../app/theme/app_colors.dart';
import '../../core/network/api_exception.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/models/product_entry.dart';
import '../../data/repositories/dashboard_repository.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  static const _accent = Color(0xFF2F6BFF);

  List<ProductEntry> _products = [];
  final _togglingCodes = <String>{};
  String? _error;
  bool _isLoading = true;

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

    try {
      final products = await DashboardRepository(
        AppScope.of(context).apiClient,
      ).fetchCategories();
      if (!mounted) return;
      setState(() {
        _products = products;
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
        _error = 'Unable to load products. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _openAddProduct() async {
    final added = await context.push<bool>('/products/add');
    if (added == true && mounted) await _load();
  }

  Future<void> _openEditProduct(ProductEntry product) async {
    final updated = await context.push<bool>(
      '/products/edit',
      extra: product,
    );
    if (updated == true && mounted) await _load();
  }

  Future<void> _toggleProduct(ProductEntry product, bool enabled) async {
    if (_togglingCodes.contains(product.id)) return;

    final previous = product.isEnabled;
    setState(() {
      product.isEnabled = enabled;
      _togglingCodes.add(product.id);
    });

    try {
      final updated = await DashboardRepository(
        AppScope.of(context).apiClient,
      ).toggleCategory(product.id);
      if (!mounted) return;

      setState(() {
        final index = _products.indexWhere((item) => item.id == product.id);
        if (index >= 0) {
          _products[index] = updated;
        }
        _togglingCodes.remove(product.id);
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        product.isEnabled = previous;
        _togglingCodes.remove(product.id);
      });
      showAppMessage(context, 'Unable to update category', error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        product.isEnabled = previous;
        _togglingCodes.remove(product.id);
      });
      showAppMessage(
        context,
        'Unable to update category',
        'Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Expanded(child: _buildBody(padding)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(double padding) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _products.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return const Center(
        child: Text(
          'No products yet. Tap Add Product to create one.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(padding, 4, padding, padding + 16),
        itemCount: _products.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          color: Color(0xFFE8ECF2),
        ),
        itemBuilder: (context, index) {
          final product = _products[index];
          return _ProductTile(
            product: product,
            accent: _accent,
            onTap: () => _openPlans(product),
            onEdit: () => _openEditProduct(product),
            onChanged: (enabled) => _toggleProduct(product, enabled),
          );
        },
      ),
    );
  }

  void _openPlans(ProductEntry product) {
    final code = Uri.encodeComponent(product.id);
    final title = Uri.encodeComponent(product.productCategory);
    context.push('/products/plans?code=$code&title=$title');
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.accent,
    required this.onTap,
    required this.onEdit,
    required this.onChanged,
  });

  final ProductEntry product;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final enabled = product.isEnabled;
    final planLabel = product.planCount == 1
        ? '1 plan'
        : '${product.planCount} plans';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
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
                            color: enabled
                                ? AppColors.navy
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$planLabel · ${enabled ? 'Enabled' : 'Disabled'}',
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
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Edit product',
            onPressed: onEdit,
            icon: const Icon(
              Icons.edit_outlined,
              color: AppColors.textSecondary,
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
