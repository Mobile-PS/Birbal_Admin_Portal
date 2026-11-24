import '../../core/utils/json_utils.dart';

enum CustomerPolicyStatus { active, inactive, renewalDue, noPolicy }

class CustomerPolicySummary {
  const CustomerPolicySummary({
    required this.policyPublicId,
    required this.policyNumber,
    required this.planName,
    required this.status,
    this.planCategory,
    this.insurerName,
    this.premium,
    this.sumInsured,
    this.startDate,
    this.endDate,
    this.renewalDate,
    this.firstPolicyInceptionDate,
    this.policyTermYears,
    this.renewalStatus,
    this.policyDocumentBase64,
    this.policyDocumentFileName,
    this.policyDocumentDownloadUrl,
    this.policyDocumentContentType,
    this.policyDocumentId,
  });

  final String policyPublicId;
  final String policyNumber;
  final String planName;
  final String status;
  final String? planCategory;
  final String? insurerName;
  final num? premium;
  final num? sumInsured;
  final String? startDate;
  final String? endDate;
  final String? renewalDate;
  final String? firstPolicyInceptionDate;
  final int? policyTermYears;
  final String? renewalStatus;
  final String? policyDocumentBase64;
  final String? policyDocumentFileName;
  final String? policyDocumentDownloadUrl;
  final String? policyDocumentContentType;
  final String? policyDocumentId;

  bool get hasDocument {
    final base64 = policyDocumentBase64?.trim();
    return base64 != null && base64.isNotEmpty;
  }

  String get documentDisplayName {
    final name = policyDocumentFileName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Policy document';
  }

  bool get isActive {
    final value = status.trim().toUpperCase();
    return value != 'INACTIVE' && !value.contains('INACTIV');
  }

  CustomerPolicySummary copyWith({
    String? policyPublicId,
    String? policyNumber,
    String? planName,
    String? status,
    String? planCategory,
    String? insurerName,
    num? premium,
    num? sumInsured,
    String? startDate,
    String? endDate,
    String? renewalDate,
    String? firstPolicyInceptionDate,
    int? policyTermYears,
    String? renewalStatus,
    String? policyDocumentBase64,
    String? policyDocumentFileName,
    String? policyDocumentDownloadUrl,
    String? policyDocumentContentType,
    String? policyDocumentId,
  }) {
    return CustomerPolicySummary(
      policyPublicId: policyPublicId ?? this.policyPublicId,
      policyNumber: policyNumber ?? this.policyNumber,
      planName: planName ?? this.planName,
      status: status ?? this.status,
      planCategory: planCategory ?? this.planCategory,
      insurerName: insurerName ?? this.insurerName,
      premium: premium ?? this.premium,
      sumInsured: sumInsured ?? this.sumInsured,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      renewalDate: renewalDate ?? this.renewalDate,
      firstPolicyInceptionDate:
          firstPolicyInceptionDate ?? this.firstPolicyInceptionDate,
      policyTermYears: policyTermYears ?? this.policyTermYears,
      renewalStatus: renewalStatus ?? this.renewalStatus,
      policyDocumentBase64: policyDocumentBase64 ?? this.policyDocumentBase64,
      policyDocumentFileName:
          policyDocumentFileName ?? this.policyDocumentFileName,
      policyDocumentDownloadUrl:
          policyDocumentDownloadUrl ?? this.policyDocumentDownloadUrl,
      policyDocumentContentType:
          policyDocumentContentType ?? this.policyDocumentContentType,
      policyDocumentId: policyDocumentId ?? this.policyDocumentId,
    );
  }

  factory CustomerPolicySummary.fromJson(Map<String, dynamic> json) {
    final nested = json['policyDocument'];
    final document = nested is Map
        ? Map<String, dynamic>.from(nested)
        : const <String, dynamic>{};

    return CustomerPolicySummary(
      policyPublicId: jsonString(
        json['policyPublicId'],
        fallback: jsonString(json['publicId']),
      ),
      policyNumber: jsonString(json['policyNumber'], fallback: '—'),
      planName: jsonString(
        json['planName'],
        fallback: jsonString(json['productName'], fallback: 'Policy'),
      ),
      status: jsonString(json['status'], fallback: 'UNKNOWN'),
      planCategory: jsonNullableString(json['planCategory']),
      insurerName: jsonNullableString(json['insurerName']),
      premium: jsonNum(json['premium']),
      sumInsured: jsonNum(json['sumInsured']),
      startDate: jsonNullableString(json['startDate']),
      endDate: jsonNullableString(json['endDate']),
      renewalDate: jsonNullableString(json['renewalDate']),
      firstPolicyInceptionDate: jsonNullableString(
        json['firstPolicyInceptionDate'],
      ),
      policyTermYears: jsonNum(json['policyTermYears'])?.toInt(),
      renewalStatus: jsonNullableString(json['renewalStatus']),
      policyDocumentBase64: jsonNullableString(
        json['policyDocumentBase64'] ?? document['base64'],
      ),
      policyDocumentFileName: jsonNullableString(
        json['policyDocumentFileName'] ??
            document['fileName'] ??
            document['file_name'],
      ),
      policyDocumentDownloadUrl: jsonNullableString(
        json['policyDocumentDownloadUrl'] ??
            document['downloadUrl'] ??
            document['download_url'],
      ),
      policyDocumentContentType: jsonNullableString(
        json['policyDocumentContentType'] ??
            document['contentType'] ??
            document['content_type'],
      ),
      policyDocumentId: jsonNullableString(
        json['policyDocumentId'] ??
            document['documentId'] ??
            document['document_id'] ??
            document['id'],
      ),
    );
  }
}

