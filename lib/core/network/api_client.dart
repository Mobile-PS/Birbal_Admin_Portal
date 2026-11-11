import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'api_exception.dart';

/// Thin Dio wrapper. Successful calls return the decoded body.
/// Failures throw [ApiException] instead of [DioException].
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  static const disabledMessage =
      'API calls are disabled. Turn off AppConfig.disableApiCalls to use the server.';

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _send(
      () => _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<dynamic> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _send(
      () => _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<dynamic> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _send(
      () => _dio.put<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<dynamic> patch(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _send(
      () => _dio.patch<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<dynamic> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _send(
      () => _dio.delete<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<dynamic> _send(Future<Response<dynamic>> Function() call) async {
    if (AppConfig.disableApiCalls) {
      if (kDebugMode) {
        debugPrint('API disabled — blocked network call');
      }
      throw const ApiException(disabledMessage);
    }

    try {
      final response = await call();
      return response.data;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
