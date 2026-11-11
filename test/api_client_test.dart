import 'package:birbal_advice_admin_portal/core/network/api_client.dart';
import 'package:birbal_advice_admin_portal/core/network/api_exception.dart';
import 'package:birbal_advice_admin_portal/core/network/auth_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/json_adapter.dart';
import 'support/memory_token_store.dart';

void main() {
  test('returns the decoded body for a successful call', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'));
    dio.httpClientAdapter = JsonAdapter((options) async {
      return jsonBody({
        'status': true,
        'data': {'count': 3},
      });
    });

    final body = await ApiClient(dio).get('/customers') as Map;
    expect(body['status'], isTrue);
    expect(body['data'], {'count': 3});
  });

  test('maps the API envelope message onto ApiException', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'));
    dio.httpClientAdapter = JsonAdapter((options) async {
      return jsonBody({
        'status': false,
        'message': 'Email is required',
      }, statusCode: 422);
    });

    expect(
      () => ApiClient(dio).post('/customers', data: const {}),
      throwsA(
        isA<ApiException>()
            .having((error) => error.message, 'message', 'Email is required')
            .having((error) => error.statusCode, 'statusCode', 422),
      ),
    );
  });

  test('maps Dio timeout errors onto ApiException', () {
    final error = ApiException.fromDio(
      DioException(
        requestOptions: RequestOptions(path: '/customers'),
        type: DioExceptionType.connectionTimeout,
      ),
    );

    expect(error.message, contains('timed out'));
  });

  test('auth interceptor attaches the bearer token', () async {
    final store = MemoryTokenStore()..token = 'secret-token';
    final dio = Dio(BaseOptions(baseUrl: 'http://example.com'));
    late RequestOptions captured;

    dio.interceptors.add(AuthInterceptor(store));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured = options;
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {'status': true},
            ),
          );
        },
      ),
    );

    await dio.get<dynamic>('/customers');
    expect(captured.headers['Authorization'], 'Bearer secret-token');
  });
}
