import '../../core/utils/json_utils.dart';

class InsurancePlanModel {
  const InsurancePlanModel({
    required this.publicId,
    required this.name,
    required this.category,
    this.insurerName,
    this.description,
    this.documentBase64,
    this.documentFileName,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  final String publicId;
  final String name;
  final String category;
  final String? insurerName;
  final String? description;
  final String? documentBase64;
  final String? documentFileName;
  final bool active;
  final String? createdAt;
  final String? updatedAt;

  bool get hasDocument {
    final document = documentBase64?.trim();
    return document != null && document.isNotEmpty;
  }

  String get documentDisplayName {
    final name = documentFileName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Plan document';
  }

  factory InsurancePlanModel.fromJson(Map<String, dynamic> json) {
    final nested = json['document'];
    final document = nested is Map
        ? Map<String, dynamic>.from(nested)
        : const <String, dynamic>{};

    return InsurancePlanModel(
      publicId: jsonString(json['publicId'] ?? json['public_id'] ?? json['id']),
      name: jsonString(json['name'], fallback: 'Insurance plan'),
      category: jsonString(json['category']),
      insurerName: jsonNullableString(
        json['insurerName'] ?? json['insurer_name'],
      ),
      description: jsonNullableString(json['description']),
      documentBase64: jsonNullableString(
        json['documentBase64'] ??
            json['document_base64'] ??
            document['base64'] ??
            document['documentBase64'],
      ),
      documentFileName: jsonNullableString(
        json['documentFileName'] ??
            json['document_file_name'] ??
            json['fileName'] ??
            document['fileName'] ??
            document['file_name'],
      ),
      active: json['active'] != false,
      createdAt: jsonNullableString(json['createdAt'] ?? json['created_at']),
      updatedAt: jsonNullableString(json['updatedAt'] ?? json['updated_at']),
    );
  }
}

class InsurancePlanPage {
  const InsurancePlanPage({
    required this.content,
    this.page = 0,
    this.size = 50,
    this.totalElements = 0,
    this.totalPages = 0,
    this.last = true,
  });

  final List<InsurancePlanModel> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool last;

  factory InsurancePlanPage.fromData(Map<String, dynamic> data) {
    final rawContent = data['content'];
    final content = <InsurancePlanModel>[];
    if (rawContent is List) {
      for (final item in rawContent) {
        if (item is Map) {
          content.add(
            InsurancePlanModel.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return InsurancePlanPage(
      content: content,
      page: jsonInt(data['page']),
      size: jsonInt(data['size'], fallback: content.length),
      totalElements: jsonInt(
        data['totalElements'] ?? data['total_elements'],
        fallback: content.length,
      ),
      totalPages: jsonInt(
        data['totalPages'] ?? data['total_pages'],
        fallback: 1,
      ),
      last: data['last'] != false,
    );
  }

  static const empty = InsurancePlanPage(content: []);
}
