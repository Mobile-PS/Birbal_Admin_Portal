import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/theme/app_colors.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/phone_launcher.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/models/inquiry_summary.dart';
import '../../data/repositories/inquiries_repository.dart';

class InquiriesPage extends StatefulWidget {
  const InquiriesPage({super.key});

  @override
  State<InquiriesPage> createState() => _InquiriesPageState();
}

class _InquiriesPageState extends State<InquiriesPage> {
  static const _accent = Color(0xFF9B51E0);
  static const _pageSize = 20;

  final _searchController = TextEditingController();

  List<InquirySummary> _inquiries = const [];
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
      final result = await InquiriesRepository(
        AppScope.of(context).apiClient,
      ).fetchInquiries(page: requestPage, size: _pageSize);
      if (!mounted) return;

      setState(() {
        _inquiries = reset
            ? result.content
            : [..._inquiries, ...result.content];
        _page = result.page;
        _lastPage = result.last || result.content.isEmpty;
        _totalElements = result.totalElements;
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
        _error = 'Unable to load inquiries. Please try again.';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  List<InquirySummary> get _visibleInquiries {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _inquiries;

    return _inquiries.where((inquiry) {
      return inquiry.username.toLowerCase().contains(query) ||
          inquiry.email.toLowerCase().contains(query) ||
          inquiry.mobileNumber.contains(query) ||
          inquiry.policyName.toLowerCase().contains(query) ||
          inquiry.policyCategory.toLowerCase().contains(query) ||
          inquiry.status.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final inquiries = _visibleInquiries;

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
                    const Text(
                      'Inquiries',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isLoading
                          ? 'Advice requests waiting on the team.'
                          : '$_totalElements total · Advice requests waiting on the team.',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SearchField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Expanded(child: _buildList(inquiries, padding)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<InquirySummary> inquiries, double padding) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _inquiries.isEmpty) {
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

    if (inquiries.isEmpty) {
      return const Center(
        child: Text(
          'No inquiries match your search.',
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
          itemCount: inquiries.length + (_isLoadingMore ? 1 : 0),
          separatorBuilder: (context, index) => const Divider(
            height: 1,
            color: Color(0xFFE8ECF2),
          ),
          itemBuilder: (context, index) {
            if (index >= inquiries.length) {
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
            return _InquiryTile(
              inquiry: inquiries[index],
              accent: _accent,
            );
          },
        ),
      ),
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
        hintText: 'Search by name, mobile, email or plan...',
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
          borderSide: const BorderSide(color: Color(0xFF9B51E0), width: 1.4),
        ),
      ),
    );
  }
}

class _InquiryTile extends StatelessWidget {
  const _InquiryTile({
    required this.inquiry,
    required this.accent,
  });

  final InquirySummary inquiry;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusStyle(inquiry.status);
    final createdLabel = inquiry.createdAt == null
        ? null
        : _formatCreatedAt(inquiry.createdAt!.toLocal());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFF3E9FC),
            child: Text(
              inquiry.initials,
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
                        inquiry.username,
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
                        color: statusStyle.$2,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        inquiry.statusLabel,
                        style: TextStyle(
                          color: statusStyle.$1,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  inquiry.mobileNumber,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  inquiry.email,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13.5,
                  ),
                ),
                if (inquiry.policyName.isNotEmpty ||
                    inquiry.policyCategory.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    [
                      if (inquiry.policyName.isNotEmpty) inquiry.policyName,
                      if (inquiry.policyCategory.isNotEmpty)
                        inquiry.policyCategory,
                    ].join(' · '),
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ],
                if (createdLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    createdLabel,
                    style: const TextStyle(
                      color: Color(0xFF9AA6B2),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (inquiry.mobileNumber.trim().isNotEmpty) ...[
            const SizedBox(width: 4),
            IconButton(
              key: ValueKey('inquiry-call-${inquiry.id}'),
              tooltip: 'Call',
              onPressed: () => _call(context),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFE8F8EF),
                foregroundColor: const Color(0xFF12B76A),
              ),
              icon: const Icon(Icons.call_rounded),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _call(BuildContext context) async {
    final phone = inquiry.mobileNumber.trim();
    final launched = await launchPhoneCall(phone);
    if (!context.mounted) return;
    if (!launched) {
      showAppMessage(
        context,
        'Unable to call',
        'Could not open the dialer for $phone.',
      );
    }
  }

  (Color, Color) _statusStyle(String status) {
    final normalized = status.trim().toUpperCase();
    return switch (normalized) {
      'NEW' => (const Color(0xFF2F6BFF), const Color(0xFFE8F0FF)),
      'OPEN' || 'IN_PROGRESS' || 'IN-PROGRESS' => (
        const Color(0xFFF79009),
        const Color(0xFFFFF6E8),
      ),
      'CLOSED' || 'RESOLVED' || 'DONE' => (
        const Color(0xFF12B76A),
        const Color(0xFFECFDF3),
      ),
      _ => (const Color(0xFF667085), const Color(0xFFEEF2F7)),
    };
  }

  String _formatCreatedAt(DateTime value) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';
    final day = value.day.toString().padLeft(2, '0');
    return '$day ${months[value.month - 1]} ${value.year}, '
        '${hour.toString().padLeft(2, '0')}:$minute $period';
  }
}
