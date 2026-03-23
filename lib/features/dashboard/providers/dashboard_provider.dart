import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../models/activity_model.dart';

class DashboardProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  int? _uid;

  List<CrmActivity> _upcomingActivities = [];
  bool _isLoadingActivities = false;
  String? _activitiesError;

  List<CrmActivity> get upcomingActivities => _upcomingActivities;
  bool get isLoadingActivities => _isLoadingActivities;
  String? get activitiesError => _activitiesError;

  void updateAuth(String token, String serverUrl, int? uid) {
    _uid = uid;
    if (_uid != null && _upcomingActivities.isEmpty) {
      fetchUpcomingActivities();
      fetchMetrics();
    }
  }

  double _totalRevenue = 0.0;
  int _newLeadsCount = 0;
  String _selectedPeriod = 'This Month';

  double get totalRevenue => _totalRevenue;
  int get newLeadsCount => _newLeadsCount;
  String get selectedPeriod => _selectedPeriod;

  void setPeriod(String period) {
    if (_selectedPeriod != period) {
      _selectedPeriod = period;
      fetchMetrics();
    }
  }

  Future<void> fetchUpcomingActivities({int limit = 5}) async {
    if (_uid == null) {
      debugPrint('DashboardProvider: Cannot fetch activities, _uid is null');
      return;
    }

    _isLoadingActivities = true;
    _activitiesError = null;
    notifyListeners();

    try {
      debugPrint('DashboardProvider: Fetching upcoming activities for uid: $_uid, limit: $limit');
      final result = await _apiService.call(
        '/web/dataset/call_kw',
        method: 'call',
        params: {
          "model": "mail.activity",
          "method": "search_read",
          "args": [
            [
              ["user_id", "=", _uid],
            ],
          ],
          "kwargs": {
            "fields": [
              "id",
              "res_id",
              "res_name",
              "res_model",
              "activity_type_id",
              "summary",
              "date_deadline",
              "state",
            ],
            "limit": limit,
            "order": "date_deadline asc",
          },
        },
      );

      debugPrint('DashboardProvider: Fetch result: $result');

      List<dynamic> records = [];
      if (result is List) {
        records = result;
      } else if (result is Map && result['records'] != null) {
        records = result['records'] as List;
      }

      _upcomingActivities = records
          .map((e) => CrmActivity.fromOdooJson(e as Map<String, dynamic>))
          .toList();
      debugPrint('DashboardProvider: Parsed ${_upcomingActivities.length} activities');
    } catch (e) {
      debugPrint('DashboardProvider: Error fetching activities: $e');
      _activitiesError = 'Exception: $e';
    } finally {
      _isLoadingActivities = false;
      notifyListeners();
    }
  }

  Future<void> fetchMetrics() async {
    if (_uid == null) return;
    try {
      final DateTime now = DateTime.now();
      DateTime? startDate;
      DateTime? endDate;

      switch (_selectedPeriod) {
        case 'Today':
          startDate = DateTime(now.year, now.month, now.day);
          endDate = startDate.add(const Duration(days: 1));
          break;
        case 'This Week':
          startDate = now.subtract(Duration(days: now.weekday - 1));
          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          endDate = startDate.add(const Duration(days: 7));
          break;
        case 'This Month':
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month + 1, 1);
          break;
        case 'This Quarter':
          int currentQuarter = (now.month - 1) ~/ 3;
          startDate = DateTime(now.year, currentQuarter * 3 + 1, 1);
          endDate = DateTime(now.year, currentQuarter * 3 + 4, 1);
          break;
        case 'This Year':
          startDate = DateTime(now.year, 1, 1);
          endDate = DateTime(now.year + 1, 1, 1);
          break;
        case 'All Time':
        default:
          break;
      }

      final List<dynamic> dateDomain = [];
      if (startDate != null && endDate != null) {
        final startStr = startDate.toUtc().toString().substring(0, 19);
        final endStr = endDate.toUtc().toString().substring(0, 19);
        dateDomain.addAll([
          ["create_date", ">=", startStr],
          ["create_date", "<", endStr],
        ]);
      }

      // 1. Fetch total expected revenue for the user
      final revenueResult = await _apiService.call(
        '/web/dataset/call_kw',
        method: 'call',
        params: {
          "model": "crm.lead",
          "method": "read_group",
          "args": [
            [
              ["user_id", "=", _uid],
              ["type", "=", "opportunity"],
              ...dateDomain,
            ],
            ["expected_revenue:sum"],
            [],
          ],
          "kwargs": {},
        },
      );

      if (revenueResult is List && revenueResult.isNotEmpty) {
        final Map<String, dynamic> agg = revenueResult.first;
        _totalRevenue = (agg['expected_revenue'] is num)
            ? (agg['expected_revenue'] as num).toDouble()
            : 0.0;
      }

      // 2. Fetch new leads count (e.g. probability < 100 and no specific stage, or maybe just total count)
      // I'll fetch total open leads count for the user for demonstration
      final countResult = await _apiService.call(
        '/web/dataset/call_kw',
        method: 'call',
        params: {
          "model": "crm.lead",
          "method": "search_count",
          "args": [
            [
              ["user_id", "=", _uid],
              ["type", "=", "opportunity"],
              ["probability", "<", 100],
              ...dateDomain,
            ],
          ],
          "kwargs": {},
        },
      );

      _newLeadsCount = countResult is int ? countResult : 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching dashboard metrics: $e');
    }
  }
}
