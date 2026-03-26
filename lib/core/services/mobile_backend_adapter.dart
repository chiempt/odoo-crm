import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

typedef SleepFn = Future<void> Function(Duration duration);

class BackendAuthResult {
  final int uid;
  final String? sessionId;
  final String? name;
  final String? username;

  const BackendAuthResult({
    required this.uid,
    required this.sessionId,
    this.name,
    this.username,
  });
}

class MobileBackendAdapter {
  static const Duration _minRequestSpacing = Duration(milliseconds: 120);
  static const int _maxReadRetries = 2;
  static const Set<int> _retryableStatusCodes = {408, 429, 500, 502, 503, 504};
  static const Set<String> _allowedPaths = {
    '/web/session/authenticate',
    '/web/session/get_session_info',
    '/web/database/list',
    '/web/dataset/call_kw',
  };
  static const Set<String> _mutatingRpcMethods = {
    'create',
    'write',
    'unlink',
    'message_post',
    'message_subscribe',
    'message_unsubscribe',
    'action_set_won',
    'action_set_lost',
    'convert_opportunity',
  };

  final http.Client _httpClient;
  final SleepFn _sleep;
  DateTime? _lastRequestAt;

  String? _baseUrl;
  String? _sessionId;
  VoidCallback? onSessionExpired;

  static final MobileBackendAdapter _instance =
      MobileBackendAdapter._internal();

  factory MobileBackendAdapter() => _instance;

  MobileBackendAdapter._internal({http.Client? httpClient, SleepFn? sleep})
    : _httpClient = httpClient ?? http.Client(),
      _sleep = sleep ?? Future<void>.delayed;

  @visibleForTesting
  factory MobileBackendAdapter.test({http.Client? httpClient, SleepFn? sleep}) {
    return MobileBackendAdapter._internal(httpClient: httpClient, sleep: sleep);
  }

  String? get sessionId => _sessionId;

  void updateConfig(String baseUrl, String? sessionId) {
    _baseUrl = _normalizeUrl(baseUrl);
    _sessionId = sessionId;
  }

  Future<List<String>> listDatabases(String rawBaseUrl) async {
    _baseUrl = _normalizeUrl(rawBaseUrl);
    final payload = await _requestJsonRpc(
      '/web/database/list',
      body: {
        'jsonrpc': '2.0',
        'method': 'call',
        'params': <String, dynamic>{},
        'id': DateTime.now().millisecondsSinceEpoch,
      },
      idempotent: true,
      includeSession: false,
    );

    final dynamic result = payload['result'];
    if (result is List) {
      return result.map((e) => e.toString()).toList();
    }
    return const [];
  }

  Future<BackendAuthResult> authenticate({
    required String rawBaseUrl,
    required String db,
    required String login,
    required String password,
  }) async {
    _baseUrl = _normalizeUrl(rawBaseUrl);
    final payload = await _requestJsonRpc(
      '/web/session/authenticate',
      body: {
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {'db': db, 'login': login, 'password': password},
        'id': DateTime.now().millisecondsSinceEpoch,
      },
      idempotent: false,
      includeSession: false,
    );

    final dynamic result = payload['result'];
    if (result is! Map<String, dynamic> || result['uid'] == null) {
      throw Exception('Authentication failed');
    }

    final bodySessionId = result['session_id']?.toString();
    if (bodySessionId != null && bodySessionId.isNotEmpty) {
      _sessionId = bodySessionId;
    } else {
      _sessionId ??= 'odoo_session_cookie_managed';
    }

    return BackendAuthResult(
      uid: result['uid'] as int,
      sessionId: _sessionId,
      name: result['name']?.toString(),
      username: result['username']?.toString(),
    );
  }

  Future<Map<String, dynamic>> call({
    required String path,
    required String method,
    required Map<String, dynamic> params,
  }) async {
    final rpcMethod = params['method']?.toString().toLowerCase();
    final idempotent = !_mutatingRpcMethods.contains(rpcMethod);

    return _requestJsonRpc(
      path,
      body: {
        'jsonrpc': '2.0',
        'method': method,
        'params': params,
        'id': DateTime.now().millisecondsSinceEpoch,
      },
      idempotent: idempotent,
      includeSession: true,
    );
  }

