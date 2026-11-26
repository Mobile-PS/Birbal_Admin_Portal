import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../app/theme/app_colors.dart';
import '../../core/network/api_exception.dart';
import '../../data/models/admin_dashboard_summary.dart';
import '../../data/models/lead_models.dart';
import '../../data/repositories/crm_repository.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../shell/admin_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  AdminDashboardSummary? _summary;
  int _totalLeads = 0;
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
      final results = await Future.wait([
        DashboardRepository(AppScope.of(context).apiClient).fetchDashboard(),
        CrmRepository(AppScope.of(context).apiClient).fetchLeads(),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as AdminDashboardSummary;
        _totalLeads = (results[1] as LeadsPage).totalElements;
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
        _error = 'Unable to load dashboard. Please try again.';
        _isLoading = false;
      });
    }
  }

  List<DashboardMetric> _metricsFor(AdminDashboardSummary summary) {
    return [
      DashboardMetric(
        label: 'Customers',
        value: '${summary.totalCustomers}',
        icon: Icons.people_alt_rounded,
        iconColor: const Color(0xFF2F80ED),
        iconBackground: const Color(0xFFE8F1FF),
        route: '/customers',
      ),
      DashboardMetric(
        label: 'Policies',
        value: '${summary.totalPolicies}',
        icon: Icons.description_rounded,
        iconColor: const Color(0xFF27AE60),
        iconBackground: const Color(0xFFE8F8EF),
        route: '/policies',
      ),
      DashboardMetric(
        label: 'Active policies',
        value: '${summary.activePolicies}',
        icon: Icons.verified_user_rounded,
        iconColor: const Color(0xFF219653),
        iconBackground: const Color(0xFFE7F6EF),
        route: '/policies',
      ),
      DashboardMetric(
        label: 'Inactive policies',
        value: '${summary.inactivePolicies}',
        icon: Icons.schedule_rounded,
        iconColor: const Color(0xFFEB5757),
        iconBackground: const Color(0xFFFDECEC),
        route: '/policies',
      ),
      DashboardMetric(
        label: 'Inquiries',
        value: '${summary.totalInquiries}',
        icon: Icons.forum_rounded,
        iconColor: const Color(0xFF9B51E0),
        iconBackground: const Color(0xFFF3E9FC),
        route: '/inquiries',
      ),
      DashboardMetric(
        label: 'CRM',
        value: '$_totalLeads',
        icon: Icons.handshake_rounded,
        iconColor: const Color(0xFF0E9384),
        iconBackground: const Color(0xFFE6F6F4),
        route: '/crm',
      ),
      DashboardMetric(
        label: 'Product',
        value: '${summary.totalPlans}',
        icon: Icons.inventory_2_rounded,
        iconColor: const Color(0xFF2F6BFF),
        iconBackground: const Color(0xFFE8F0FF),
        route: '/products',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Dashboard',
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _load,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final metrics = _metricsFor(_summary ?? AdminDashboardSummary.empty);

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 720
            ? 3
            : 2;
        const spacing = 14.0;
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: cardWidth,
                child: DashboardMetricCard(
                  metric: metric,
                  onTap: () => context.go(metric.route),
                ),
              ),
          ],
        );
      },
    );
  }
}

class DashboardMetric {
  const DashboardMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.route,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String route;
}

class DashboardMetricCard extends StatelessWidget {
  const DashboardMetricCard({
    required this.metric,
    required this.onTap,
    super.key,
  });

  final DashboardMetric metric;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: metric.iconBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(metric.icon, color: metric.iconColor, size: 22),
                ),
                const SizedBox(height: 18),
                Text(
                  metric.label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  metric.value,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
