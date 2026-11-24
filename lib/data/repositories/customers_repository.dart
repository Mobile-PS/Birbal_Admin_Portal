import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/api_response.dart';
import '../models/customer_application.dart';

class CustomersRepository {
  CustomersRepository(this._client);

  final ApiClient _client;

  /// Loads policy-login application details via `GET /customers/{customerId}`.
  Future<CustomerApplication> getCustomerApplication(String customerId) async {
    final id = customerId.trim();
    if (id.isEmpty) {
      throw const ApiException('Customer id is missing.');
    }

    final data = await _client.get(ApiEndpoints.customer(id));

    if (data is! Map) {
      throw const ApiException(
        'Unexpected response while loading customer application.',
      );
    }

    final body = Map<String, dynamic>.from(data);
    ApiResponse.ensureSuccess(body);

    final payload = ApiResponse.dataMap(body);
    if (payload.isEmpty) {
      throw const ApiException(
        'No policy login data is available for this customer.',
      );
    }

    return CustomerApplication.fromJson(payload);
  }
}
