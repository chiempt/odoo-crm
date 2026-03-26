import 'package:flutter/foundation.dart';

import 'mobile_backend_adapter.dart';

class ApiService {
  final MobileBackendAdapter _backendAdapter = MobileBackendAdapter();

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Callback to handle session expiration globally
  VoidCallback? get onSessionExpired => _backendAdapter.onSessionExpired;
  set onSessionExpired(VoidCallback? callback) {
    _backendAdapter.onSessionExpired = callback;
  }

  void updateConfig(String baseUrl, String? sessionId) {
    _backendAdapter.updateConfig(baseUrl, sessionId);
  }

  // Simplified Odoo RPC call
  Future<dynamic> call(
    String path, {
    required String method,
    required Map<String, dynamic> params,
  }) async {
    final data = await _backendAdapter.call(
      path: path,
      method: method,
      params: params,
    );
    if (data['error'] != null) {
      final error = data['error'];
      final String errorMessage = error['message'] ?? error.toString();

      // Detect Odoo Session Expired
      if (error['code'] == 100 ||
          errorMessage.contains('Session expired') ||
          (error['data'] != null &&
              error['data']['name'] == 'odoo.http.SessionExpiredException')) {
        debugPrint('ApiService: Session expired detected!');
        _backendAdapter.onSessionExpired?.call();
      }

      throw Exception(errorMessage);
    }
    return data['result'];
  }
}