  Future<bool> pingSession() async {
    final payload = await _requestJsonRpc(
      '/web/session/get_session_info',
      body: {
        'jsonrpc': '2.0',
        'method': 'call',
        'params': <String, dynamic>{},
        'id': DateTime.now().millisecondsSinceEpoch,
      },
      idempotent: true,
      includeSession: true,
    );

    final dynamic result = payload['result'];
    if (result is! Map<String, dynamic>) {
      return false;
    }
    final uid = result['uid'];
    if (uid is int) {
      return uid > 0;
    }
    if (uid is String) {
      return int.tryParse(uid) != null && int.parse(uid) > 0;
    }
    return false;
  }

  Future<Map<String, dynamic>> _requestJsonRpc(
    String path, {
    required Map<String, dynamic> body,
    required bool idempotent,
    required bool includeSession,
  }) async {
    if (!_allowedPaths.contains(path)) {
      throw StateError('Path is not allowed by mobile policy: $path');
    }
    final base = _baseUrl;
    if (base == null || base.isEmpty) {
      throw Exception('Base URL not configured');
    }

    final cleanPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$base$cleanPath');
    final maxAttempts = idempotent ? _maxReadRetries + 1 : 1;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      await _respectRateLimit();

      try {
        final response = await _httpClient.post(
          uri,
          headers: _buildHeaders(includeSession: includeSession),
          body: jsonEncode(body),
        );
        _captureSession(response);

        final shouldRetry =
            idempotent &&
            attempt < maxAttempts &&
            _retryableStatusCodes.contains(response.statusCode);
        if (shouldRetry) {
          final wait = _retryDelay(attempt, response.headers['retry-after']);
          await _sleep(wait);
          continue;
        }

        if (response.statusCode != 200) {
          throw Exception('HTTP Error: ${response.statusCode}');
        }

        return jsonDecode(response.body) as Map<String, dynamic>;
      } on SocketException catch (_) {
        if (!idempotent || attempt >= maxAttempts) rethrow;
        await _sleep(_retryDelay(attempt, null));
      } on TimeoutException catch (_) {
        if (!idempotent || attempt >= maxAttempts) rethrow;
        await _sleep(_retryDelay(attempt, null));
      }
    }

    throw Exception('Request failed after retries');
  }

  Map<String, String> _buildHeaders({required bool includeSession}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (includeSession && _sessionId != null && _sessionId!.isNotEmpty) {
      headers['Cookie'] = 'session_id=$_sessionId';
      headers['X-Openerp-Session-Id'] = _sessionId!;
    }
    return headers;
  }

  void _captureSession(http.Response response) {
    final String allCookies = response.headers.entries
        .where((entry) => entry.key.toLowerCase() == 'set-cookie')
        .map((entry) => entry.value)
        .join('; ');

    if (allCookies.isEmpty) return;
    final match = RegExp(
      r'session_id=([^; ]+)',
      caseSensitive: false,
    ).firstMatch(allCookies);
    final sessionId = match?.group(1);
    if (sessionId != null && sessionId.isNotEmpty) {
      _sessionId = sessionId;
    }
  }

  Future<void> _respectRateLimit() async {
    final now = DateTime.now();
    if (_lastRequestAt != null) {
      final elapsed = now.difference(_lastRequestAt!);
      if (elapsed < _minRequestSpacing) {
        await _sleep(_minRequestSpacing - elapsed);
      }
    }
    _lastRequestAt = DateTime.now();
  }

  Duration _retryDelay(int attempt, String? retryAfterHeader) {
    final retryAfter = int.tryParse(retryAfterHeader ?? '');
    if (retryAfter != null && retryAfter >= 0) {
      return Duration(seconds: retryAfter);
    }
    final exponent = attempt < 1 ? 1 : attempt;
    return Duration(milliseconds: 250 * exponent);
  }

  String _normalizeUrl(String input) {
    final normalized = AppConfig.normalizeServerUrl(input);
    return normalized.endsWith('/')
        ? normalized.substring(0, normalized.length - 1)
        : normalized;
  }
}
