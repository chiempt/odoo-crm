import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/mobile_backend_adapter.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final MobileBackendAdapter _backendAdapter = MobileBackendAdapter();
  AuthStatus _status = AuthStatus.initial;
  String? _token;
  String? _serverUrl;
  String? _database;
  int? _uid;
  String? _name;
  String? _username;
  Timer? _sessionMonitorTimer;
  bool _sessionRecoveryInProgress = false;
  String? _pendingAuthMessage;

  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  String? get token => _token;
  String? get serverUrl => _serverUrl;
  String? get database => _database;
  int? get uid => _uid;
  String? get name => _name;
  String? get username => _username;
  String? consumePendingAuthMessage() {
    final message = _pendingAuthMessage;
    _pendingAuthMessage = null;
    return message;
  }

  AuthProvider() {
    _checkAuth();
    // Set global session expired handler
    ApiService().onSessionExpired = () {
      if (isAuthenticated) {
        unawaited(_handleSessionExpired());
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
      _startSessionMonitor();
      unawaited(_validateSessionAfterRestore());
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(
    String email,
    String password,
    String url,
    String db, {
    bool rememberSession = false,
  }) async {
    final formattedUrl = AppConfig.normalizeServerUrl(url);

    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final authResult = await _backendAdapter.authenticate(
        rawBaseUrl: formattedUrl,
        db: db,
        login: email,
        password: password,
      );

      await _authService.saveAuthData(
        token: authResult.sessionId ?? 'odoo_session_cookie_managed',
        url: formattedUrl,
        database: db,
        uid: authResult.uid,
        name: authResult.name,
        username: authResult.username,
        password: password,
        rememberSession: rememberSession,
      );

      _token = authResult.sessionId ?? 'odoo_session_cookie_managed';
      _serverUrl = formattedUrl;
      _database = db;
      _uid = authResult.uid;
      _name = authResult.name;
      _username = authResult.username;
      _status = AuthStatus.authenticated;
      ApiService().updateConfig(_serverUrl ?? '', _token);
      _startSessionMonitor();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Login exception: $e');
    }

    _status = AuthStatus.unauthenticated;
    notifyListeners();
    return false;
  }

  Future<void> logout({String? reason}) async {
    _stopSessionMonitor();
    await _authService.removeAuthData();
    _token = null;
    _uid = null;
    _name = null;
    _username = null;
    _sessionRecoveryInProgress = false;
    if (reason != null && reason.isNotEmpty) {
      _pendingAuthMessage = reason;
    }
    _status = AuthStatus.unauthenticated;
    ApiService().updateConfig('', null);
    notifyListeners();
  }

  Future<void> _validateSessionAfterRestore() async {
    if (!isAuthenticated) return;
    final canUseSavedSession = await _checkSessionStillValid();
    if (canUseSavedSession) return;
    await _handleSessionExpired();
  }

  void _startSessionMonitor() {
    _sessionMonitorTimer?.cancel();
    _sessionMonitorTimer = Timer.periodic(const Duration(minutes: 4), (_) {
      if (!isAuthenticated || _sessionRecoveryInProgress) {
        return;
      }
      unawaited(_proactiveSessionRefresh());
    });
  }

  void _stopSessionMonitor() {
    _sessionMonitorTimer?.cancel();
    _sessionMonitorTimer = null;
  }

  Future<void> _proactiveSessionRefresh() async {
    if (!isAuthenticated) return;
    final stillValid = await _checkSessionStillValid();
    if (stillValid) return;
    await _handleSessionExpired();
  }

  Future<bool> _checkSessionStillValid() async {
    try {
      return await _backendAdapter.pingSession();
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleSessionExpired() async {
    if (_sessionRecoveryInProgress || !isAuthenticated) {
      return;
    }
    _sessionRecoveryInProgress = true;
    final recovered = await _attemptSilentReauthentication();
    _sessionRecoveryInProgress = false;

    if (recovered) {
      notifyListeners();
      return;
    }

    await logout(
      reason: 'Your session has expired. Please sign in again to continue.',
    );
  }

  Future<bool> _attemptSilentReauthentication() async {
    final rememberSession = await _authService.getRememberSession();
    final savedPassword = await _authService.getSavedPassword();
    final login = _username;
    final url = _serverUrl;
    final db = _database;

    if (!rememberSession ||
        savedPassword == null ||
        savedPassword.isEmpty ||
        login == null ||
        login.isEmpty ||
        url == null ||
        url.isEmpty ||
        db == null ||
        db.isEmpty) {
      return false;
    }

    try {
      final authResult = await _backendAdapter.authenticate(
        rawBaseUrl: url,
        db: db,
        login: login,
        password: savedPassword,
      );
      _token = authResult.sessionId ?? _token;
      _uid = authResult.uid;
      _name = authResult.name ?? _name;
      _username = authResult.username ?? _username;

      await _authService.saveAuthData(
        token: _token ?? 'odoo_session_cookie_managed',
        url: url,
        database: db,
        uid: _uid,
        name: _name,
        username: _username,
        password: savedPassword,
        rememberSession: true,
      );

      _status = AuthStatus.authenticated;
      ApiService().updateConfig(url, _token);
      _startSessionMonitor();
      return true;
    } catch (e) {
      debugPrint('Silent session recovery failed: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _stopSessionMonitor();
    ApiService().onSessionExpired = null;
    super.dispose();
  }
}
