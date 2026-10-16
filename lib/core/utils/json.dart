/// Tolerant JSON readers. The API sometimes omits optional fields, and numbers
/// can arrive as int or double — these helpers never throw.
library;

typedef Json = Map<String, dynamic>;

String jStr(Json j, String k, [String fallback = '']) {
  final v = j[k];
  if (v == null) return fallback;
  return v is String ? v : '$v';
}

String? jStrN(Json j, String k) {
  final v = j[k];
  if (v == null) return null;
  final s = v is String ? v : '$v';
  return s.isEmpty ? null : s;
}

int jInt(Json j, String k, [int fallback = 0]) {
  final v = j[k];
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

int? jIntN(Json j, String k) {
  final v = j[k];
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double jDouble(Json j, String k, [double fallback = 0]) {
  final v = j[k];
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

double? jDoubleN(Json j, String k) {
  final v = j[k];
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

bool jBool(Json j, String k, [bool fallback = false]) {
  final v = j[k];
  return v is bool ? v : fallback;
}

Json jMap(Json j, String k) {
  final v = j[k];
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return <String, dynamic>{};
}

List<String> jStrList(Json j, String k) {
  final v = j[k];
  if (v is List) return v.map((e) => '$e').toList();
  return const [];
}

List<T> jList<T>(Json j, String k, T Function(Json) parse) {
  final v = j[k];
  if (v is! List) return <T>[];
  return v.whereType<Map>().map((e) => parse(Map<String, dynamic>.from(e))).toList();
}

/// Removes null values so we never send `"field": null` (the backend's
/// validators treat absent and null differently).
Json compact(Json m) => m..removeWhere((_, v) => v == null);
