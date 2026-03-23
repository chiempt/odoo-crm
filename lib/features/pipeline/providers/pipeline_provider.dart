import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../models/crm_lead.dart';

class PipelineProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<CrmLead> _leads = [];
  bool _isLoading = false;
  String? _error;

  List<CrmLead> get leads => _leads;
  bool get isLoading => _isLoading;
  String? get error => _error;

  PipelineProvider();

  void updateAuth(String token, String serverUrl) {
    // Current approach triggers fetch on auth status change
    if (token.isNotEmpty && _leads.isEmpty) {
      fetchLeads();
    }
  }

  Future<void> fetchLeads() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.call(
        '/web/dataset/call_kw',
        method: 'call',
        params: {
          "model": "crm.lead",
          "method": "search_read",
          "args": [
            [
              ["type", "=", "opportunity"],
            ],
          ],
          "kwargs": {
            "fields": [
              "id",
              "name",
              "partner_id",
              "email_from",
              "phone",
              "expected_revenue",
              "probability",
              "stage_id",
              "user_id",
            ],
            "limit": 50,
            "order": "create_date desc",
          },
        },
      );

      List<dynamic> records = [];
      if (result is List) {
        records = result;
      } else if (result is Map && result['records'] != null) {
        records = result['records'] as List;
      }

      if (records.isNotEmpty) {
        _leads = records
            .map((e) => CrmLead.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      _error = 'Exception: $e';
    }

    _isLoading = false;
    notifyListeners();
  }
}
