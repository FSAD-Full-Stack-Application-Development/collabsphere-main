import 'dart:convert';
import 'package:collab_sphere/store/token.dart';
import 'package:http/http.dart' as http;
import 'dart:developer';

/// Base API service to handle common HTTP logic, headers, and JSON parsing.
abstract class BaseApiService {
  final String baseUrl;
  BaseApiService({required this.baseUrl});

  /// Get auth token (if any)
  Future<String?> getToken() async {
    return await tokenStore.getToken();
  }

  /// Build headers for requests (optionally with auth)
  Future<Map<String, String>> buildHeaders({bool auth = true}) async {
    final token = await getToken() ?? '';
    return {
      'Content-Type': 'application/json',
      if (auth && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Perform a GET request
  Future<http.Response> get(
    String path, {
    Map<String, String>? params,
    bool auth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: params);
    final headers = await buildHeaders(auth: auth);
    try {
      final response = await http.get(uri, headers: headers);
      log('[GET] $uri => ${response.statusCode}\n${response.body}');
      return response;
    } catch (e, stack) {
      log('[GET] $uri => ERROR: $e\n$stack');
      return http.Response('Error: $e', 500);
    }
  }

  /// Perform a POST request
  Future<http.Response> post(
    String path, {
    Object? body,
    bool auth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await buildHeaders(auth: auth);
    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      log('[POST] $uri => ${response.statusCode}\n${response.body}');
      return response;
    } catch (e, stack) {
      log('[POST] $uri => ERROR: $e\n$stack');
      return http.Response('Error: $e', 500);
    }
  }

  /// Perform a PUT request
  Future<http.Response> put(
    String path, {
    Object? body,
    bool auth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await buildHeaders(auth: auth);
    try {
      final response = await http.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      log('[PUT] $uri => ${response.statusCode}\n${response.body}');
      return response;
    } catch (e, stack) {
      log('[PUT] $uri => ERROR: $e\n$stack');
      return http.Response('Error: $e', 500);
    }
  }

  /// Perform a PATCH request
  Future<http.Response> patch(
    String path, {
    Object? body,
    bool auth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await buildHeaders(auth: auth);
    try {
      final response = await http.patch(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      // log('[PATCH] $uri => ${response.statusCode}\n${response.body}');
      return response;
    } catch (e, stack) {
      log('[PATCH] $uri => ERROR: $e\n$stack');
      return http.Response('Error: $e', 500);
    }
  }

  /// Perform a DELETE request
  Future<http.Response> delete(
    String path, {
    Object? body,
    bool auth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await buildHeaders(auth: auth);
    try {
      final response = await http.delete(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      // log('[DELETE] $uri => ${response.statusCode}\n${response.body}');
      return response;
    } catch (e, stack) {
      log('[DELETE] $uri => ERROR: $e\n$stack');
      return http.Response('Error: $e', 500);
    }
  }

  /// Parse JSON response body safely
  dynamic parseJson(http.Response response) {
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return null;
    }
  }
}
