import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../app/theme/app_colors.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/policy_document_viewer.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/models/customer_list_filter.dart';
import '../../data/models/customer_summary.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/repositories/policies_repository.dart';
import 'edit_policy_args.dart';

enum _PolicyTone { renewalDue, active, expired, inactive }

class _PolicyCardItem {
  const _PolicyCardItem({
    required this.policy,
    required this.category,
    required this.planLabel,
    required this.tone,
    required this.statusLabel,
    required this.dateLine,
    required this.icon,
    required this.cardColor,
    required this.iconBackground,
    required this.accent,
    this.footnote,
  });

  final CustomerPolicySummary policy;
  final String category;
  final String planLabel;
  final _PolicyTone tone;
  final String statusLabel;
  final String dateLine;
  final IconData icon;
  final Color cardColor;
  final Color iconBackground;
  final Color accent;
  final String? footnote;
}

class CustomerPoliciesPage extends StatefulWidget {
  const CustomerPoliciesPage({required this.customer, super.key});

  final CustomerSummary customer;

  @override
  State<CustomerPoliciesPage> createState() => _CustomerPoliciesPageState();
}

class _CustomerPoliciesPageState extends State<CustomerPoliciesPage> {
  late CustomerSummary _customer;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
  }

  Future<void> _reloadCustomer() async {
    setState(() => _isRefreshing = true);
    try {
      final page = await DashboardRepository(
        AppScope.of(context).apiClient,
      ).fetchUserDetails(
        filter: CustomerListFilter.all,
        page: 0,
        size: 100,
      );
      if (!mounted) return;
      CustomerSummary? match;
      for (final customer in page.content) {
        if (customer.id == _customer.id ||
            (customer.userPublicId != null &&
                customer.userPublicId == _customer.userPublicId)) {
          match = customer;
          break;
        }
      }
      if (match != null) {
        setState(() {
          _customer = match!;
          _isRefreshing = false;
        });
      } else {
        setState(() => _isRefreshing = false);
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _isRefreshing = false);
      showAppMessage(context, 'Could not refresh policies', error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isRefreshing = false);
      showAppMessage(
        context,
        'Could not refresh policies',
        'Please go back and open View again.',
      );
    }
  }

  Future<void> _editPolicy(CustomerPolicySummary policy) async {
    final updated = await context.push<bool>(
      '/customers/edit-policy',
      extra: EditPolicyArgs(customer: _customer, policy: policy),
    );
    if (updated == true && mounted) {
      await _reloadCustomer();
    }
  }

  void _replacePolicyLocally(CustomerPolicySummary updated) {
    final policies = _customer.policies
        .map(
          (policy) => policy.policyPublicId == updated.policyPublicId
              ? updated
              : policy,
        )
        .toList(growable: false);
    setState(() {
      _customer = _customer.copyWith(policies: policies);
    });
  }

  Future<void> _togglePolicyStatus(CustomerPolicySummary policy) async {
    final policyId = policy.policyPublicId.trim();
    if (policyId.isEmpty) {
      showAppMessage(
        context,
        'Unable to update status',
        'Policy id is missing.',
      );
      return;
    }

    final nextStatus = policy.isActive ? 'INACTIVE' : 'ACTIVE';
    try {
      final message = await PoliciesRepository(
        AppScope.of(context).apiClient,
      ).updatePolicyStatus(
        policyId: policyId,
        status: nextStatus,
      );
      if (!mounted) return;
      _replacePolicyLocally(policy.copyWith(status: nextStatus));
      showAppMessage(context, 'Status updated', message);
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppMessage(context, 'Unable to update status', error.message);
      rethrow;
    } catch (_) {
      if (!mounted) return;
      showAppMessage(
        context,
        'Unable to update status',
        'Please try again.',
      );
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = _customer.policies.map(_mapPolicy).toList();
    final renewals = cards
        .where((item) => item.tone == _PolicyTone.renewalDue)
        .toList();
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
                    onPressed: () => context.pop(true),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Policies',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          _customer.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isRefreshing)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 28 + bottomSafe),
                children: [
                  const Text(
                    'My Policies',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (cards.isEmpty)
                    const _EmptyPoliciesPane(
                      icon: Icons.inbox_outlined,
                      title: 'No policies yet',
                      message:
                          'Policies for this customer will appear here once issued.',
                    )
                  else
                    for (final item in cards) ...[
                      _PolicyStatusCard(
                        item: item,
                        onTap: () => _showPolicyDetail(context, item),
                        onEdit: () => _editPolicy(item.policy),
                      ),
                      const SizedBox(height: 12),
                    ],
                  if (renewals.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Upcoming Renewals',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _UpcomingRenewalsCard(
                      items: renewals,
                      onTap: (item) => _showPolicyDetail(context, item),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPolicyDetail(BuildContext pageContext, _PolicyCardItem item) {
    var policy = item.policy;
    var statusLabel = item.statusLabel;
    var isToggling = false;

    showModalBottomSheet<void>(
      context: pageContext,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.85;
        final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 24 + bottomInset),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.category,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.planLabel,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _DetailRow(
                        label: 'Policy No.',
                        value: policy.policyNumber,
                      ),
                      _DetailRow(label: 'Status', value: statusLabel),
                      _DetailRow(
                        label: 'Premium',
                        value: formatInr(policy.premium),
                      ),
                      _DetailRow(
                        label: 'Sum Insured',
                        value: formatInr(policy.sumInsured),
                      ),
                      _DetailRow(
                        label: 'Valid till',
                        value: formatDisplayDate(policy.endDate),
                      ),
                      if (policy.insurerName != null &&
                          policy.insurerName!.isNotEmpty)
                        _DetailRow(
                          label: 'Insurer',
                          value: policy.insurerName!,
                        ),
                      const SizedBox(height: 12),
                      Material(
                        color: const Color(0xFFF4F8F7),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Policy status',
                                      style: TextStyle(
                                        color: AppColors.navy,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      policy.isActive ? 'Active' : 'Inactive',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isToggling)
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                    ),
                                  ),
                                )
                              else
                                Switch.adaptive(
                                  value: policy.isActive,
                                  activeThumbColor: const Color(0xFF2F6BFF),
                                  onChanged: (enabled) async {
                                    setSheetState(() => isToggling = true);
                                    try {
                                      await _togglePolicyStatus(policy);
                                      if (!context.mounted) return;
                                      final updated = policy.copyWith(
                                        status:
                                            enabled ? 'ACTIVE' : 'INACTIVE',
                                      );
                                      setSheetState(() {
                                        policy = updated;
                                        statusLabel =
                                            enabled ? 'Active' : 'Inactive';
                                        isToggling = false;
                                      });
                                    } catch (_) {
                                      if (!context.mounted) return;
                                      setSheetState(() => isToggling = false);
                                    }
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _PolicyDocumentTile(
                        policy: policy,
                        onView: () {
                          Navigator.of(sheetContext).pop();
                          openPolicyDocument(pageContext, policy);
                        },
                        onDownload: () {
                          Navigator.of(sheetContext).pop();
                          downloadPolicyDocument(pageContext, policy);
                        },
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: isToggling
                              ? null
                              : () {
                                  Navigator.of(sheetContext).pop();
                                  _editPolicy(policy);
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2F6BFF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: const Text(
                            'Edit Policy',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _PolicyDocumentTile extends StatelessWidget {
  const _PolicyDocumentTile({
    required this.policy,
    required this.onView,
    required this.onDownload,
  });

  final CustomerPolicySummary policy;
  final VoidCallback onView;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final available = policy.hasDocument;

    return Material(
      color: const Color(0xFFF4F8F7),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: available
                    ? const Color(0xFFE8F0FF)
                    : const Color(0xFFE8ECF2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.picture_as_pdf_rounded,
                color: available
                    ? const Color(0xFF2F6BFF)
                    : AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Policy document',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    available
                        ? policy.documentDisplayName
                        : 'No document uploaded',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: available
                          ? AppColors.textSecondary
                          : const Color(0xFF9AA6B2),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            if (available) ...[
              TextButton(
                onPressed: onView,
                child: const Text('View'),
              ),
              TextButton(
                onPressed: onDownload,
                child: const Text('Download'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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

class _PolicyStatusCard extends StatelessWidget {
  const _PolicyStatusCard({
    required this.item,
    required this.onTap,
    required this.onEdit,
  });

  final _PolicyCardItem item;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final isRenewal = item.tone == _PolicyTone.renewalDue;

    return Material(
      color: item.cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: item.iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.category,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusPill(
                          label: item.statusLabel,
                          tone: item.tone,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.planLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Policy No. ${item.policy.policyNumber}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color:
                              isRenewal ? item.accent : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.dateLine,
                            style: TextStyle(
                              color: isRenewal
                                  ? item.accent
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (item.footnote != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.footnote!,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          fontWeight: isRenewal
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                    if (item.policy.hasDocument) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFD7E3EA),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.picture_as_pdf_rounded,
                              size: 16,
                              color: Color(0xFF2F6BFF),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.policy.documentDisplayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.navy,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  openPolicyDocument(context, item.policy),
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              child: const Text('View'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  downloadPolicyDocument(context, item.policy),
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              child: const Text('Download'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  children: [
                    IconButton(
                      tooltip: 'Edit policy',
                      onPressed: onEdit,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.edit_rounded,
                        size: 20,
                        color: Color(0xFF2F6BFF),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.tone});

  final String label;
  final _PolicyTone tone;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (tone) {
      _PolicyTone.renewalDue => (
        const Color(0xFFD6455A),
        const Color(0xFFFFD7DE),
      ),
      _PolicyTone.active => (
        const Color(0xFF2F8F63),
        const Color(0xFFD7F0E2),
      ),
      _PolicyTone.expired => (
        const Color(0xFF6B7784),
        const Color(0xFFE2E7EC),
      ),
      _PolicyTone.inactive => (
        const Color(0xFF6B7784),
        const Color(0xFFE8ECF2),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyPoliciesPane extends StatelessWidget {
  const _EmptyPoliciesPane({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, size: 42, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
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
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingRenewalsCard extends StatelessWidget {
  const _UpcomingRenewalsCard({
    required this.items,
    required this.onTap,
  });

  final List<_PolicyCardItem> items;
  final ValueChanged<_PolicyCardItem> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6EEF0)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onTap(items[i]),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F6F8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        items[i].icon,
                        color: AppColors.navy,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            items[i].category,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            items[i].policy.insurerName ?? 'Insurer',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            items[i].dateLine,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
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
            if (i != items.length - 1)
              const Divider(height: 1, color: Color(0xFFE8EEF1)),
          ],
        ],
      ),
    );
  }
}

_PolicyCardItem _mapPolicy(CustomerPolicySummary policy) {
  final tone = _toneFor(policy);
  final category = _categoryFor(policy);
  final plan = [
    policy.planName,
    if (policy.insurerName != null && policy.insurerName!.isNotEmpty)
      policy.insurerName!,
  ].join(' | ');

  return switch (tone) {
    _PolicyTone.renewalDue => _PolicyCardItem(
      policy: policy,
      category: category,
      planLabel: plan,
      tone: tone,
      statusLabel: 'Renewal due',
      dateLine: _renewalLine(policy),
      footnote: _renewalFootnote(policy),
      icon: _iconFor(category),
      cardColor: const Color(0xFFFFE8EC),
      iconBackground: const Color(0xFFE85A6B),
      accent: const Color(0xFFD6455A),
    ),
    _PolicyTone.active => _PolicyCardItem(
      policy: policy,
      category: category,
      planLabel: plan,
      tone: tone,
      statusLabel: 'Active',
      dateLine: 'Valid till ${formatDisplayDate(policy.endDate)}',
      icon: _iconFor(category),
      cardColor: const Color(0xFFE6F6EC),
      iconBackground: const Color(0xFF4CAF71),
      accent: const Color(0xFF2F8F63),
    ),
    _PolicyTone.expired => _PolicyCardItem(
      policy: policy,
      category: category,
      planLabel: plan,
      tone: tone,
      statusLabel: 'Expired',
      dateLine: 'Expired ${formatDisplayDate(policy.endDate)}',
      icon: _iconFor(category),
      cardColor: const Color(0xFFEAF1F6),
      iconBackground: const Color(0xFF2F4B63),
      accent: const Color(0xFF5C6B78),
    ),
    _PolicyTone.inactive => _PolicyCardItem(
      policy: policy,
      category: category,
      planLabel: plan,
      tone: tone,
      statusLabel: 'Inactive',
      dateLine: 'Inactive • till ${formatDisplayDate(policy.endDate)}',
      icon: _iconFor(category),
      cardColor: const Color(0xFFF2F4F7),
      iconBackground: const Color(0xFF6B7784),
      accent: const Color(0xFF6B7784),
    ),
  };
}

_PolicyTone _toneFor(CustomerPolicySummary policy) {
  final status = policy.status.toUpperCase();
  if (status == 'INACTIVE' || status.contains('INACTIV')) {
    return _PolicyTone.inactive;
  }

  final renewal = (policy.renewalStatus ?? '').toUpperCase();
  if (renewal.contains('RENEWAL') || renewal.contains('DUE')) {
    return _PolicyTone.renewalDue;
  }

  if (status.contains('EXPIR') || status.contains('LAPSE')) {
    return _PolicyTone.expired;
  }

  final end = DateTime.tryParse(policy.endDate ?? '');
  if (end != null) {
    final now = DateTime.now();
    if (end.isBefore(now)) return _PolicyTone.expired;
    if (end.difference(now).inDays <= 30) return _PolicyTone.renewalDue;
  }

  return _PolicyTone.active;
}

String _categoryFor(CustomerPolicySummary policy) {
  final raw = (policy.planCategory ?? policy.planName).trim();
  final value = raw.toLowerCase();
  if (value.contains('health') || value.contains('medic')) {
    return 'Health Insurance';
  }
  if (value.contains('life') || value.contains('term')) {
    return 'Life Insurance';
  }
  if (value.contains('car') ||
      value.contains('motor') ||
      value.contains('auto')) {
    return 'Car insurance';
  }
  if (raw.isEmpty) return 'Insurance';
  return '${raw[0].toUpperCase()}${raw.substring(1).toLowerCase()} Insurance';
}

IconData _iconFor(String category) {
  final value = category.toLowerCase();
  if (value.contains('health')) return Icons.favorite_rounded;
  if (value.contains('life') || value.contains('term')) {
    return Icons.verified_user_rounded;
  }
  if (value.contains('car') || value.contains('motor')) {
    return Icons.directions_car_filled_rounded;
  }
  return Icons.shield_outlined;
}

String _renewalLine(CustomerPolicySummary policy) {
  final date = policy.endDate;
  if (date == null) return 'Renewal due';
  final end = DateTime.tryParse(date);
  if (end == null) return 'Renews ${formatDisplayDate(date)}';
  final days = end.difference(DateTime.now()).inDays;
  final left = days < 0 ? 0 : days;
  return 'Renews ${formatDisplayDate(date)} • $left days left';
}

String? _renewalFootnote(CustomerPolicySummary policy) {
  final end = DateTime.tryParse(policy.endDate ?? '');
  if (end == null) return null;
  final days = end.difference(DateTime.now()).inDays;
  final left = days < 0 ? 0 : days;
  return 'Your policy is due for renewal in $left days';
}
