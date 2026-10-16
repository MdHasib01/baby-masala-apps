import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the JWT. Equivalent of `tokenStore` (localStorage `babycare_token`)
/// in the web app, but in the Android keystore.
class TokenStore {
  TokenStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'babycare_token';
  final FlutterSecureStorage _storage;
  String? _cached;

  String? get current => _cached;

  Future<String?> load() async {
    try {
      _cached = await _storage.read(key: _key);
    } catch (_) {
      _cached = null;
    }
    return _cached;
  }

  Future<void> set(String token) async {
    _cached = token;
    try {
      await _storage.write(key: _key, value: token);
    } catch (_) {
      /* storage unavailable: session lasts until app restart */
    }
  }

  Future<void> clear() async {
    _cached = null;
    try {
      await _storage.delete(key: _key);
    } catch (_) {}
  }
}
