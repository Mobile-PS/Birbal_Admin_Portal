import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../app/theme/app_colors.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/customer_application_pdf.dart';
import '../../core/utils/policy_document_viewer.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/models/customer_list_filter.dart';
import '../../data/models/customer_summary.dart';
import '../../data/repositories/customers_repository.dart';
import '../../data/repositories/dashboard_repository.dart';

enum _CustomerSort { nameAsc, nameDesc }

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  static const _accent = Color(0xFF2F6BFF);
  static const _pageSize = 20;

  final _searchController = TextEditingController();
  final _counts = <CustomerListFilter, int>{};

  CustomerListFilter _filter = CustomerListFilter.all;
  _CustomerSort _sort = _CustomerSort.nameAsc;
  List<CustomerSummary> _customers = const [];
  String? _error;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _lastPage = true;
  int _page = 0;
  int _totalElements = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load(reset: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _error = null;
        _page = 0;
        _lastPage = true;
      });
    } else {
      if (_isLoadingMore || _lastPage) return;
      setState(() => _isLoadingMore = true);
    }

    final requestPage = reset ? 0 : _page + 1;

    try {
      final result = await DashboardRepository(
        AppScope.of(context).apiClient,
      ).fetchUserDetails(
        filter: _filter,
        page: requestPage,
        size: _pageSize,
      );
      if (!mounted) return;

      setState(() {
        _customers = reset
            ? result.content
            : [..._customers, ...result.content];
        _page = result.page;
        _lastPage = result.last || result.content.isEmpty;
        _totalElements = result.totalElements;
        _counts[_filter] = result.totalElements;
        _isLoading = false;
        _isLoadingMore = false;
        _error = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load customers. Please try again.';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  List<CustomerSummary> get _visibleCustomers {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _customers.where((customer) {
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

  Future<void> _openAddCustomer() async {
    await context.push('/customers/add');
    if (mounted) await _load(reset: true);
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
                    _Header(accent: _accent, onAdd: _openAddCustomer),
                    const SizedBox(height: 16),
                    _SearchField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),
                    _StatusTabs(
                      selected: _filter,
                      accent: _accent,
                      counts: {
                        for (final filter in CustomerListFilter.values)
                          filter: _counts[filter] ??
                              (filter == _filter ? _totalElements : 0),
                      },
                      onSelected: (filter) {
                        if (filter == _filter) return;
                        setState(() => _filter = filter);
                        _load(reset: true);
                      },
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
              Expanded(child: _buildList(customers, padding)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<CustomerSummary> customers, double padding) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _customers.isEmpty) {
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
                onPressed: () => _load(reset: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (customers.isEmpty) {
      return const Center(
        child: Text(
          'No customers match your search.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 240 &&
              !_lastPage &&
              !_isLoadingMore &&
              !_isLoading) {
            _load(reset: false);
          }
          return false;
        },
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(padding, 4, padding, padding + 16),
          itemCount: customers.length + (_isLoadingMore ? 1 : 0),
          separatorBuilder: (context, index) => const Divider(
            height: 1,
            color: Color(0xFFE8ECF2),
          ),
          itemBuilder: (context, index) {
            if (index >= customers.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                ),
              );
            }
            return _CustomerTile(
              customer: customers[index],
              accent: _accent,
              onCustomerChanged: () => _load(reset: true),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.accent, required this.onAdd});

  final Color accent;
  final VoidCallback onAdd;

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
          onPressed: onAdd,
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

  final CustomerListFilter selected;
  final Map<CustomerListFilter, int> counts;
  final Color accent;
  final ValueChanged<CustomerListFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in CustomerListFilter.values) ...[
            _StatusChip(
              label: '${filter.label} (${counts[filter] ?? 0})',
              selected: selected == filter,
              accent: accent,
              onTap: () => onSelected(filter),
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
    required this.onCustomerChanged,
  });

  final CustomerSummary customer;
  final Color accent;
  final VoidCallback onCustomerChanged;

  Future<void> _downloadPolicyData(
    BuildContext context,
    CustomerSummary customer,
  ) async {
    final apiClient = AppScope.of(context).apiClient;
    var loaderVisible = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
                SizedBox(width: 14),
                Text('Preparing policy data PDF...'),
              ],
            ),
          ),
        ),
      ),
    );

    void dismissLoader() {
      if (!loaderVisible || !context.mounted) return;
      loaderVisible = false;
      Navigator.of(context, rootNavigator: true).pop();
    }

    try {
      final application =
          await CustomersRepository(apiClient).getCustomerApplication(
        customer.id,
      );
      final pdfBytes = await CustomerApplicationPdf.build(application);
      if (!context.mounted) return;
      dismissLoader();

      final fileName =
          'Policy_Login_${application.applicationNumber}_${customer.name}'
              .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
              .replaceAll(RegExp(r'\s+'), '_');
      final dataUri =
          'data:application/pdf;base64,${base64Encode(pdfBytes)}';

      await openBase64Document(
        context,
        documentBase64: dataUri,
        title: 'Policy Login Details',
        contentType: 'application/pdf',
        fileName: '$fileName.pdf',
        unavailableMessage: 'Unable to open the generated PDF.',
      );
    } on ApiException catch (error) {
      dismissLoader();
      if (!context.mounted) return;
      showAppMessage(context, 'Unavailable', error.message);
    } catch (_) {
      dismissLoader();
      if (!context.mounted) return;
      showAppMessage(
        context,
        'Failed',
        'Unable to generate policy data PDF. Please try again.',
      );
    }
  }

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
            onSelected: (value) async {
              if (value == 'View') {
                final changed = await context.push<bool>(
                  '/customers/policies',
                  extra: customer,
                );
                if (changed == true) onCustomerChanged();
                return;
              }
              if (value == 'Edit') {
                final updated = await context.push<bool>(
                  '/customers/edit',
                  extra: customer,
                );
                if (updated == true) onCustomerChanged();
                return;
              }
              if (value == 'Add Policy') {
                final added = await context.push<bool>(
                  '/customers/add-policy',
                  extra: customer,
                );
                if (added == true) onCustomerChanged();
                return;
              }
              if (value == 'Download Policy Data') {
                await _downloadPolicyData(context, customer);
                return;
              }
              if (!context.mounted) return;
              showAppMessage(
                context,
                value,
                '$value for ${customer.name}',
              );
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'View', child: Text('View')),
              PopupMenuItem(value: 'Edit', child: Text('Edit')),
              PopupMenuItem(value: 'Add Policy', child: Text('Add Policy')),
              PopupMenuItem(
                value: 'Download Policy Data',
                child: Text('Download Policy Data'),
              ),
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
