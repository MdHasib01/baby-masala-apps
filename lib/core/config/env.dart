/// Build-time configuration.
///
/// Defaults:
///   * release builds → live server  https://babymasalabd.com/api
///   * debug/profile  → local backend as seen from the Android emulator
///                      (10.0.2.2 == host's localhost)
///
/// Override either with:
///   flutter run --dart-define=API_BASE_URL=http://192.168.0.10:5000/api
class Env {
  const Env._();

  static const String liveApi = 'https://babymasalabd.com/api';
  static const String liveWeb = 'https://babymasalabd.com';
  static const String devApi = 'http://10.0.2.2:5000/api';

  static const bool _isRelease = bool.fromEnvironment('dart.vm.product');

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _isRelease ? liveApi : devApi,
  );

  /// Used for "copy post link" — same shape as the web app's
  /// `${origin}/community/post/{id}`.
  static const String webOrigin = String.fromEnvironment(
    'WEB_ORIGIN',
    defaultValue: liveWeb,
  );
}
