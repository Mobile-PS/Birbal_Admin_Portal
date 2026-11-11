import '../utils/json_utils.dart';
import 'api_exception.dart';

/// Shared API envelope used by Birbal Advice:
/// ```json
/// {
///   "data": {},
///   "message": "...",
///   "requestId": "...",
///   "status": true,
///   "timestamp": "..."
/// }
/// ```
abstract final class ApiResponse {
  static bool isSuccess(Map<String, dynamic> body) {
    final status = body['status'];
    if (status is bool) return status;
    if (status is String) {
      final normalized = status.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    if (status is num) return status != 0;
    return body['success'] == true;
  }

  static String message(
    Map<String, dynamic> body, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    return ApiException.messageFromBody(body, fallback: fallback);
  }

  static String? nullableMessage(Map<String, dynamic> body) {
    return jsonNullableString(body['message']);
  }

  static void ensureSuccess(Map<String, dynamic> body) {
    if (!isSuccess(body)) {
      throw ApiException(message(body));
    }
  }

  static Map<String, dynamic> dataMap(Map<String, dynamic> body) {
    final payload = body['data'];
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    return <String, dynamic>{};
  }

  static List<Map<String, dynamic>> dataList(Map<String, dynamic> body) {
    final payload = body['data'];
    if (payload is! List) return const [];

    return payload.map((item) {
      if (item is! Map) {
        throw const FormatException('Expected objects in data list.');
      }
      return Map<String, dynamic>.from(item);
    }).toList();
  }
}
