import 'package:flutter/widgets.dart';

import '../core/auth/session_controller.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_store.dart';
import '../data/repositories/auth_repository.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    required this.apiClient,
    required this.tokenStore,
    required this.authRepository,
    required this.session,
    required super.child,
    super.key,
  });

  final ApiClient apiClient;
  final TokenStore tokenStore;
  final AuthRepository authRepository;
  final SessionController session;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing above this widget.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) {
    return apiClient != oldWidget.apiClient ||
        tokenStore != oldWidget.tokenStore ||
        authRepository != oldWidget.authRepository ||
        session != oldWidget.session;
  }
}
