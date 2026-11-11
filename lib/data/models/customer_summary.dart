enum CustomerPolicyStatus { active, renewalDue, noPolicy }

class CustomerSummary {
  const CustomerSummary({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.policyCount,
    required this.status,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final int policyCount;
  final CustomerPolicyStatus status;

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String get policyBadgeLabel {
    if (policyCount <= 0) return 'No Policy';
    return policyCount == 1 ? '1 Policy' : '$policyCount Policies';
  }
}
