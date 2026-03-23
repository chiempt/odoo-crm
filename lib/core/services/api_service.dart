import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  String? _baseUrl;
  String? _sessionId;

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Callback to handle session expiration globally
  VoidCallback? onSessionExpired;

  void updateConfig(String baseUrl, String? sessionId) {
    // Remove trailing slash if exists to ensure consistent URL construction
    _baseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    _sessionId = sessionId;
  }

  Map<String, String> get _headers {
    final Map<String, String> headers = {'Content-Type': 'application/json'};
    if (_sessionId != null && _sessionId!.isNotEmpty) {
      headers['Cookie'] = 'session_id=$_sessionId';
      // Some Odoo configurations or versions might also look for this header
      headers['X-Openerp-Session-Id'] = _sessionId!;
    }
    return headers;
  }

  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    if (_baseUrl == null || _baseUrl!.isEmpty) {
      throw Exception('Base URL not configured');
    }

    // Ensure path starts with a slash
    final String cleanPath = path.startsWith('/') ? path : '/$path';
    final url = Uri.parse('$_baseUrl$cleanPath');

    debugPrint('ApiService POST: $url');
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode(body),
    );

    // Update session_id if Odoo sends a new one in the Header (Mobile only)
    final String allCookies = response.headers.entries
        .where((e) => e.key.toLowerCase() == 'set-cookie')
        .map((e) => e.value)
        .join('; ');

    if (allCookies.isNotEmpty) {
      final match = RegExp(
        r'session_id=([^; ]+)',
        caseSensitive: false,
      ).firstMatch(allCookies);
      if (match != null) {
        final newSessionId = match.group(1);
        if (newSessionId != null && newSessionId != _sessionId) {
          debugPrint('ApiService: Updated new session_id: $newSessionId');
          _sessionId = newSessionId;
        }
      }
    }

    return response;
  }

  // Simplified Odoo RPC call
  Future<dynamic> call(
    String path, {
    required String method,
    required Map<String, dynamic> params,
  }) async {
    final response = await post(path, {
      "jsonrpc": "2.0",
      "method": method,
      "params": params,
      "id": DateTime.now().millisecondsSinceEpoch,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['error'] != null) {
        final error = data['error'];
        final String errorMessage = error['message'] ?? error.toString();

        // Detect Odoo Session Expired
        if (error['code'] == 100 ||
            errorMessage.contains('Session expired') ||
            (error['data'] != null &&
                error['data']['name'] == 'odoo.http.SessionExpiredException')) {
          debugPrint('ApiService: Session expired detected!');
          onSessionExpired?.call();
        }

        throw Exception(errorMessage);
      }
      return data['result'];
    } else {
      throw Exception('HTTP Error: ${response.statusCode}');
    }
  }
}
