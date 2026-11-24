import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/api_response.dart';
import '../models/admin_dashboard_summary.dart';
import '../models/customer_list_filter.dart';
import '../models/customer_summary.dart';
import '../models/product_entry.dart';

class DashboardRepository {
  DashboardRepository(this._client);

  final ApiClient _client;

  /// Loads admin dashboard counts via `GET /admin/dashboard`.
  Future<AdminDashboardSummary> fetchDashboard() async {
    final data = await _client.get(ApiEndpoints.adminDashboard);

    if (data is! Map) {
      throw const ApiException('Unexpected response while loading dashboard.');
    }

    final body = Map<String, dynamic>.from(data);
    ApiResponse.ensureSuccess(body);
    return AdminDashboardSummary.fromJson(ApiResponse.dataMap(body));
  }

  /// Loads paged customer rows via `GET /admin/dashboard/userDetails`.
  Future<CustomerDetailsPage> fetchUserDetails({
    CustomerListFilter filter = CustomerListFilter.all,
    int page = 0,
    int size = 20,
  }) async {
    final data = await _client.get(
      ApiEndpoints.adminDashboardUserDetails,
      queryParameters: {
        'filter': filter.apiValue,
        'page': page,
        'size': size,
      },
    );

    if (data is! Map) {
      throw const ApiException('Unexpected response while loading customers.');
    }

    final body = Map<String, dynamic>.from(data);
    ApiResponse.ensureSuccess(body);
    return CustomerDetailsPage.fromJson(ApiResponse.dataMap(body));
  }

  /// Loads product categories via `GET /admin/dashboard/categories`.
  Future<List<ProductEntry>> fetchCategories() async {
    final data = await _client.get(ApiEndpoints.adminDashboardCategories);

    if (data is! Map) {
      throw const ApiException('Unexpected response while loading products.');
    }

    final body = Map<String, dynamic>.from(data);
    ApiResponse.ensureSuccess(body);
    final categories = ApiResponse.dataList(body)
        .map(ProductEntry.fromJson)
        .toList()
      ..sort((a, b) {
        final byOrder = a.displayOrder.compareTo(b.displayOrder);
        if (byOrder != 0) return byOrder;
        return a.productCategory.toLowerCase().compareTo(
          b.productCategory.toLowerCase(),
        );
      });
    return categories;
  }

  /// Toggles a category via `PATCH /admin/dashboard/categories/{code}/toggle`.
  Future<ProductEntry> toggleCategory(String code) async {
    final data = await _client.patch(
      ApiEndpoints.adminDashboardCategoryToggle(code),
    );

    if (data is! Map) {
      throw const ApiException('Unexpected response while updating category.');
    }

    final body = Map<String, dynamic>.from(data);
    ApiResponse.ensureSuccess(body);
    return ProductEntry.fromJson(ApiResponse.dataMap(body));
  }

  /// Creates a category via `POST /createInsuranceCategory`.
  Future<ProductEntry> createInsuranceCategory({
    required String code,
    required String category,
    required String documentBase64,
  }) async {
    final data = await _client.post(
      ApiEndpoints.createInsuranceCategory,
      data: {
        'code': code,
        'category': category,
        'documentBase64': documentBase64,
      },
    );

    if (data is! Map) {
      throw const ApiException('Unexpected response while creating category.');
    }

    final body = Map<String, dynamic>.from(data);
    ApiResponse.ensureSuccess(body);
    return ProductEntry.fromJson(ApiResponse.dataMap(body));
  }

  /// Updates a category via `PUT /updateInsuranceCategory/{code}`.
  Future<ProductEntry> updateInsuranceCategory({
    required String code,
    required String category,
    required String documentBase64,
  }) async {
    final normalizedCode = code.trim();
    if (normalizedCode.isEmpty) {
      throw const ApiException('Category code is missing.');
    }

    final data = await _client.put(
      ApiEndpoints.updateInsuranceCategory(normalizedCode),
      data: {
        'code': normalizedCode,
        'category': category,
        'documentBase64': documentBase64,
      },
    );

    if (data is! Map) {
      throw const ApiException('Unexpected response while updating category.');
    }

    final body = Map<String, dynamic>.from(data);
    ApiResponse.ensureSuccess(body);
    final payload = ApiResponse.dataMap(body);
    if (payload.isEmpty) {
      return ProductEntry(
        id: normalizedCode,
        productCategory: category,
      );
    }
    return ProductEntry.fromJson(payload);
  }
}
