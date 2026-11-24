import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> saveDocumentBytes({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  required String subject,
}) async {
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile(file.path, mimeType: mimeType, name: fileName),
      ],
      subject: subject,
    ),
  );
}
