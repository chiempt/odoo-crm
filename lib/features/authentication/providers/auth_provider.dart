import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/auth_service.dart';
import '../../../core/services/api_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  AuthStatus _status = AuthStatus.initial;
  String? _token;
  String? _serverUrl;
  String? _database;
  int? _uid;
  String? _name;
  String? _username;

  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  String? get token => _token;
  String? get serverUrl => _serverUrl;
  String? get database => _database;
  int? get uid => _uid;
  String? get name => _name;
  String? get username => _username;

  AuthProvider() {
    _checkAuth();
    // Set global session expired handler
    ApiService().onSessionExpired = () {
      if (isAuthenticated) {
        logout();
      }
    };
  }

  Future<void> _checkAuth() async {
    _status = AuthStatus.loading;
    notifyListeners();

    final token = await _authService.getToken();
    _serverUrl = await _authService.getServerUrl();
    _database = await _authService.getDatabase();
    _uid = await _authService.getUid();
    _name = await _authService.getName();
    _username = await _authService.getUsername();

    if (token != null) {
      _token = token;
      _status = AuthStatus.authenticated;
      ApiService().updateConfig(_serverUrl ?? '', _token);
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(
    String email,
    String password,
    String url,
    String db,
  ) async {
    String formattedUrl = url.trim();
    if (!formattedUrl.startsWith('http://') &&
        !formattedUrl.startsWith('https://')) {
      formattedUrl = 'https://$formattedUrl';
    }

    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final uri = Uri.parse('$formattedUrl/web/session/authenticate');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "jsonrpc": "2.0",
          "method": "call",
          "params": {"db": db, "login": email, "password": password},
          "id": DateTime.now().millisecondsSinceEpoch,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] != null && data['result']['uid'] != null) {
          String? sessionId;

          // Priority 1: Get from JSON Body (Most reliable way on WEB)
          if (data['result']['session_id'] != null) {
            sessionId = data['result']['session_id'];
            debugPrint('AuthProvider: Got session_id from Body: $sessionId');
          }

          // Priority 2: Extract from Header (For Mobile/Desktop)
          if (sessionId == null) {
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
                sessionId = match.group(1);
                debugPrint(
                  'AuthProvider: Got session_id from Header: $sessionId',
                );
              }
            }
          }

          // Fallback cuối cùng
          sessionId ??= 'odoo_session_cookie_managed';

          final int resultUid = data['result']['uid'];
          final String? resultName = data['result']['name'];
          final String? resultUsername = data['result']['username'];

          await _authService.saveAuthData(
            token: sessionId,
            url: formattedUrl,
            database: db,
            uid: resultUid,
            name: resultName,
            username: resultUsername,
          );

          _token = sessionId;
          _serverUrl = formattedUrl;
          _database = db;
          _uid = resultUid;
          _name = resultName;
          _username = resultUsername;
          _status = AuthStatus.authenticated;
          ApiService().updateConfig(_serverUrl ?? '', _token);
          notifyListeners();
          return true;
        } else if (data['error'] != null) {
          debugPrint('Odoo API Error: ${data['error']}');
        }
      } else {
        debugPrint('HTTP Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Login exception: $e');
    }

    _status = AuthStatus.unauthenticated;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _authService.removeAuthData();
    _token = null;
    _uid = null;
    _name = null;
    _username = null;
    _status = AuthStatus.unauthenticated;
    ApiService().updateConfig('', null);
    notifyListeners();
  }
}
