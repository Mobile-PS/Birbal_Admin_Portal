import '../../core/utils/document_base64.dart';
import '../../core/utils/json_utils.dart';

class ProductEntry {
  ProductEntry({
    required this.id,
    required this.productCategory,
    this.isEnabled = true,
    this.displayOrder = 0,
    this.planCount = 0,
    this.documentBase64,
    this.documentFileName,
  });

  final String id;
  final String productCategory;
  bool isEnabled;
  final int displayOrder;
  final int planCount;
  final String? documentBase64;
  final String? documentFileName;

  /// Normalized image data-URI when an icon is present.
  String? get imageDataUri => DocumentBase64.normalize(
        documentBase64,
        fileName: documentFileName,
      );

  bool get hasIcon {
    final value = imageDataUri;
    return value != null && value.isNotEmpty;
  }

  factory ProductEntry.fromJson(Map<String, dynamic> json) {
    final nested = json['document'];
    final document = nested is Map
        ? Map<String, dynamic>.from(nested)
        : const <String, dynamic>{};

    return ProductEntry(
      id: jsonString(json['code'], fallback: jsonString(json['category'])),
      productCategory: jsonString(json['category'], fallback: 'Category'),
      isEnabled: json['active'] != false,
      displayOrder: jsonInt(json['displayOrder']),
      planCount: jsonInt(json['planCount']),
      documentBase64: jsonNullableString(
        json['documentBase64'] ??
            json['document_base64'] ??
            json['imageBase64'] ??
            json['image_base64'] ??
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
    );
  }
}
