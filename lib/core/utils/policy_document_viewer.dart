import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../app/theme/app_colors.dart';
import '../../data/models/customer_summary.dart';
import '../widgets/app_snackbar.dart';
import 'document_base64.dart';
import 'policy_document_save_stub.dart'
    if (dart.library.html) 'policy_document_save_web.dart'
    if (dart.library.io) 'policy_document_save_io.dart';

DecodedDataUri? decodeDocumentBase64(
  String? raw, {
  String? contentType,
  String? fileName,
}) {
  final dataUri = DocumentBase64.normalize(
    raw,
    contentType: contentType,
    fileName: fileName,
  );
  return decodeDataUri(dataUri);
}

Future<void> openBase64Document(
  BuildContext context, {
  required String? documentBase64,
  String title = 'Document',
  String? contentType,
  String? fileName,
  String unavailableMessage = 'No document is available.',
}) async {
  final decoded = decodeDocumentBase64(
    documentBase64,
    contentType: contentType,
    fileName: fileName,
  );
  if (decoded == null) {
    if (context.mounted) {
      showAppMessage(context, 'Unavailable', unavailableMessage);
    }
    return;
  }

  final displayName = (fileName?.trim().isNotEmpty ?? false)
      ? fileName!.trim()
      : title;

  await showDialog<void>(
    context: context,
    builder: (context) => _DocumentViewerDialog(
      title: displayName,
      decoded: decoded,
      onDownload: () => downloadBase64Document(
        context,
        documentBase64: documentBase64,
        title: displayName,
        contentType: contentType,
        fileName: fileName,
        unavailableMessage: unavailableMessage,
      ),
    ),
  );
}

Future<void> downloadBase64Document(
  BuildContext context, {
  required String? documentBase64,
  String title = 'Document',
  String? contentType,
  String? fileName,
  String unavailableMessage = 'No document is available.',
}) async {
  final decoded = decodeDocumentBase64(
    documentBase64,
    contentType: contentType,
    fileName: fileName,
  );
  if (decoded == null) {
    if (context.mounted) {
      showAppMessage(context, 'Unavailable', unavailableMessage);
    }
    return;
  }

  final displayName = (fileName?.trim().isNotEmpty ?? false)
      ? fileName!.trim()
      : title;
  final safeName = _safeFileName(displayName, decoded.mimeType);

  try {
    await saveDocumentBytes(
      bytes: decoded.bytes,
      fileName: safeName,
      mimeType: decoded.mimeType,
      subject: displayName,
    );
    if (context.mounted) {
      showAppMessage(context, 'Downloaded', safeName);
    }
  } catch (_) {
    if (context.mounted) {
      showAppMessage(
        context,
        'Download failed',
        'Could not save this document.',
      );
    }
  }
}

Future<void> openPolicyDocument(
  BuildContext context,
  CustomerPolicySummary policy,
) {
  return openBase64Document(
    context,
    documentBase64: policy.policyDocumentBase64,
    title: policy.documentDisplayName,
    contentType: policy.policyDocumentContentType,
    fileName: policy.policyDocumentFileName,
    unavailableMessage:
        'No policy document is available for this policy.',
  );
}

Future<void> downloadPolicyDocument(
  BuildContext context,
  CustomerPolicySummary policy,
) {
  return downloadBase64Document(
    context,
    documentBase64: policy.policyDocumentBase64,
    title: policy.documentDisplayName,
    contentType: policy.policyDocumentContentType,
    fileName: policy.policyDocumentFileName,
    unavailableMessage:
        'No policy document is available for this policy.',
  );
}

String _safeFileName(String name, String mimeType) {
  final cleaned = name
      .trim()
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .replaceAll(RegExp(r'\s+'), '_');
  if (cleaned.contains('.')) return cleaned;
  if (mimeType.contains('pdf')) return '$cleaned.pdf';
  if (mimeType.contains('png')) return '$cleaned.png';
  if (mimeType.contains('webp')) return '$cleaned.webp';
  if (mimeType.contains('jpeg') || mimeType.contains('jpg')) {
    return '$cleaned.jpg';
  }
  return cleaned;
}

class _DocumentViewerDialog extends StatelessWidget {
  const _DocumentViewerDialog({
    required this.title,
    required this.decoded,
    required this.onDownload,
  });

  final String title;
  final DecodedDataUri decoded;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Download',
                    onPressed: onDownload,
                    icon: const Icon(Icons.download_rounded),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: decoded.isImage
                  ? InteractiveViewer(
                      child: Center(
                        child: Image.memory(
                          decoded.bytes,
                          fit: BoxFit.contain,
                        ),
                      ),
                    )
                  : decoded.isPdf
                      ? PdfViewer.data(
                          Uint8List.fromList(decoded.bytes),
                          sourceName: 'document-${decoded.bytes.length}.pdf',
                          params: const PdfViewerParams(
                            margin: 8,
                            backgroundColor: Color(0xFFF4F8F7),
                          ),
                        )
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.insert_drive_file_outlined,
                                  size: 48,
                                  color: AppColors.brand,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Document attached (${decoded.mimeType})',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.navy,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: onDownload,
                                  icon: const Icon(Icons.download_rounded),
                                  label: const Text('Download'),
                                ),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
