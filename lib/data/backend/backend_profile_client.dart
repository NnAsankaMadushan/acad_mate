import 'dart:convert';

import 'package:http/http.dart' as http;

class BackendProfileClient {
  BackendProfileClient({
    required String baseUrl,
    http.Client? client,
  })  : _baseUri = Uri.parse(baseUrl.trim().replaceFirst(RegExp(r'/$'), '')),
        _client = client ?? http.Client();

  final Uri _baseUri;
  final http.Client _client;

  Future<Map<String, dynamic>> loadCurrentUserProfile({
    required String idToken,
  }) async {
    final http.Response response = await _client.get(
      _uri('/users/me'),
      headers: <String, String>{
        'Authorization': 'Bearer $idToken',
        'Accept': 'application/json',
      },
    );
    return _decodeObjectResponse(response);
  }

  Future<Map<String, dynamic>> upsertCurrentUserProfile({
    required String idToken,
    required Map<String, dynamic> payload,
  }) async {
    final http.Response response = await _client.put(
      _uri('/users/me'),
      headers: <String, String>{
        'Authorization': 'Bearer $idToken',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );
    return _decodeObjectResponse(response);
  }

  void close() {
    _client.close();
  }

  Uri _uri(String path) {
    final String normalizedPath =
        path.startsWith('/') ? path.substring(1) : path;
    return _baseUri.resolve(normalizedPath);
  }

  Map<String, dynamic> _decodeObjectResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BackendProfileClientException(
        'Backend request failed (${response.statusCode}): ${response.body}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw BackendProfileClientException(
      'Backend returned an unexpected payload: ${response.body}',
    );
  }
}

class BackendProfileClientException implements Exception {
  BackendProfileClientException(this.message);

  final String message;

  @override
  String toString() => message;
}
