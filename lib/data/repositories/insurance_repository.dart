import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/api_response.dart';
import '../models/insurance_plan_model.dart';

class InsuranceRepository {
  InsuranceRepository(this._client);

  final ApiClient _client;

  /// Loads plans via `GET /insurance-plans`.
  Future<InsurancePlanPage> fetchPlans({
    required String category,
    bool activeOnly = true,
    int page = 0,
    int size = 50,
  }) async {
    final data = await _client.get(
      ApiEndpoints.insurancePlans,
      queryParameters: {
        'activeOnly': activeOnly,
        'category': category,
        'page': page,
        'size': size,
      },
    );

    if (data is! Map) {
      throw const ApiException(
        'Unexpected response while loading insurance plans.',
      );
    }

    final body = Map<String, dynamic>.from(data);
    ApiResponse.ensureSuccess(body);

    try {
      return InsurancePlanPage.fromData(ApiResponse.dataMap(body));
    } on FormatException {
      throw const ApiException(
        'Unexpected response while loading insurance plans.',
      );
    }
  }

  /// Creates insurer/plan data via `POST /createInsurerData`.
  Future<String> createInsurerData({
    required String code,
    required String category,
    required String name,
    required String insurerName,
    required String description,
    required String documentBase64,
  }) async {
    final data = await _client.post(
      ApiEndpoints.createInsurerData,
      data: {
        'code': code,
        'category': category,
        'name': name,
        'insurerName': insurerName,
        'description': description,
        'documentBase64': documentBase64,
      },
    );

    if (data is! Map) {
      throw const ApiException('Unexpected response while creating plan.');
    }

    final body = Map<String, dynamic>.from(data);
    ApiResponse.ensureSuccess(body);
    return ApiResponse.nullableMessage(body) ??
        'Insurance plan created successfully.';
  }

  /// Updates insurer/plan data via `PUT /updateInsurerData/{planId}`.
  Future<String> updateInsurerData({
    required String planId,
    required String code,
    required String category,
    required String name,
    required String insurerName,
    required String description,
    required String documentBase64,
  }) async {
    final id = planId.trim();
    if (id.isEmpty) {
      throw const ApiException('Plan id is missing.');
    }

    final data = await _client.put(
      ApiEndpoints.updateInsurerData(id),
      data: {
        'code': code,
        'category': category,
        'name': name,
        'insurerName': insurerName,
        'description': description,
        'documentBase64': documentBase64,
      },
    );

    if (data is! Map) {
      throw const ApiException('Unexpected response while updating plan.');
    }

    final body = Map<String, dynamic>.from(data);
    ApiResponse.ensureSuccess(body);
    return ApiResponse.nullableMessage(body) ??
        'Insurance plan updated successfully.';
  }
}
