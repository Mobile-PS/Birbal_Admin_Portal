/// Runtime configuration for the admin portal.
///
/// Point the app at another API without editing source:
/// `flutter run -d chrome --dart-define=BASE_URL=https://host/api/v1`
abstract final class AppConfig {
  static const appName = 'Birbal Advice Admin';

  /// Live API host.
  static const baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://birbaladvice.com/api/v1',
  );

  /// When true, no HTTP calls leave the app. Auth uses local stubs so flows
  /// still work. Keep `false` for the live API.
  static const disableApiCalls = false;

  static const connectTimeout = Duration(seconds: 20);
  static const receiveTimeout = Duration(seconds: 20);
  static const sendTimeout = Duration(seconds: 20);
}
