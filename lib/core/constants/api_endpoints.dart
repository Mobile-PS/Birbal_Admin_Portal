/// Paths relative to the configured API base URL.
abstract final class ApiEndpoints {
  static const requestOtp = '/auth/otp/request';
  static const verifyOtp = '/auth/otp/verify';
  static const users = '/users';
  static String user(String userPublicId) => '$users/$userPublicId';
  static const usersStaffDirectory = '/users/staff-directory';
  static const adminDashboard = '/admin/dashboard';
  static const adminDashboardUserDetails = '/admin/dashboard/userDetails';
  static const adminDashboardCategories = '/admin/dashboard/categories';
  static String adminDashboardCategoryToggle(String code) =>
      '$adminDashboardCategories/$code/toggle';
  static const customers = '/customers';
  static String customer(String customerId) => '$customers/$customerId';
  static const inquiries = '/inquiries';
  static const insurancePlans = '/insurance-plans';
  static const insuranceCategories = '/insurance-plans/categories';
  static const createInsuranceCategory = '/createInsuranceCategory';
  static String updateInsuranceCategory(String code) =>
      '/updateInsuranceCategory/$code';
  static const createInsurerData = '/createInsurerData';
  static String updateInsurerData(String planId) =>
      '/updateInsurerData/$planId';
  static const policies = '/policies';
  static String policy(String policyId) => '$policies/$policyId';
  static String policyStatus(String policyId) => '$policies/$policyId/status';
  static const crmLeads = '/crm/leads';
  static String crmLead(String leadId) => '$crmLeads/$leadId';
  static String crmLeadFollowUps(String leadId) =>
      '${crmLead(leadId)}/follow-ups';
  static String crmLeadActivities(String leadId) =>
      '${crmLead(leadId)}/activities';
  static String crmLeadStage(String leadId) => '${crmLead(leadId)}/stage';
}
