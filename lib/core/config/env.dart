/// Build-time configuration.
///
/// Override with:
///   flutter run --dart-define=API_BASE_URL=http://192.168.0.10:5000/api
///
/// The default points at the backend on the host machine as seen from the
/// Android emulator (10.0.2.2 == host's localhost).
class Env {
  const Env._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000/api',
  );

  /// Used for "copy post link" — same shape as the web app's
  /// `${origin}/community/post/{id}`.
  static const String webOrigin = String.fromEnvironment(
    'WEB_ORIGIN',
    defaultValue: 'https://babycare.babymasala.com',
  );
}
