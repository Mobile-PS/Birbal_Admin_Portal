/// Runtime configuration for the admin portal.
///
/// Point the app at another API without editing source:
/// `flutter run -d chrome --dart-define=BASE_URL=http://host/api/v1`
abstract final class AppConfig {
  static const appName = 'Birbal Advice Admin';

  /// Same host as the customer app.
  static const baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://16.170.172.250/api/v1',
  );

  /// When true, no HTTP calls leave the app. Auth uses local stubs so flows
  /// still work. Keep `false` for the live API.
  static const disableApiCalls = false;

  static const connectTimeout = Duration(seconds: 20);
  static const receiveTimeout = Duration(seconds: 20);
  static const sendTimeout = Duration(seconds: 20);
}
