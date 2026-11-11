import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/auth/session_controller.dart';
import 'core/network/api_client.dart';
import 'core/network/dio_factory.dart';
import 'core/storage/shared_prefs_token_store.dart';
import 'data/repositories/auth_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final tokenStore = SharedPrefsTokenStore(preferences);

  late final SessionController session;
  final apiClient = ApiClient(
    createDio(
      tokenStore,
      onSessionCleared: () => session.markSignedOut(),
    ),
  );
  final authRepository = AuthRepository(apiClient, tokenStore);
  session = SessionController(authRepository, tokenStore);
  await session.bootstrap();

  runApp(
    BirbalAdminApp(
      apiClient: apiClient,
      tokenStore: tokenStore,
      authRepository: authRepository,
      session: session,
    ),
  );
}
