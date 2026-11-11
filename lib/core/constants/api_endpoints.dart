/// Paths relative to the configured API base URL.
abstract final class ApiEndpoints {
  static const requestOtp = '/auth/otp/request';
  static const verifyOtp = '/auth/otp/verify';
  static const users = '/users';
  static const customers = '/customers';
  static const inquiries = '/inquiries';
  static const insurancePlans = '/insurance-plans';
  static const insuranceCategories = '/insurance-plans/categories';
}
