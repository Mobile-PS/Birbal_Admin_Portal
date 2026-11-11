import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  static const unauthorizedMessage =
      'Your session has expired. Please sign in again.';

  factory ApiException.fromDio(DioException error) {
    final status = error.response?.statusCode;
    final serverMessage = _extractMessage(error.response?.data);
    if (serverMessage != null) {
      return ApiException(serverMessage, statusCode: status);
    }

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout => ApiException(
        'The request timed out. Check your connection and try again.',
        statusCode: status,
      ),
      DioExceptionType.connectionError => const ApiException(
        'Unable to reach the server. Check your internet connection.',
      ),
      DioExceptionType.cancel => const ApiException(
        'The request was cancelled.',
      ),
      DioExceptionType.badCertificate => const ApiException(
        'The secure connection could not be verified.',
      ),
      DioExceptionType.badResponse => ApiException(
        _messageForStatus(status),
        statusCode: status,
      ),
      DioExceptionType.unknown => ApiException(
        'Something went wrong. Please try again.',
        statusCode: status,
      ),
    };
  }

  static String? _extractMessage(dynamic data) {
    if (data is! Map) return null;

    final topMessage = data['message'];
    if (topMessage is String && topMessage.trim().isNotEmpty) {
      return topMessage.trim();
    }

    final error = data['error'];
    if (error is Map) {
      final errorMessage = error['message'];
      if (errorMessage is String && errorMessage.trim().isNotEmpty) {
        return errorMessage.trim();
      }
      final details = error['details'];
      if (details is List && details.isNotEmpty) {
        final first = details.first;
        if (first is Map) {
          final fieldMessage = first['message'];
          if (fieldMessage is String && fieldMessage.trim().isNotEmpty) {
            return fieldMessage.trim();
          }
        }
      }
    }

    if (error is String && error.trim().isNotEmpty) {
      return error.trim();
    }
    if (topMessage is List && topMessage.isNotEmpty) {
      return topMessage.first.toString();
    }
    return null;
  }

  /// Reads `message` / nested `error` from the standard API envelope.
  static String messageFromBody(
    Map<String, dynamic> body, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    return _extractMessage(body) ?? fallback;
  }

  static String _messageForStatus(int? status) {
    return switch (status) {
      400 => 'The request could not be processed.',
      401 => unauthorizedMessage,
      403 => 'You do not have access to this.',
      404 => 'We could not find what you were looking for.',
      422 => 'Please check the details and try again.',
      500 || 502 || 503 => 'The server is unavailable. Try again shortly.',
      _ => 'Something went wrong. Please try again.',
    };
  }

  @override
  String toString() => message;
}