class CustomerSummary {
  const CustomerSummary({
    required this.id,
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.policyCount,
    required this.status,
    this.userPublicId,
    this.policies = const [],
  });

  final String id;
  final String name;
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final int policyCount;
  final CustomerPolicyStatus status;
  final String? userPublicId;
  final List<CustomerPolicySummary> policies;

  String get initials {
    final parts = name
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

  String get policyBadgeLabel {
    if (policyCount <= 0) return 'No Policy';
    return policyCount == 1 ? '1 Policy' : '$policyCount Policies';
  }

  CustomerSummary copyWith({
    String? id,
    String? name,
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    int? policyCount,
    CustomerPolicyStatus? status,
    String? userPublicId,
    List<CustomerPolicySummary>? policies,
  }) {
    return CustomerSummary(
      id: id ?? this.id,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      policyCount: policyCount ?? this.policyCount,
      status: status ?? this.status,
      userPublicId: userPublicId ?? this.userPublicId,
      policies: policies ?? this.policies,
    );
  }

  factory CustomerSummary.fromJson(Map<String, dynamic> json) {
    var firstName = jsonString(json['firstName']);
    var lastName = jsonString(json['lastName']);
    final fullName = jsonString(
      json['customerFullName'],
      fallback: '$firstName $lastName'.trim(),
    );
    if (firstName.isEmpty && lastName.isEmpty && fullName.isNotEmpty) {
      final parts = fullName
          .split(RegExp(r'\s+'))
          .where((part) => part.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) {
        firstName = parts.first;
        lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }
    }
    final policies = <CustomerPolicySummary>[];
    final rawPolicies = json['policies'];
    if (rawPolicies is List) {
      for (final item in rawPolicies) {
        if (item is Map) {
          policies.add(
            CustomerPolicySummary.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    final policyCount = jsonInt(
      json['policyCount'],
      fallback: policies.length,
    );

    return CustomerSummary(
      id: jsonString(
        json['customerPublicId'],
        fallback: jsonString(json['userPublicId'], fallback: fullName),
      ),
      name: fullName.isEmpty ? 'Customer' : fullName,
      firstName: firstName,
      lastName: lastName,
      phone: jsonString(json['mobile']),
      email: jsonString(json['email']),
      policyCount: policyCount,
      status: _statusFrom(jsonString(json['status']), policyCount),
      userPublicId: jsonNullableString(json['userPublicId']),
      policies: policies,
    );
  }

  static CustomerPolicyStatus _statusFrom(String raw, int policyCount) {
    final status = raw.trim().toUpperCase().replaceAll('_', '-');
    if (policyCount <= 0 || status == 'NO-POLICY' || status == 'NOPOLICY') {
      return CustomerPolicyStatus.noPolicy;
    }
    if (status.contains('RENEW')) return CustomerPolicyStatus.renewalDue;
    if (status == 'INACTIVE') return CustomerPolicyStatus.inactive;
    return CustomerPolicyStatus.active;
  }
}

class CustomerDetailsPage {
  const CustomerDetailsPage({
    required this.content,
    required this.last,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  final List<CustomerSummary> content;
  final bool last;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  factory CustomerDetailsPage.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'];
    final content = <CustomerSummary>[];
    if (rawContent is List) {
      for (final item in rawContent) {
        if (item is Map) {
          content.add(
            CustomerSummary.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return CustomerDetailsPage(
      content: content,
      last: json['last'] == true,
      page: jsonInt(json['page']),
      size: jsonInt(json['size'], fallback: 20),
      totalElements: jsonInt(json['totalElements']),
      totalPages: jsonInt(json['totalPages']),
    );
  }

  static const empty = CustomerDetailsPage(
    content: [],
    last: true,
    page: 0,
    size: 20,
    totalElements: 0,
    totalPages: 0,
  );
}
