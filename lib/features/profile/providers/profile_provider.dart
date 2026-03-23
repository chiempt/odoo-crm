import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

class ProfileProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  int? _uid;

  bool _isLoading = false;
  String? _error;

  String _phone = '';
  String _tz = '';
  String _lang = '';
  int _dealsWon = 0;
  int _activeLeads = 0;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get phone => _phone;
  String get tz => _tz;
  String get lang => _lang;
  int get dealsWon => _dealsWon;
  int get activeLeads => _activeLeads;

  void updateAuth(int? uid) {
    if (_uid != uid) {
      _uid = uid;
      if (_uid != null) {
        fetchProfileData();
      }
    }
  }

  Future<void> fetchProfileData() async {
    if (_uid == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Fetch user data (phone, standard language, tz) from res.users
      final userResult = await _apiService.call(
        '/web/dataset/call_kw/res.users/search_read',
        method: 'call',
        params: {
          "model": "res.users",
          "method": "search_read",
          "args": [
            [
              ["id", "=", _uid],
            ],
          ],
          "kwargs": {
            "fields": ["phone", "tz", "lang"],
            "limit": 1,
          },
        },
      );

      if (userResult is List && userResult.isNotEmpty) {
        final data = userResult.first;
        _phone = data['phone'] is String ? data['phone'] : '';
        _tz = data['tz'] is String ? data['tz'] : 'UTC';
        _lang = data['lang'] is String ? data['lang'] : 'en_US';
      }

      // 2. Fetch Deals Won (type=opportunity, using a generic check if they have probability 100 or stage)
      final wonCount = await _apiService.call(
        '/web/dataset/call_kw/crm.lead/search_count',
        method: 'call',
        params: {
          "model": "crm.lead",
          "method": "search_count",
          "args": [
            [
              ["user_id", "=", _uid],
              ["probability", "=", 100],
            ],
          ],
          "kwargs": {},
        },
      );
      _dealsWon = wonCount is int ? wonCount : 0;

      // 3. Fetch Active Leads (type=opportunity, probability < 100)
      final activeCount = await _apiService.call(
        '/web/dataset/call_kw/crm.lead/search_count',
        method: 'call',
        params: {
          "model": "crm.lead",
          "method": "search_count",
          "args": [
            [
              ["user_id", "=", _uid],
              ["probability", "<", 100],
              ["probability", ">", 0],
            ],
          ],
          "kwargs": {},
        },
      );
      _activeLeads = activeCount is int ? activeCount : 0;
    } catch (e) {
      _error = e.toString();
      debugPrint('Profile error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
