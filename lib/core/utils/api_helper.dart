import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

Map<String, dynamic> parseJsonResponse(http.Response response) {
  if (response.statusCode >= 200 && response.statusCode < 300) {
    if (response.body.isEmpty) return {};
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {'data': decoded};
  }

  String message = 'Request failed (${response.statusCode})';
  try {
    final body = jsonDecode(response.body);
    if (body is Map) {
      if (body['detail'] != null) {
        message = body['detail'].toString();
      } else {
        final first = body.values.first;
        if (first is List && first.isNotEmpty) {
          message = first.first.toString();
        }
      }
    }
  } catch (_) {}
  throw ApiException(message, statusCode: response.statusCode);
}

List<dynamic> parseListResponse(http.Response response) {
  final json = parseJsonResponse(response);
  if (json.containsKey('results') && json['results'] is List) {
    return json['results'] as List;
  }
  if (json.containsKey('data') && json['data'] is List) {
    return json['data'] as List;
  }
  throw ApiException('Unexpected list response format');
}

double parseDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

int parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

DateTime? parseDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

DateTime parseDate(dynamic value) {
  if (value == null) return DateTime.now();
  final parsed = DateTime.tryParse(value.toString());
  if (parsed != null) return parsed;
  return DateTime.now();
}
