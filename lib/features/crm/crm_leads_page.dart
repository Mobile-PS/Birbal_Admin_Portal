import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../data/models/lead_models.dart';
import '../../data/repositories/crm_repository.dart';

class CrmLeadsPage extends StatefulWidget {
  const CrmLeadsPage({super.key});

  @override
  State<CrmLeadsPage> createState() => _CrmLeadsPageState();
}

class _CrmLeadsPageState extends State<CrmLeadsPage> {
  static const _accent = Color(0xFF2F6BFF);

  final _searchController = TextEditingController();
  LeadStage? _stageFilter;
  List<LeadSummary> _leads = const [];
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final leads = await CrmRepository.instance.fetchLeads(stage: _stageFilter);
      if (!mounted) return;
      setState(() {
        _leads = leads;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load leads. Please try again.';
        _isLoading = false;
      });
    }
  }

  List<LeadSummary> get _visibleLeads {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _leads;
    return _leads.where((lead) {
      return lead.name.toLowerCase().contains(query) ||
          lead.mobile.contains(query) ||
          lead.productInterest.toLowerCase().contains(query) ||
          (lead.assignedUserName?.toLowerCase().contains(query) ?? false);
    }).toList(growable: false);
  }

  Future<void> _openAddLead() async {
    final created = await context.push<bool>('/crm/add');
    if (created == true && mounted) await _load();
  }

  Future<void> _openLead(LeadSummary lead) async {
    final changed = await context.push<bool>(
      '/crm/detail',
      extra: lead.id,
    );
    if (changed == true && mounted) await _load();
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
                padding: EdgeInsets.fromLTRB(padding, padding, padding, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'CRM',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: _openAddLead,
                          style: FilledButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size(0, 44),
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
                            'Add Lead',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Local preview until lead APIs are ready. Data resets when the app restarts.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search by name, mobile, product or assignee',
                        hintStyle: const TextStyle(
                          color: Color(0xFF9AA6B2),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF9AA6B2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
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
                          borderSide: const BorderSide(
                            color: Color(0xFF2F6BFF),
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _StageChip(
                            label: 'All',
                            selected: _stageFilter == null,
                            accent: _accent,
                            onTap: () {
                              if (_stageFilter == null) return;
                              setState(() => _stageFilter = null);
                              _load();
                            },
                          ),
                          const SizedBox(width: 8),
                          for (final stage in LeadStage.values) ...[
                            _StageChip(
                              label: stage.label,
                              selected: _stageFilter == stage,
                              accent: _accent,
                              onTap: () {
                                if (_stageFilter == stage) return;
                                setState(() => _stageFilter = stage);
                                _load();
                              },
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
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

    if (_error != null && _leads.isEmpty) {
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
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final leads = _visibleLeads;
    if (leads.isEmpty) {
      return const Center(
        child: Text(
          'No leads match your filters.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(padding, 4, padding, padding + 16),
        itemCount: leads.length,
        separatorBuilder: (_, _) => const Divider(
          height: 1,
          color: Color(0xFFE8ECF2),
        ),
        itemBuilder: (context, index) {
          final lead = leads[index];
          return _LeadTile(
            lead: lead,
            accent: _accent,
            onTap: () => _openLead(lead),
          );
        },
      ),
    );
  }
}

class _StageChip extends StatelessWidget {
  const _StageChip({
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

class _LeadTile extends StatelessWidget {
  const _LeadTile({
    required this.lead,
    required this.accent,
    required this.onTap,
  });

  final LeadSummary lead;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final stageColor = _stageColor(lead.stage);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFE8F0FF),
              child: Text(
                lead.initials,
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
                          lead.name,
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
                          color: stageColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          lead.stage.label,
                          style: TextStyle(
                            color: stageColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lead.mobile,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lead.productInterest,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13.5,
                    ),
                  ),
                  if (lead.assignedUserName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Assigned: ${lead.assignedUserName}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                  if (lead.nextFollowUpAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Next follow-up: ${_formatDateTime(lead.nextFollowUpAt!)}',
                      style: const TextStyle(
                        color: Color(0xFFB54708),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
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
      ),
    );
  }
}

Color _stageColor(LeadStage stage) {
  return switch (stage) {
    LeadStage.newLead => const Color(0xFF2F6BFF),
    LeadStage.contacted => const Color(0xFF7A5AF8),
    LeadStage.followUp => const Color(0xFFF79009),
    LeadStage.documentsPending => const Color(0xFFEE46BC),
    LeadStage.policyIssued => const Color(0xFF12B76A),
    LeadStage.lost => const Color(0xFF667085),
  };
}

String _formatDateTime(DateTime value) {
  const months = [
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
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '${local.day} ${months[local.month - 1]} · $hour:$minute $period';
}
