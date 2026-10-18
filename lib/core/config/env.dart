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

  /// Phone (WhatsApp) login needs an SMS provider on the server, which isn't
  /// wired up yet; until then sign-up and login are email only.
  static const bool phoneLoginEnabled = false;

  // Publisher and public pages (also linked from the Play Store listing).
  static const String publisher = 'Nukta Technologies';
  static const String supportEmail = 'smnr7770@gmail.com';
  static const String privacyUrl = '$liveWeb/privacy-policy.html';
  static const String termsUrl = '$liveWeb/terms.html';
  static const String deleteAccountUrl = '$liveWeb/delete-account.html';
}
