import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/api_response.dart';
import '../models/inquiry_summary.dart';

class InquiriesRepository {
  InquiriesRepository(this._client);

  final ApiClient _client;

  /// Loads paged inquiries via `GET /inquiries`.
  Future<InquiryDetailsPage> fetchInquiries({
    int page = 0,
    int size = 20,
  }) async {
    final data = await _client.get(
      ApiEndpoints.inquiries,
      queryParameters: {
        'page': page,
        'size': size,
      },
    );

    if (data is! Map) {
      throw const ApiException('Unexpected response while loading inquiries.');
    }

    final body = Map<String, dynamic>.from(data);
    ApiResponse.ensureSuccess(body);
    return InquiryDetailsPage.fromJson(ApiResponse.dataMap(body));
  }
}
