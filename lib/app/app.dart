import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/session_controller.dart';
import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/routing/app_router.dart';
import '../core/storage/token_store.dart';
import '../data/repositories/auth_repository.dart';
import 'app_scope.dart';
import 'theme/app_theme.dart';

class BirbalAdminApp extends StatefulWidget {
  const BirbalAdminApp({
    required this.apiClient,
    required this.tokenStore,
    required this.authRepository,
    required this.session,
    super.key,
  });

  final ApiClient apiClient;
  final TokenStore tokenStore;
  final AuthRepository authRepository;
  final SessionController session;

  @override
  State<BirbalAdminApp> createState() => _BirbalAdminAppState();
}

class _BirbalAdminAppState extends State<BirbalAdminApp> {
  late final GoRouter _router = createAppRouter(widget.session);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      apiClient: widget.apiClient,
      tokenStore: widget.tokenStore,
      authRepository: widget.authRepository,
      session: widget.session,
      child: MaterialApp.router(
        title: AppConfig.appName,
        theme: AppTheme.light(),
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
        builder: (context, child) {
          final scaler = MediaQuery.textScalerOf(context).clamp(
            minScaleFactor: 0.9,
            maxScaleFactor: 1.3,
          );
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: scaler),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
