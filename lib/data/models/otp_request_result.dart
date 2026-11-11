import '../../core/network/api_response.dart';
import '../../core/utils/json_utils.dart';

class OtpRequestResult {
  const OtpRequestResult({
    required this.registered,
    required this.message,
  });

  final bool registered;
  final String message;

  factory OtpRequestResult.fromBody(Map<String, dynamic> body) {
    final data = ApiResponse.dataMap(body);
    final topMessage = ApiResponse.nullableMessage(body);
    final dataMessage = jsonNullableString(data['message']);

    final bool registered;
    if (data.containsKey('registered')) {
      registered = data['registered'] == true;
    } else {
      registered = ApiResponse.isSuccess(body);
    }

    final message = (dataMessage != null && dataMessage.isNotEmpty)
        ? dataMessage
        : (topMessage != null && topMessage.isNotEmpty)
        ? topMessage
        : registered
        ? 'OTP sent successfully.'
        : 'This mobile number is not registered with us.';

    return OtpRequestResult(registered: registered, message: message);
  }
}
