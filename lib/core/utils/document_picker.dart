import 'dart:convert';

import 'package:file_picker/file_picker.dart';

class PickedDocument {
  const PickedDocument({
    required this.fileName,
    required this.dataUri,
  });

  final String fileName;
  final String dataUri;
}

Future<PickedDocument?> pickDocumentAsBase64DataUri() async {
  final files = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['pdf'],
  );
  if (files.isEmpty) return null;

  final file = files.first;
  final bytes = await file.readAsBytes();
  if (bytes.isEmpty) return null;

  final fileName = file.name;
  if (!fileName.toLowerCase().endsWith('.pdf') && !_isPdfBytes(bytes)) {
    return null;
  }

  final dataUri = 'data:application/pdf;base64,${base64Encode(bytes)}';
  return PickedDocument(fileName: fileName, dataUri: dataUri);
}

Future<PickedDocument?> pickImageAsBase64DataUri() async {
  final files = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
  );
  if (files.isEmpty) return null;

  final file = files.first;
  final bytes = await file.readAsBytes();
  if (bytes.isEmpty) return null;

  final fileName = file.name;
  final mime = _imageMimeFromName(fileName) ??
      _imageMimeFromBytes(bytes) ??
      'image/png';
  if (!_isImageBytes(bytes) && _imageMimeFromName(fileName) == null) {
    return null;
  }

  final dataUri = 'data:$mime;base64,${base64Encode(bytes)}';
  return PickedDocument(fileName: fileName, dataUri: dataUri);
}

bool _isPdfBytes(List<int> bytes) {
  return bytes.length >= 4 &&
      bytes[0] == 0x25 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x44 &&
      bytes[3] == 0x46;
}

bool _isImageBytes(List<int> bytes) {
  return _imageMimeFromBytes(bytes) != null;
}

String? _imageMimeFromName(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.webp')) return 'image/webp';
  return null;
}

String? _imageMimeFromBytes(List<int> bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return 'image/jpeg';
  }
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return 'image/png';
  }
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return 'image/webp';
  }
  return null;
}
