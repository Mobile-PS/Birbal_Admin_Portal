import 'dart:typed_data';

Future<void> saveDocumentBytes({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  required String subject,
}) async {
  throw UnsupportedError('Document save is not supported on this platform.');
}
