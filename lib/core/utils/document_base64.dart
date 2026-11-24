import 'dart:convert';
import 'dart:typed_data';

/// Helpers for image/PDF base64 used in request + response payloads.
abstract final class DocumentBase64 {
  static final RegExp _dataUriPattern = RegExp(
    r'^data:([^;,]+)?(?:;charset=[^;,]+)?;base64,(.+)$',
    caseSensitive: false,
    dotAll: true,
  );

  static String? normalize(
    String? raw, {
    String? contentType,
    String? fileName,
  }) {
    if (raw == null) return null;
    final value = raw.trim();
    if (value.isEmpty) return null;

    final match = _dataUriPattern.firstMatch(value);
    if (match != null) {
      final encoded = (match.group(2) ?? '').replaceAll(RegExp(r'\s'), '');
      if (encoded.isEmpty) return null;
      final declaredMime = (match.group(1) ?? '').trim();
      final mime = _resolveMime(
        declaredMime: declaredMime,
        contentType: contentType,
        fileName: fileName,
        encoded: encoded,
      );
      return 'data:$mime;base64,$encoded';
    }

    final encoded = value.replaceAll(RegExp(r'\s'), '');
    if (encoded.isEmpty) return null;
    try {
      base64Decode(encoded);
    } on FormatException {
      return null;
    }

    final mime = _resolveMime(
      declaredMime: null,
      contentType: contentType,
      fileName: fileName,
      encoded: encoded,
    );
    return 'data:$mime;base64,$encoded';
  }

  static bool isPdf(String? raw, {String? contentType, String? fileName}) {
    final normalized = normalize(
      raw,
      contentType: contentType,
      fileName: fileName,
    );
    if (normalized == null) return false;
    return normalized.toLowerCase().startsWith('data:application/pdf');
  }

  static bool isImage(String? raw, {String? contentType, String? fileName}) {
    final normalized = normalize(
      raw,
      contentType: contentType,
      fileName: fileName,
    );
    if (normalized == null) return false;
    return normalized.toLowerCase().startsWith('data:image/');
  }

  static String _resolveMime({
    required String? declaredMime,
    required String? contentType,
    required String? fileName,
    required String encoded,
  }) {
    final fromContentType = _mimeFromContentType(contentType);
    if (fromContentType != null) return fromContentType;

    final fromName = _mimeFromName(fileName);
    if (fromName != null) return fromName;

    final fromDeclared = _mimeFromContentType(declaredMime);
    if (fromDeclared != null && fromDeclared != 'application/octet-stream') {
      return fromDeclared;
    }

    try {
      final bytes = base64Decode(encoded);
      final fromBytes = _mimeFromBytes(bytes);
      if (fromBytes != null) return fromBytes;
    } on FormatException {
      // Fall through.
    }

    if (fromDeclared != null) return fromDeclared;
    return 'application/octet-stream';
  }

  static String? _mimeFromContentType(String? value) {
    if (value == null) return null;
    final mime = value.trim().toLowerCase();
    if (mime.isEmpty) return null;
    if (mime.contains('pdf')) return 'application/pdf';
    if (mime.contains('png')) return 'image/png';
    if (mime.contains('webp')) return 'image/webp';
    if (mime.contains('jpeg') || mime.contains('jpg')) return 'image/jpeg';
    if (mime.startsWith('image/')) return mime;
    if (mime == 'application/octet-stream') return mime;
    return mime;
  }

  static String? _mimeFromName(String? name) {
    if (name == null || name.trim().isEmpty) return null;
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return null;
  }

  static String? _mimeFromBytes(List<int> bytes) {
    if (bytes.length >= 4 &&
        bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46) {
      return 'application/pdf';
    }
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
    return null;
  }
}

class DecodedDataUri {
  const DecodedDataUri({
    required this.bytes,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String mimeType;

  bool get isImage =>
      mimeType.startsWith('image/') || _looksLikeImage(bytes);

  bool get isPdf => mimeType.contains('pdf') || _looksLikePdf(bytes);
}

DecodedDataUri? decodeDataUri(String? raw) {
  final normalized = DocumentBase64.normalize(raw);
  if (normalized == null) return null;

  final match = RegExp(
    r'^data:([^;,]+)?(?:;charset=[^;,]+)?;base64,(.+)$',
    caseSensitive: false,
    dotAll: true,
  ).firstMatch(normalized);
  if (match == null) return null;

  try {
    final mime = (match.group(1) ?? 'application/octet-stream').trim();
    final encoded = (match.group(2) ?? '').replaceAll(RegExp(r'\s'), '');
    if (encoded.isEmpty) return null;
    return DecodedDataUri(bytes: base64Decode(encoded), mimeType: mime);
  } on FormatException {
    return null;
  }
}

bool _looksLikePdf(List<int> bytes) {
  return bytes.length >= 4 &&
      bytes[0] == 0x25 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x44 &&
      bytes[3] == 0x46;
}

bool _looksLikeImage(List<int> bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return true;
  }
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return true;
  }
  return false;
}
