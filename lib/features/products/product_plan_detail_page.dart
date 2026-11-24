import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/policy_document_viewer.dart';
import '../../data/models/insurance_plan_model.dart';

class ProductPlanDetailPage extends StatelessWidget {
  const ProductPlanDetailPage({required this.plan, super.key});

  final InsurancePlanModel? plan;

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
                  const Expanded(
                    child: Text(
                      'Plan details',
                      textAlign: TextAlign.center,
                      style: TextStyle(
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
            Expanded(
              child: plan == null
                  ? const Center(
                      child: Text(
                        'This plan could not be opened.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        16,
                        20,
                        20 + bottomSafe,
                      ),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE6EEF0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: AppColors.brand.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.shield_outlined,
                                      color: AppColors.brand,
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          plan!.name,
                                          style: const TextStyle(
                                            color: AppColors.navy,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 18,
                                            height: 1.25,
                                          ),
                                        ),
                                        if (_hasText(plan!.insurerName)) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            plan!.insurerName!,
                                            style: const TextStyle(
                                              color: AppColors.brand,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (_hasText(plan!.category))
                                    _InfoChip(
                                      label: plan!.category,
                                      color: AppColors.navy,
                                    ),
                                  _InfoChip(
                                    label: plan!.active ? 'Active' : 'Inactive',
                                    color: plan!.active
                                        ? const Color(0xFF2F8F63)
                                        : AppColors.textSecondary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _DetailCard(
                          children: [
                            if (_hasText(plan!.description))
                              _DetailBlock(
                                label: 'Description',
                                value: plan!.description!,
                              ),
                            _DetailBlock(
                              label: 'Insurer',
                              value: _textOrDash(plan!.insurerName),
                            ),
                            _DetailBlock(
                              label: 'Category',
                              value: _textOrDash(plan!.category),
                            ),
                            _DetailBlock(
                              label: 'Plan ID',
                              value: _textOrDash(plan!.publicId),
                            ),
                            _DetailBlock(
                              label: 'Status',
                              value: plan!.active ? 'Active' : 'Inactive',
                              isLast: !_hasText(plan!.createdAt) &&
                                  !_hasText(plan!.updatedAt),
                            ),
                            if (_hasText(plan!.createdAt))
                              _DetailBlock(
                                label: 'Created on',
                                value: _formatDateTime(plan!.createdAt!),
                                isLast: !_hasText(plan!.updatedAt),
                              ),
                            if (_hasText(plan!.updatedAt))
                              _DetailBlock(
                                label: 'Updated on',
                                value: _formatDateTime(plan!.updatedAt!),
                                isLast: true,
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _PlanAttachmentCard(plan: plan!),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanAttachmentCard extends StatelessWidget {
  const _PlanAttachmentCard({required this.plan});

  final InsurancePlanModel plan;

  @override
  Widget build(BuildContext context) {
    final available = plan.hasDocument;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EEF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attachment',
            style: TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: const Color(0xFFF4F8F7),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
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
                      Icons.attach_file_rounded,
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
                        Text(
                          available
                              ? plan.documentDisplayName
                              : 'No attachment',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: available
                                ? AppColors.navy
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                        if (available) ...[
                          const SizedBox(height: 2),
                          const Text(
                            'View or download plan document',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (available) ...[
                    TextButton(
                      key: const ValueKey('plan-attachment-view'),
                      onPressed: () => openBase64Document(
                        context,
                        documentBase64: plan.documentBase64,
                        title: plan.documentDisplayName,
                        fileName: plan.documentFileName,
                        unavailableMessage:
                            'No plan document is available for this plan.',
                      ),
                      child: const Text('View'),
                    ),
                    TextButton(
                      key: const ValueKey('plan-attachment-download'),
                      onPressed: () => downloadBase64Document(
                        context,
                        documentBase64: plan.documentBase64,
                        title: plan.documentDisplayName,
                        fileName: plan.documentFileName,
                        unavailableMessage:
                            'No plan document is available for this plan.',
                      ),
                      child: const Text('Download'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EEF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 8 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

String _textOrDash(String? value) {
  if (!_hasText(value)) return '—';
  return value!.trim();
}

String _formatDateTime(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  final local = parsed.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year}, $hour:$minute';
}
