import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../storage/token_store.dart';
import 'auth_interceptor.dart';

Dio createDio(
  TokenStore tokenStore, {
  VoidCallback? onSessionCleared,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      // Browsers cannot apply a send timeout to requests without a body.
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      sendTimeout: kIsWeb ? null : AppConfig.sendTimeout,
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      responseType: ResponseType.json,
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(
      tokenStore,
      onSessionCleared: onSessionCleared,
    ),
  );
  if (kDebugMode) {
    dio.interceptors.add(DebugLogInterceptor());
  }
  return dio;
}
