import 'package:flutter/material.dart';
import '../../../core/services/odoo_crm_service.dart';
import '../models/deal_model.dart';

class DealProvider with ChangeNotifier {
  final OdooCrmService _crmService = OdooCrmService();

  List<Deal> _deals = [];
  bool _isLoading = false;
  String? _error;
  Map<String, List<Deal>> _dealsByStage = {};

  List<Deal> get deals => _deals;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, List<Deal>> get dealsByStage => _dealsByStage;

  /// Fetch all deals/opportunities from Odoo
  Future<void> fetchDeals({bool refresh = false}) async {
    if (_isLoading) return;
    
    if (refresh) {
      _deals = [];
      _dealsByStage = {};
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _crmService.fetchLeads(
        domain: [
          ['type', '=', 'opportunity'],
        ],
        limit: 100,
        order: 'date_deadline desc, expected_revenue desc',
      );

      _deals = result.map((json) => Deal.fromOdoo(json)).toList();
      _groupDealsByStage();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching deals: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch a single deal with full details including activities and history
  Future<Deal?> fetchDealDetails(int dealId) async {
    try {
      // Fetch lead details
      final leadData = await _crmService.fetchLeadById(dealId);
      if (leadData == null) return null;

      final deal = Deal.fromOdoo(leadData);

      // Fetch activities
      final activitiesData = await _crmService.fetchActivities(dealId);
      DealActivity? activity;
      if (activitiesData.isNotEmpty) {
        activity = DealActivity.fromOdooActivity(activitiesData.first);
      }

      // Fetch message history
      final messagesData = await _crmService.fetchMessages(dealId);
      final history = messagesData
          .map((json) => DealHistoryEntry.fromOdooMessage(json))
          .toList();

      return deal.copyWithDetails(
        activity: activity,
        history: history,
      );
    } catch (e) {
      debugPrint('Error fetching deal details: $e');
      return null;
    }
  }

  /// Create a new deal/opportunity
  Future<bool> createDeal(Map<String, dynamic> values) async {
    try {
      values['type'] = 'opportunity'; // Ensure it's an opportunity
      final id = await _crmService.createLead(values);
      await fetchDeals(refresh: true);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update an existing deal
  Future<bool> updateDeal(int dealId, Map<String, dynamic> values) async {
    try {
      final success = await _crmService.updateLead(dealId, values);
      if (success) {
        await fetchDeals(refresh: true);
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete a deal
  Future<bool> deleteDeal(int dealId) async {
    try {
      final success = await _crmService.deleteLead(dealId);
      if (success) {
        _deals.removeWhere((deal) => deal.id == dealId.toString());
        _groupDealsByStage();
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Mark deal as won
  Future<bool> markAsWon(int dealId) async {
    try {
      final success = await _crmService.markAsWon(dealId);
      if (success) {
        await fetchDeals(refresh: true);
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Mark deal as lost
  Future<bool> markAsLost(int dealId, {int? lostReasonId}) async {
    try {
      final success = await _crmService.markAsLost(dealId, lostReasonId: lostReasonId);
      if (success) {
        await fetchDeals(refresh: true);
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Add activity to a deal
  Future<bool> addActivity({
    required int dealId,
    required String summary,
    String? note,
    required String dateDeadline,
    int? activityTypeId,
  }) async {
    try {
      await _crmService.createActivity(
        leadId: dealId,
        summary: summary,
        note: note,
        dateDeadline: dateDeadline,
        activityTypeId: activityTypeId,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Post a message/note to a deal
  Future<bool> postMessage({
    required int dealId,
    required String body,
  }) async {
    try {
      await _crmService.postMessage(
        leadId: dealId,
        body: body,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Group deals by stage for pipeline view
  void _groupDealsByStage() {
    _dealsByStage = {};
    for (final deal in _deals) {
      if (!_dealsByStage.containsKey(deal.stage)) {
        _dealsByStage[deal.stage] = [];
      }
      _dealsByStage[deal.stage]!.add(deal);
    }
  }

  /// Filter deals by stage
  List<Deal> getDealsByStage(String stage) {
    return _deals.where((deal) => deal.stage == stage).toList();
  }

  /// Search deals
  List<Deal> searchDeals(String query) {
    if (query.isEmpty) return _deals;
    
    final lowerQuery = query.toLowerCase();
    return _deals.where((deal) {
      return deal.title.toLowerCase().contains(lowerQuery) ||
          deal.company.toLowerCase().contains(lowerQuery) ||
          deal.contactName.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get total revenue
  double getTotalRevenue() {
    return _deals.fold(0.0, (sum, deal) {
      final value = double.tryParse(
        deal.value.replaceAll(RegExp(r'[^\d.]'), ''),
      ) ?? 0.0;
      return sum + value;
    });
  }

  /// Get deals count by stage
  Map<String, int> getDealsCountByStage() {
    final counts = <String, int>{};
    for (final stage in Deal.stages) {
      counts[stage] = getDealsByStage(stage).length;
    }
    return counts;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
