/// Mirrors `ApiError` in frontend/src/services/api.ts.
///
/// The backend always answers errors as `{ message, code }` where `message` is
/// Bengali text that is safe to show to the user.
class ApiException implements Exception {
  ApiException(this.status, this.message, [this.code]);

  final int status;
  final String message;
  final String? code;

  static const String genericMessage = 'কিছু একটা সমস্যা হয়েছে। আবার চেষ্টা করুন।';
  static const String networkMessage = 'সার্ভারের সাথে সংযোগ করা যাচ্ছে না। ইন্টারনেট সংযোগ পরীক্ষা করুন।';

  factory ApiException.fromResponse(int status, Object? data) {
    if (data is Map) {
      final msg = data['message'];
      final code = data['code'];
      return ApiException(
        status,
        msg is String && msg.isNotEmpty ? msg : genericMessage,
        code is String ? code : null,
      );
    }
    return ApiException(status, genericMessage);
  }

  factory ApiException.network() => ApiException(0, networkMessage, 'NETWORK');

  @override
  String toString() => message;
}

/// Same as `errorMessage()` in the web app.
String errorMessage(Object err) =>
    err is ApiException ? err.message : ApiException.genericMessage;
