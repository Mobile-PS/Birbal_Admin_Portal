import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

class JsonAdapter implements HttpClientAdapter {
  JsonAdapter(this.onFetch);

  final Future<ResponseBody> Function(RequestOptions options) onFetch;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return onFetch(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(Object data, {int statusCode = 200}) {
  return ResponseBody.fromString(
    data is String ? data : jsonEncode(data),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}
