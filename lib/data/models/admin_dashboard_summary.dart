import '../../core/utils/json_utils.dart';

class AdminDashboardSummary {
  const AdminDashboardSummary({
    required this.activePolicies,
    required this.inactivePolicies,
    required this.totalCustomers,
    required this.totalInquiries,
    required this.totalPlans,
    required this.totalPolicies,
    required this.totalUsers,
  });

  final int activePolicies;
  final int inactivePolicies;
  final int totalCustomers;
  final int totalInquiries;
  final int totalPlans;
  final int totalPolicies;
  final int totalUsers;

  factory AdminDashboardSummary.fromJson(Map<String, dynamic> json) {
    return AdminDashboardSummary(
      activePolicies: jsonInt(json['activePolicies']),
      inactivePolicies: jsonInt(json['inactivePolicies']),
      totalCustomers: jsonInt(json['totalCustomers']),
      totalInquiries: jsonInt(json['totalInquiries']),
      totalPlans: jsonInt(json['totalPlans']),
      totalPolicies: jsonInt(json['totalPolicies']),
      totalUsers: jsonInt(json['totalUsers']),
    );
  }

  static const empty = AdminDashboardSummary(
    activePolicies: 0,
    inactivePolicies: 0,
    totalCustomers: 0,
    totalInquiries: 0,
    totalPlans: 0,
    totalPolicies: 0,
    totalUsers: 0,
  );
}
