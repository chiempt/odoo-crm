import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../models/contact_model.dart';

class ContactProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<ContactModel> _contacts = [];
  bool _isLoading = false;
  String? _error;

  List<ContactModel> get contacts => _contacts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool _hasFetched = false;

  Future<void> fetchContacts({bool force = false}) async {
    if (_hasFetched && !force) return;

    _isLoading = true;
    _error = null;
    if (force) {
      _contacts.clear();
    }
    notifyListeners();

    try {
      final result = await _apiService.call(
        '/web/dataset/call_kw/res.partner/search_read',
        method: 'call',
        params: {
          "model": "res.partner",
          "method": "search_read",
          "args": [],
          "kwargs": {
            "domain": [
              ["active", "=", true],
            ],
            "fields": [
              "id",
              "name",
              "email",
              "phone",
              "mobile",
              "parent_id",
              "is_company",
            ],
            "limit": 50,
            "order": "id desc",
          },
        },
      );

      List<dynamic> records = [];
      if (result is List) {
        records = result;
      } else if (result is Map && result['records'] != null) {
        records = result['records'] as List;
      }

      _contacts = records
          .map((e) => ContactModel.fromOdooJson(e as Map<String, dynamic>))
          .toList();
      _hasFetched = true;
    } catch (e) {
      _error = 'Exception: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createContact({
    required String name,
    required bool isCompany,
    String? email,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final values = {
        "name": name,
        "is_company": isCompany,
        if (email != null && email.isNotEmpty) "email": email,
        if (phone != null && phone.isNotEmpty) "phone": phone,
      };

      final result = await _apiService.call(
        '/web/dataset/call_kw/res.partner/create',
        method: 'call',
        params: {
          "model": "res.partner",
          "method": "create",
          "args": [
            [values],
          ],
          "kwargs": {},
        },
      );

      if (result != null) {
        // success, refresh contacts
        await fetchContacts(force: true);
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Exception: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateContact({
    required int id,
    required String name,
    required bool isCompany,
    String? email,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final values = {
        "name": name,
        "is_company": isCompany,
        "email": email ?? '',
        "phone": phone ?? '',
      };

      final result = await _apiService.call(
        '/web/dataset/call_kw/res.partner/write',
        method: 'call',
        params: {
          "model": "res.partner",
          "method": "write",
          "args": [
            [id],
            values,
          ],
          "kwargs": {},
        },
      );

      if (result == true) {
        // success, refresh contacts
        await fetchContacts(force: true);
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Exception: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearData() {
    _contacts.clear();
    _hasFetched = false;
    notifyListeners();
  }
}
