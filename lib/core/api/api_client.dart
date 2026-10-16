import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/env.dart';
import 'api_exception.dart';
import 'token_store.dart';

/// Thin HTTP wrapper — the Dart twin of `apiRequest()` in
/// frontend/src/services/api.ts.
///
/// * Sends `Authorization: Bearer <token>` when signed in.
/// * Converts every failure into [ApiException] (Bengali message + code).
/// * On 401 with a token, clears it and calls [onUnauthorized].
class ApiClient {
  ApiClient({required this.tokens, String? baseUrl, Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: (baseUrl ?? Env.apiBaseUrl).replaceAll(RegExp(r'/$'), ''),
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 60),
              responseType: ResponseType.json,
              // We map status codes ourselves.
              validateStatus: (_) => true,
            ));

  final Dio _dio;
  final TokenStore tokens;

  /// Set by the session layer so a rejected token returns the user to Welcome.
  void Function()? onUnauthorized;

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) =>
      request('GET', path, query: query);
  Future<Map<String, dynamic>> post(String path, [Object? body = const {}]) =>
      request('POST', path, body: body);
  Future<Map<String, dynamic>> patch(String path, Object body) => request('PATCH', path, body: body);
  Future<Map<String, dynamic>> put(String path, Object body) => request('PUT', path, body: body);
  Future<Map<String, dynamic>> delete(String path) => request('DELETE', path);

  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
  }) async {
    final token = tokens.current;
    final headers = <String, String>{
      if (body != null) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    Response<dynamic> res;
    try {
      res = await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: query?..removeWhere((_, v) => v == null),
        options: Options(method: method, headers: headers),
      );
    } on DioException catch (e) {
      debugPrint('[api] $method $path → ${e.type}: ${e.message ?? e.error}');
      throw ApiException.network();
    }

    final status = res.statusCode ?? 0;
    final data = res.data;
    if (status < 200 || status >= 300) {
      if (status == 401 && token != null) {
        await tokens.clear();
        onUnauthorized?.call();
      }
      throw ApiException.fromResponse(status, data);
    }
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }
}

/// `encodeURIComponent` equivalent for path segments.
String seg(String id) => Uri.encodeComponent(id);
