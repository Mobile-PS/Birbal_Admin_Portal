import '../../core/utils/json_utils.dart';

class InquirySummary {
  const InquirySummary({
    required this.id,
    required this.username,
    required this.email,
    required this.mobileNumber,
    required this.policyCategory,
    required this.policyName,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String username;
  final String email;
  final String mobileNumber;
  final String policyCategory;
  final String policyName;
  final String status;
  final DateTime? createdAt;

  String get initials {
    final parts = username
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String get statusLabel {
    final raw = status.trim();
    if (raw.isEmpty) return 'Unknown';
    return raw
        .toLowerCase()
        .split(RegExp(r'[_\s-]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  factory InquirySummary.fromJson(Map<String, dynamic> json) {
    return InquirySummary(
      id: jsonString(json['publicId']),
      username: jsonString(json['username'], fallback: 'Unknown'),
      email: jsonString(json['email']),
      mobileNumber: jsonString(json['mobileNumber']),
      policyCategory: jsonString(json['policyCategory']),
      policyName: jsonString(json['policyName']),
      status: jsonString(json['status']),
      createdAt: _parseDate(json['createdAt']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    final raw = jsonNullableString(value);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }
}

class InquiryDetailsPage {
  const InquiryDetailsPage({
    required this.content,
    required this.last,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  final List<InquirySummary> content;
  final bool last;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  factory InquiryDetailsPage.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'];
    final content = <InquirySummary>[];
    if (rawContent is List) {
      for (final item in rawContent) {
        if (item is Map) {
          content.add(
            InquirySummary.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return InquiryDetailsPage(
      content: content,
      last: json['last'] == true,
      page: jsonInt(json['page']),
      size: jsonInt(json['size'], fallback: 20),
      totalElements: jsonInt(json['totalElements']),
      totalPages: jsonInt(json['totalPages']),
    );
  }

  static const empty = InquiryDetailsPage(
    content: [],
    last: true,
    page: 0,
    size: 20,
    totalElements: 0,
    totalPages: 0,
  );
}
