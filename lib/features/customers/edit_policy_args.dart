import '../../data/models/customer_summary.dart';

class EditPolicyArgs {
  const EditPolicyArgs({
    required this.customer,
    required this.policy,
  });

  final CustomerSummary customer;
  final CustomerPolicySummary policy;
}
