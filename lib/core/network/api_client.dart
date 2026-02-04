// ─────────────────────────────────────────────────────────────────────────────
// lib/core/network/api_client.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_endpoints.dart';
import 'network_exceptions.dart';

class ApiClient {
  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _xOckKey = 'x_ock_key';

  // ───── Token Management ─────
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = token.trim().toLowerCase().startsWith('bearer ')
        ? token.trim().substring(7).trim()
        : token.trim();
    await prefs.setString(_tokenKey, normalized);
  }

  Future<void> saveRefreshToken(String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  Future<void> saveXOckKey(String xOckKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_xOckKey, xOckKey);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<String?> getXOckKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_xOckKey);
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_xOckKey);
  }

  // ───── Headers Builder ─────
  Future<Map<String, String>> _getHeaders({
    bool requiresAuth = true,
    bool requiresXOck = false,
    bool isMultipart = false,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (!isMultipart) {
      headers['Content-Type'] = 'application/json';
    }

    if (requiresAuth) {
      final token = await getToken();
      if (token != null) {
        final value = token.trim().toLowerCase().startsWith('bearer ')
            ? token.trim()
            : 'Bearer ${token.trim()}';
        headers['Authorization'] = value;
      }
    }

    if (requiresXOck) {
      final xOck = await getXOckKey();
      if (xOck != null) {
        headers['X-Ock'] = xOck;
      }
    }

    return headers;
  }

  // ───── GET Request ─────
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    bool requiresAuth = true,
    bool requiresXOck = false,
  }) async {
    try {
      final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint')
          .replace(queryParameters: queryParams);
      final headers = await _getHeaders(
        requiresAuth: requiresAuth,
        requiresXOck: requiresXOck,
      );

      final response = await http.get(uri, headers: headers);
      return _handleResponse(response);
    } on SocketException {
      throw NetworkException('No internet connection');
    } catch (e) {
      throw NetworkException('Request failed: $e');
    }
  }

  // ───── POST Request (JSON) ─────
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
    bool requiresXOck = false,
  }) async {
    try {
      final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
      final headers = await _getHeaders(
        requiresAuth: requiresAuth,
        requiresXOck: requiresXOck,
      );

      final response = await http.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException('No internet connection');
    } catch (e) {
      throw NetworkException('Request failed: $e');
    }
  }

  // ───── POST Request (Form Data) ─────
  Future<Map<String, dynamic>> postFormData(
    String endpoint, {
    required Map<String, dynamic> fields,
    Map<String, File>? files,
    bool requiresAuth = true,
    bool requiresXOck = false,
  }) async {
    try {
      final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      final headers = await _getHeaders(
        requiresAuth: requiresAuth,
        requiresXOck: requiresXOck,
        isMultipart: true,
      );
      request.headers.addAll(headers);

      // Add fields
      fields.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Add files
      if (files != null) {
        for (var entry in files.entries) {
          final file = entry.value;
          request.files.add(
            await http.MultipartFile.fromPath(entry.key, file.path),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException('No internet connection');
    } catch (e) {
      throw NetworkException('Request failed: $e');
    }
  }

  // ───── PUT Request ─────
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
    bool requiresXOck = false,
  }) async {
    try {
      final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
      final headers = await _getHeaders(
        requiresAuth: requiresAuth,
        requiresXOck: requiresXOck,
      );

      final response = await http.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException('No internet connection');
    } catch (e) {
      throw NetworkException('Request failed: $e');
    }
  }

  // ───── DELETE Request ─────
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
    bool requiresXOck = false,
  }) async {
    try {
      final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
      final headers = await _getHeaders(
        requiresAuth: requiresAuth,
        requiresXOck: requiresXOck,
      );

      final response = await http.delete(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException('No internet connection');
    } catch (e) {
      throw NetworkException('Request failed: $e');
    }
  }

  // ───── Response Handler ─────
  Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    // Try to parse JSON response. Support both Map and List payloads.
    Map<String, dynamic> jsonResponse;
    try {
      final decoded = body.isNotEmpty ? jsonDecode(body) : null;
      if (decoded is Map<String, dynamic>) {
        jsonResponse = decoded;
      } else if (decoded is List) {
        // Wrap array responses into a Map under 'data' for uniform handling
        jsonResponse = {'data': decoded};
      } else if (decoded == null) {
        throw const FormatException('Empty response');
      } else {
        throw const FormatException('Unsupported JSON root type');
      }
    } catch (e) {
      // Fallback: attempt to coerce single-quoted JSON to valid JSON
      try {
        final fixed = body.replaceAll("'", '"');
        final decoded = jsonDecode(fixed);
        if (decoded is Map<String, dynamic>) {
          jsonResponse = decoded;
        } else if (decoded is List) {
          jsonResponse = {'data': decoded};
        } else {
          final snippet = body.length > 160 ? body.substring(0, 160) + '…' : body;
          throw NetworkException('Invalid response format (HTTP $statusCode). Body: $snippet');
        }
      } catch (_) {
        final snippet = body.length > 160 ? body.substring(0, 160) + '…' : body;
        throw NetworkException('Invalid response format (HTTP $statusCode). Body: $snippet');
      }
    }

    // Handle different status codes
    if (statusCode >= 200 && statusCode < 300) {
      return jsonResponse;
    } else if (statusCode == 401) {
      throw UnauthorizedException(
        jsonResponse['message'] ?? 'Unauthorized - Invalid token',
      );
    } else if (statusCode == 422) {
      Map<String, dynamic>? errors;
      final dataNode = jsonResponse['data'];
      if (dataNode is Map<String, dynamic>) {
        final maybeErrors = dataNode['errors'];
        if (maybeErrors is Map<String, dynamic>) {
          errors = maybeErrors;
        }
      }

      String errorMessage = 'Validation error';
      if (errors != null && errors.isNotEmpty) {
        final firstVal = errors.values.first;
        if (firstVal is List && firstVal.isNotEmpty) {
          errorMessage = firstVal.first.toString();
        } else if (firstVal is String) {
          errorMessage = firstVal;
        } else {
          errorMessage = firstVal.toString();
        }
      } else {
        final msg = jsonResponse['message'];
        if (msg is String) {
          errorMessage = msg;
        } else if (msg is Map) {
          // Some backends return message as an object
          errorMessage = msg.values.isNotEmpty ? msg.values.first.toString() : 'Validation error';
        }
      }

      throw ValidationException(errorMessage, errors);
    } else if (statusCode == 404) {
      throw NotFoundException(
        jsonResponse['message'] ?? 'Resource not found',
      );
    } else if (statusCode >= 500) {
      throw ServerException(
        jsonResponse['message'] ?? 'Server error occurred',
      );
    } else {
      throw NetworkException(
        jsonResponse['message'] ?? 'Request failed with status: $statusCode',
      );
    }
  }

  // ───── Refresh Token ─────
  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;

      final response = await post(
        ApiEndpoints.refreshToken,
        requiresAuth: true,
      );

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        await saveToken(data['access_token']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
