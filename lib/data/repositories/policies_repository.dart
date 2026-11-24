import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/api_response.dart';

class PoliciesRepository {
  PoliciesRepository(this._client);

  final ApiClient _client;

  /// Creates a policy via `POST /policies`.
  Future<String> createPolicy({
    required String userPublicId,
    required String customerId,
    required String planCategory,
    required String productName,
    required String insurerName,
    required String startDate,
    required String endDate,
    required String firstPolicyInceptionDate,
    required String renewalDate,
    required num premium,
    required num sumInsured,
    required int policyTermYears,
    required String policyDocumentBase64,
  }) async {
    final data = await _client.post(
      ApiEndpoints.policies,
      data: {
        'userPublicId': userPublicId,
        'customerId': customerId,
        'planCategory': planCategory,
        'productName': productName,
        'insurerName': insurerName,
        'startDate': startDate,
        'endDate': endDate,
        'firstPolicyInceptionDate': firstPolicyInceptionDate,
        'renewalDate': renewalDate,
        'premium': premium,
        'sumInsured': sumInsured,
        'policyTermYears': policyTermYears,
        'policyDocumentBase64': policyDocumentBase64,
      },
    );

    if (data is! Map) {
      throw const ApiException('Unexpected response while creating policy.');
    }

    final body = Map<String, dynamic>.from(data);
    ApiResponse.ensureSuccess(body);
    return ApiResponse.nullableMessage(body) ??
        'Policy created successfully.';
  }

  /// Updates a policy via `PUT /policies/{policyId}`.
  Future<String> updatePolicy({
    required String policyId,
    required String userPublicId,
    required String customerId,
    required String planCategory,
    required String productName,
    required String insurerName,
    required String policyNumber,
    required String startDate,
    required String endDate,
    required String firstPolicyInceptionDate,
    required String renewalDate,
    required num premium,
    required num sumInsured,
    required int policyTermYears,
    required String policyDocumentBase64,
  }) async {
    final id = policyId.trim();
    if (id.isEmpty) {
      throw const ApiException('Policy id is missing.');
    }

    final data = await _client.put(
      ApiEndpoints.policy(id),
      data: {
        'userPublicId': userPublicId,
        'customerId': customerId,
        'planCategory': planCategory,
        'productName': productName,
        'insurerName': insurerName,
        'policyNumber': policyNumber,
        'startDate': startDate,
        'endDate': endDate,
        'firstPolicyInceptionDate': firstPolicyInceptionDate,
        'renewalDate': renewalDate,
        'premium': premium,
        'sumInsured': sumInsured,
        'policyTermYears': policyTermYears,
        'policyDocumentBase64': policyDocumentBase64,
      },
    );

    if (data is! Map) {
      throw const ApiException('Unexpected response while updating policy.');
    }

    final body = Map<String, dynamic>.from(data);
    ApiResponse.ensureSuccess(body);
    return ApiResponse.nullableMessage(body) ??
        'Policy updated successfully.';
  }

  /// Updates policy status via `PATCH /policies/{policyId}/status`.
  Future<String> updatePolicyStatus({
    required String policyId,
    required String status,
  }) async {
    final id = policyId.trim();
    if (id.isEmpty) {
      throw const ApiException('Policy id is missing.');
    }

    final normalized = status.trim().toUpperCase();
    if (normalized != 'ACTIVE' && normalized != 'INACTIVE') {
      throw const ApiException('Status must be ACTIVE or INACTIVE.');
    }

    final data = await _client.patch(
      ApiEndpoints.policyStatus(id),
      data: {
        'status': normalized,
      },
    );

    if (data is! Map) {
      throw const ApiException(
        'Unexpected response while updating policy status.',
      );
    }

    final body = Map<String, dynamic>.from(data);
    ApiResponse.ensureSuccess(body);
    return ApiResponse.nullableMessage(body) ??
        'Policy status updated successfully.';
  }
}
