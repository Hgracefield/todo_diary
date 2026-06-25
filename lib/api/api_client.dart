import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:my_todo_list_app/api/api_config.dart';
import 'package:my_todo_list_app/api/api_exception.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Map<String, String> get _headers => const {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  Future<List<dynamic>> getList(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _client.get(
      ApiConfig.uri(path, queryParameters),
      headers: _headers,
    );
    final decoded = _decode(response);
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic> && decoded['data'] is List) {
      return decoded['data'] as List<dynamic>;
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: 'Expected list response from $path',
    );
  }

  Future<Map<String, dynamic>> getMap(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _client.get(
      ApiConfig.uri(path, queryParameters),
      headers: _headers,
    );
    final decoded = _decode(response);
    if (decoded is Map<String, dynamic>) return decoded;
    throw ApiException(
      statusCode: response.statusCode,
      message: 'Expected object response from $path',
    );
  }

  Future<Map<String, dynamic>?> getNullableMap(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _client.get(
      ApiConfig.uri(path, queryParameters),
      headers: _headers,
    );
    if (response.statusCode == 404 || response.body.trim().isEmpty) {
      return null;
    }
    final decoded = _decode(response);
    if (decoded is Map<String, dynamic>) return decoded;
    throw ApiException(
      statusCode: response.statusCode,
      message: 'Expected object response from $path',
    );
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) {
    return _sendWithBody('POST', path, body);
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) {
    return _sendWithBody('PATCH', path, body);
  }

  Future<void> delete(String path) async {
    final response = await _client.delete(
      ApiConfig.uri(path),
      headers: _headers,
    );
    _decode(response, allowEmpty: true);
  }

  Future<Map<String, dynamic>> _sendWithBody(
    String method,
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = ApiConfig.uri(path);
    final encodedBody = jsonEncode(body);
    final response = switch (method) {
      'POST' => await _client.post(uri, headers: _headers, body: encodedBody),
      'PATCH' => await _client.patch(uri, headers: _headers, body: encodedBody),
      _ => throw ArgumentError('Unsupported method: $method'),
    };
    final decoded = _decode(response);
    if (decoded is Map<String, dynamic>) return decoded;
    throw ApiException(
      statusCode: response.statusCode,
      message: 'Expected object response from $path',
    );
  }

  dynamic _decode(http.Response response, {bool allowEmpty = false}) {
    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
    if (!isSuccess) {
      throw ApiException(
        statusCode: response.statusCode,
        message: response.body.isEmpty
            ? response.reasonPhrase ?? 'API error'
            : response.body,
      );
    }

    if (response.body.trim().isEmpty) {
      return allowEmpty ? null : <String, dynamic>{};
    }

    return jsonDecode(utf8.decode(response.bodyBytes));
  }
}
