import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/api_response.dart';
import '../models/customer_role.dart';

class UsersRepository {
  UsersRepository(this._client);

  final ApiClient _client;

  /// Creates a user via `POST /users`.
  Future<String> createUser({
    required String firstName,
    required String lastName,
    required String email,
    required String mobile,
    CustomerRole role = CustomerRole.customer,
  }) async {
    final data = await _client.post(
      ApiEndpoints.users,
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'mobile': mobile,
        'role': role.apiValue,
      },
    );

    if (data is! Map) {
      throw const ApiException('Unexpected response while creating user.');
    }

    final body = Map<String, dynamic>.from(data);
    ApiResponse.ensureSuccess(body);
    return ApiResponse.nullableMessage(body) ?? 'User created successfully.';
  }

  /// Updates a user via `PATCH /users/{userPublicId}`.
  Future<String> updateUser({
    required String userPublicId,
    required String firstName,
    required String lastName,
    required String email,
    required String mobile,
  }) async {
    final id = userPublicId.trim();
    if (id.isEmpty) {
      throw const ApiException('User id is missing for this customer.');
    }

    final data = await _client.patch(
      ApiEndpoints.user(id),
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'mobile': mobile,
      },
    );

    if (data is! Map) {
      throw const ApiException('Unexpected response while updating user.');
    }

    final body = Map<String, dynamic>.from(data);
    ApiResponse.ensureSuccess(body);
    return ApiResponse.nullableMessage(body) ?? 'User updated successfully.';
  }
}
