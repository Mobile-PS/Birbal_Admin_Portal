import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../data/models/customer_summary.dart';
import '../../data/sample/sample_customers.dart';

enum _CustomerTab { all, activePolicy, renewalDue, noPolicy }

enum _CustomerSort { nameAsc, nameDesc }

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  static const _accent = Color(0xFF2F6BFF);

  final _searchController = TextEditingController();
  _CustomerTab _tab = _CustomerTab.all;
  _CustomerSort _sort = _CustomerSort.nameAsc;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _countFor(_CustomerTab tab) {
    return sampleCustomers.where((customer) => _matchesTab(customer, tab)).length;
  }

  bool _matchesTab(CustomerSummary customer, _CustomerTab tab) {
    return switch (tab) {
      _CustomerTab.all => true,
      _CustomerTab.activePolicy =>
        customer.status == CustomerPolicyStatus.active,
      _CustomerTab.renewalDue =>
        customer.status == CustomerPolicyStatus.renewalDue,
      _CustomerTab.noPolicy =>
        customer.status == CustomerPolicyStatus.noPolicy,
    };
  }

  List<CustomerSummary> get _visibleCustomers {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = sampleCustomers.where((customer) {
      if (!_matchesTab(customer, _tab)) return false;
      if (query.isEmpty) return true;
      return customer.name.toLowerCase().contains(query) ||
          customer.phone.contains(query) ||
          customer.email.toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) {
      final compared = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return _sort == _CustomerSort.nameAsc ? compared : -compared;
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final customers = _visibleCustomers;

    return ColoredBox(
      color: const Color(0xFFF7F8FC),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = constraints.maxWidth >= 720 ? 28.0 : 16.0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(padding, padding, padding, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(accent: _accent),
                    const SizedBox(height: 16),
                    _SearchField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),
                    _StatusTabs(
                      selected: _tab,
                      accent: _accent,
                      counts: {
                        _CustomerTab.all: sampleCustomers.length,
                        _CustomerTab.activePolicy: _countFor(
                          _CustomerTab.activePolicy,
                        ),
                        _CustomerTab.renewalDue: _countFor(
                          _CustomerTab.renewalDue,
                        ),
                        _CustomerTab.noPolicy: _countFor(_CustomerTab.noPolicy),
                      },
                      onSelected: (tab) => setState(() => _tab = tab),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _SortButton(
                        sort: _sort,
                        onChanged: (sort) => setState(() => _sort = sort),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Expanded(
                child: customers.isEmpty
                    ? const Center(
                        child: Text(
                          'No customers match your search.',
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
                        itemCount: customers.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                          color: Color(0xFFE8ECF2),
                        ),
                        itemBuilder: (context, index) {
                          return _CustomerTile(
                            customer: customers[index],
                            accent: _accent,
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

class _Header extends StatelessWidget {
  const _Header({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Customers',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: () => context.push('/customers/add'),
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(0, 44),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.add, size: 18),
          label: const Text(
            'Add Customer',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search by name, mobile or email...',
        hintStyle: const TextStyle(color: Color(0xFF9AA6B2), fontSize: 14),
        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9AA6B2)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2F6BFF), width: 1.4),
        ),
      ),
    );
  }
}

class _StatusTabs extends StatelessWidget {
  const _StatusTabs({
    required this.selected,
    required this.counts,
    required this.accent,
    required this.onSelected,
  });

  final _CustomerTab selected;
  final Map<_CustomerTab, int> counts;
  final Color accent;
  final ValueChanged<_CustomerTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final tabs = <(_CustomerTab, String)>[
      (_CustomerTab.all, 'All'),
      (_CustomerTab.activePolicy, 'Active Policy'),
      (_CustomerTab.renewalDue, 'Renewal Due'),
      (_CustomerTab.noPolicy, 'No Policy'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final entry in tabs) ...[
            _StatusChip(
              label: '${entry.$2} (${counts[entry.$1] ?? 0})',
              selected: selected == entry.$1,
              accent: accent,
              onTap: () => onSelected(entry.$1),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent : const Color(0xFFEEF2F7),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : accent,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({
    required this.sort,
    required this.onChanged,
  });

  final _CustomerSort sort;
  final ValueChanged<_CustomerSort> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = sort == _CustomerSort.nameAsc
        ? 'Sort: Name A-Z'
        : 'Sort: Name Z-A';

    return PopupMenuButton<_CustomerSort>(
      onSelected: onChanged,
      offset: const Offset(0, 40),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _CustomerSort.nameAsc,
          child: Text('Name A-Z'),
        ),
        PopupMenuItem(
          value: _CustomerSort.nameDesc,
          child: Text('Name Z-A'),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({
    required this.customer,
    required this.accent,
  });

  final CustomerSummary customer;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final hasPolicy = customer.policyCount > 0;
    final badgeColor = hasPolicy
        ? const Color(0xFF12B76A)
        : const Color(0xFFF79009);
    final badgeBackground = hasPolicy
        ? const Color(0xFFECFDF3)
        : const Color(0xFFFFF6E8);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFE8F0FF),
            child: Text(
              customer.initials,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        customer.name,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBackground,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        customer.policyBadgeLabel,
                        style: TextStyle(
                          color: badgeColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  customer.phone,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  customer.email,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            onSelected: (value) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$value for ${customer.name}')),
              );
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'View', child: Text('View')),
              PopupMenuItem(value: 'Edit', child: Text('Edit')),
            ],
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
