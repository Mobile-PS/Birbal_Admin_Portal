import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../app/theme/app_colors.dart';
import '../../core/network/api_exception.dart';
import '../../data/models/insurance_plan_model.dart';
import '../../data/repositories/insurance_repository.dart';

class ProductPlansPage extends StatefulWidget {
  const ProductPlansPage({
    required this.categoryCode,
    required this.categoryTitle,
    super.key,
  });

  final String categoryCode;
  final String categoryTitle;

  @override
  State<ProductPlansPage> createState() => _ProductPlansPageState();
}

class _ProductPlansPageState extends State<ProductPlansPage> {
  List<InsurancePlanModel> _plans = const [];
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
    if (widget.categoryCode.trim().isEmpty) {
      setState(() {
        _error = 'Category is missing.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final page = await InsuranceRepository(
        AppScope.of(context).apiClient,
      ).fetchPlans(category: widget.categoryCode);
      if (!mounted) return;
      setState(() {
        _plans = page.content;
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
        _error = 'Unable to load plans. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _openAddPlan() async {
    final code = Uri.encodeComponent(widget.categoryCode);
    final title = Uri.encodeComponent(widget.categoryTitle);
    final added = await context.push<bool>(
      '/products/plans/add?code=$code&title=$title',
    );
    if (added == true && mounted) await _load();
  }

  Future<void> _openEditPlan(InsurancePlanModel plan) async {
    final code = Uri.encodeComponent(widget.categoryCode);
    final title = Uri.encodeComponent(widget.categoryTitle);
    final updated = await context.push<bool>(
      '/products/plans/edit?code=$code&title=$title',
      extra: plan,
    );
    if (updated == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: AppColors.navy,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.categoryTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  key: const ValueKey('add-plan-button'),
                  onPressed: _openAddPlan,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2F6BFF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    'Add Plan',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            Expanded(child: _buildBody(bottomSafe)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(double bottomSafe) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _plans.isEmpty) {
      return _EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load plans',
        message: _error!,
        actionLabel: 'Try again',
        onAction: _load,
      );
    }

    if (_plans.isEmpty) {
      return const _EmptyState(
        icon: Icons.inbox_outlined,
        title: 'No plans found',
        message: 'There are no active plans in this category yet.',
      );
    }

    return RefreshIndicator(
      color: AppColors.brand,
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomSafe),
        itemCount: _plans.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final plan = _plans[index];
          return _PlanCard(
            plan: plan,
            onTap: () => context.push('/products/plans/detail', extra: plan),
            onEdit: () => _openEditPlan(plan),
          );
        },
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.onTap,
    required this.onEdit,
  });

  final InsurancePlanModel plan;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE6EEF0)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InkWell(
                onTap: onTap,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.brand.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.shield_outlined,
                              color: AppColors.brand,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plan.name,
                                  style: const TextStyle(
                                    color: AppColors.navy,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15.5,
                                  ),
                                ),
                                if (plan.insurerName != null &&
                                    plan.insurerName!.trim().isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    plan.insurerName!,
                                    style: const TextStyle(
                                      color: AppColors.brand,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                      if (plan.description != null &&
                          plan.description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          plan.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 4),
              child: IconButton(
                tooltip: 'Edit plan',
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.5,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
