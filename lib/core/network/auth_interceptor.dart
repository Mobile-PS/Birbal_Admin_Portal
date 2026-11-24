import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_endpoints.dart';
import '../storage/token_store.dart';
import 'api_exception.dart';
import 'api_response.dart';

class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor(this._tokenStore, {this._onSessionCleared});

  final TokenStore _tokenStore;
  final VoidCallback? _onSessionCleared;
  bool _clearing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStore.readToken();
    if (kDebugMode) {
      debugPrint(
        token == null || token.isEmpty
            ? 'Auth token: <none> → ${options.method} ${options.uri}'
            : 'Auth token: $token → ${options.method} ${options.uri}',
      );
    }
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    if (_isAuthFailure(
      path: response.requestOptions.path,
      statusCode: response.statusCode,
      data: response.data,
    )) {
      final message = _authFailureMessage(response.data);
      await _clearSession();
      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: message,
        ),
      );
      return;
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (_isAuthFailure(
      path: err.requestOptions.path,
      statusCode: err.response?.statusCode,
      data: err.response?.data,
    )) {
      await _clearSession();
    }
    handler.next(err);
  }

  static const _publicPaths = {
    ApiEndpoints.requestOtp,
    ApiEndpoints.verifyOtp,
  };

  bool _isPublic(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return _publicPaths.any(
      (endpoint) =>
          normalized == endpoint || normalized.endsWith(endpoint),
    );
  }

  bool _isAuthFailure({
    required String path,
    required int? statusCode,
    required dynamic data,
  }) {
    if (_isPublic(path)) return false;
    if (statusCode == 401) return true;
    if (data is! Map) return false;

    final body = Map<String, dynamic>.from(data);
    if (ApiResponse.isSuccess(body)) return false;

    final message = ApiResponse.message(body, fallback: '').toLowerCase();
    return message.contains('authentication required') ||
        message.contains('unauthorized') ||
        message.contains('unauthenticated') ||
        message.contains('invalid token') ||
        message.contains('token expired') ||
        message.contains('session expired');
  }

  String _authFailureMessage(dynamic data) {
    if (data is Map) {
      return ApiResponse.message(
        Map<String, dynamic>.from(data),
        fallback: ApiException.unauthorizedMessage,
      );
    }
    return ApiException.unauthorizedMessage;
  }

  Future<void> _clearSession() async {
    if (_clearing) return;
    _clearing = true;
    try {
      await _tokenStore.clearSession();
      _onSessionCleared?.call();
    } finally {
      _clearing = false;
    }
  }
}

class DebugLogInterceptor extends Interceptor {
  static const _encoder = JsonEncoder.withIndent('  ');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      final buffer = StringBuffer()
        ..writeln('')
        ..writeln('┌──────────── REQUEST ────────────')
        ..writeln('│ ${options.method} ${options.uri}')
        ..writeln('│ Headers: ${_pretty(options.headers)}');
      if (options.queryParameters.isNotEmpty) {
        buffer.writeln('│ Query: ${_pretty(options.queryParameters)}');
      }
      if (options.data != null) {
        buffer.writeln('│ Body: ${_pretty(options.data)}');
      }
      buffer.write('└────────────────────────────────');
      debugPrint(buffer.toString());
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      final buffer = StringBuffer()
        ..writeln('')
        ..writeln('┌──────────── RESPONSE ───────────')
        ..writeln(
          '│ ${response.statusCode} '
          '${response.requestOptions.method} '
          '${response.requestOptions.uri}',
        )
        ..writeln('│ Body: ${_pretty(response.data)}')
        ..write('└────────────────────────────────');
      debugPrint(buffer.toString());
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final buffer = StringBuffer()
        ..writeln('')
        ..writeln('┌──────────── ERROR ──────────────')
        ..writeln(
          '│ ${err.response?.statusCode ?? err.type} '
          '${err.requestOptions.method} ${err.requestOptions.uri}',
        )
        ..writeln('│ Message: ${err.message}');
      if (err.response?.data != null) {
        buffer.writeln('│ Response body: ${_pretty(err.response?.data)}');
      }
      buffer.write('└────────────────────────────────');
      debugPrint(buffer.toString());
    }
    handler.next(err);
  }

  String _pretty(Object? data) {
    if (data == null) return 'null';
    if (data is FormData) {
      return {
        'fields': [
          for (final field in data.fields) '${field.key}=${field.value}',
        ],
        'files': [for (final file in data.files) file.key],
      }.toString();
    }
    try {
      if (data is Map || data is List) {
        return '\n${_encoder.convert(data)}';
      }
      if (data is String) {
        final trimmed = data.trim();
        if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
          return '\n${_encoder.convert(jsonDecode(trimmed))}';
        }
        return data;
      }
    } catch (_) {}
    return data.toString();
  }
}
