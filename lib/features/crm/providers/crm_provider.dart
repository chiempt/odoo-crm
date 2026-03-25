import 'package:flutter/material.dart';
import '../../../core/services/odoo_crm_service.dart';
import '../models/lead_model.dart';

class CrmStage {
  final int id;
  final String name;

  CrmStage({required this.id, required this.name});
}

class CrmUser {
  final int id;
  final String name;
  final String? email;

  CrmUser({required this.id, required this.name, this.email});
}

class CrmPartner {
  final int id;
  final String name;

  CrmPartner({required this.id, required this.name});
}

class CrmProvider with ChangeNotifier {
  final OdooCrmService _crmService = OdooCrmService();
  int? _uid;

  List<Lead> _leads = [];
  List<CrmStage> _stages = [];
  List<CrmUser> _users = [];
  List<CrmPartner> _partners = [];

  bool _isLoading = false;
  bool _isFetchingMore = false;
  String? _error;

  int _offset = 0;
  final int _limit = 20;
  bool _hasMore = true;

  String _currentQuery = '';
  int _currentFilterIndex = 0; // 0: All, 1: Hot, 2: My, 3: Overdue
  int? _currentStageId;
  int? _currentUserId;
  double? _currentMinRevenue;
  double? _currentMaxRevenue;
  int? _currentPriority;
  String _currentOrder = "create_date desc";

  List<Lead> get leads => _leads;
  List<CrmStage> get stages => _stages;
  List<CrmUser> get users => _users;
  List<CrmPartner> get partners => _partners;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  int get currentFilterIndex => _currentFilterIndex;
  int? get currentStageId => _currentStageId;
  int? get currentUserId => _currentUserId;
  double? get currentMinRevenue => _currentMinRevenue;
  double? get currentMaxRevenue => _currentMaxRevenue;
  int? get currentPriority => _currentPriority;
  String get currentOrder => _currentOrder;

  void updateAuth(String token, String serverUrl, int? uid) {
    _uid = uid;

    if (_uid != null) {
      if (_leads.isEmpty) fetchLeads();
      if (_stages.isEmpty) fetchStages();
      if (_users.isEmpty) fetchUsers();
      if (_partners.isEmpty) fetchPartners();
    }
  }

  Future<void> fetchStages() async {
    try {
      final records = await _crmService.fetchStages();
      if (records.isNotEmpty) {
        _stages = records
            .map((e) => CrmStage(id: e['id'] as int, name: e['name'] as String))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Fetch stages error: $e');
    }
  }

  Future<void> fetchUsers() async {
    try {
      final records = await _crmService.fetchUsers();
      _users = records
          .map(
            (e) => CrmUser(
              id: e['id'] as int,
              name: e['name'] as String,
              email: e['email'] is String ? e['email'] as String : null,
            ),
          )
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch users error: $e');
    }
  }

  Future<void> fetchPartners() async {
    try {
      final records = await _crmService.fetchPartners();
      _partners = records
          .map((e) => CrmPartner(id: e['id'] as int, name: e['name'] as String))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch partners error: $e');
    }
  }

  Future<void> fetchLeads({
    bool isLoadMore = false,
    String? query,
    int? filterIndex,
    int? stageId,
    int? userId,
    double? minRevenue,
    double? maxRevenue,
    int? priority,
    String? order,
  }) async {
    if (query != null) _currentQuery = query;
    if (filterIndex != null) _currentFilterIndex = filterIndex;
    if (stageId != null) {
      _currentStageId = stageId == -1 ? null : stageId;
    }
    if (userId != null) {
      _currentUserId = userId == -1 ? null : userId;
    }
    if (minRevenue != null) _currentMinRevenue = minRevenue;
    if (maxRevenue != null) _currentMaxRevenue = maxRevenue;
    if (priority != null) {
      _currentPriority = priority == -1 ? null : priority;
    }
    if (order != null) _currentOrder = order;

    if (isLoadMore) {
      if (!_hasMore || _isFetchingMore) return;
      _isFetchingMore = true;
      notifyListeners();
    } else {
      _isLoading = true;
      _error = null;
      _offset = 0;
      _hasMore = true;
      notifyListeners();
    }

    try {
      // Build Odoo Domain
      List<dynamic> domain = [
        ["type", "=", "opportunity"],
      ];

      if (_currentQuery.trim().isNotEmpty) {
        final q = _currentQuery.trim();
        // Use multiple '|' for ORing multiple fields
        // For 5 fields, we need 4 '|'
        domain.add('|');
        domain.add('|');
        domain.add('|');
        domain.add('|');
        domain.add(["name", "ilike", q]);
        domain.add(["partner_id", "ilike", q]);
        domain.add(["email_from", "ilike", q]);
        domain.add(["phone", "ilike", q]);
        domain.add(["contact_name", "ilike", q]);
      }

      if (_currentFilterIndex == 1) {
        domain.add(["probability", ">=", 70]);
      } else if (_currentFilterIndex == 2 && _uid != null) {
        domain.add(["user_id", "=", _uid]);
      } else if (_currentFilterIndex == 3) {
        final todayStr = DateTime.now().toIso8601String().split('T')[0];
        domain.add("&");
        domain.add(["date_deadline", "<", todayStr]);
        domain.add(["date_deadline", "!=", false]);
      }

      if (_currentStageId != null) {
        domain.add(["stage_id", "=", _currentStageId]);
      }

      if (_currentUserId != null) {
        domain.add(["user_id", "=", _currentUserId]);
      }

      if (_currentMinRevenue != null) {
        domain.add(["expected_revenue", ">=", _currentMinRevenue]);
      }

      if (_currentMaxRevenue != null) {
        domain.add(["expected_revenue", "<=", _currentMaxRevenue]);
      }

      if (_currentPriority != null) {
        // Map 1-5 starts to Odoo priority '0', '1', '2', '3'
        // This mapping depends on Odoo version/config, usually it's 0, 1, 2, 3
        String p = "0";
        if (_currentPriority! > 4) {
          p = "3";
        } else if (_currentPriority! > 2) {
          p = "2";
        } else if (_currentPriority! > 1) {
          p = "1";
        }
        domain.add(["priority", "=", p]);
      }

      final records = await _crmService.fetchLeads(
        domain: domain,
        limit: _limit,
        offset: _offset,
        order: _currentOrder,
      );

      if (records.isNotEmpty || !isLoadMore) {
        final mappedLeads = records.map((e) => Lead.fromOdooJson(e)).toList();

        if (isLoadMore) {
          _leads.addAll(mappedLeads);
        } else {
          _leads = mappedLeads;
        }

        _offset += records.length;
        _hasMore = records.length == _limit;
      }
    } catch (e) {
      _error = 'Exception: $e';
    } finally {
      _isLoading = false;
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  Future<Lead?> fetchLeadById(int id) async {
    try {
      final results = await Future.wait([
        _crmService.fetchLeadById(id),
        _crmService.fetchMessages(id),
        _crmService.fetchActivities(id),
        _crmService.fetchFollowers(id, 'crm.lead').catchError((e) {
          debugPrint('Fetch followers error: $e');
          return <Map<String, dynamic>>[];
        }),
        _crmService.fetchAttachments(id, 'crm.lead').catchError((e) {
          debugPrint('Fetch attachments error: $e');
          return <Map<String, dynamic>>[];
        }),
      ]);

      final record = results[0] as Map<String, dynamic>?;
      final messages = results[1] as List<Map<String, dynamic>>;
      final activities = results[2] as List<Map<String, dynamic>>;
      final followersBatch = results[3] as List<Map<String, dynamic>>;
      final attachmentsBatch = results[4] as List<Map<String, dynamic>>;

      if (record != null) {
        // Map Timeline from Messages
        final timelineEntries = messages.map((m) {
          final author = m['author_id'] is List ? m['author_id'][1].toString() : 'System';
          return LeadTimelineEntry(
            description: _stripHtml(m['body']?.toString() ?? 'No content'),
            timeAgo: m['date']?.toString().split('.')[0] ?? '',
            author: author,
            dotColor: const Color(0xFF4CAF50),
          );
        }).toList();

        // Map Notes also from Messages
        final notes = messages
            .where((m) => m['message_type'] == 'comment' || m['message_type'] == 'notification')
            .map((m) {
          final author = m['author_id'] is List ? m['author_id'][1].toString() : 'System';
          return NoteEntry(
            type: m['message_type'] == 'comment' ? 'NOTE' : 'SYSTEM',
            content: _stripHtml(m['body']?.toString() ?? ''),
            timeAgo: m['date']?.toString().split('.')[0] ?? '',
            author: author,
            icon: m['message_type'] == 'comment' ? Icons.description_outlined : Icons.info_outline,
            iconBgColor: const Color(0xFFFFF8E1),
          );
        }).toList();

        // Map Scheduled Activities
        final scheduled = activities.map((a) {
          return ScheduledActivity(
            title: a['summary']?.toString() ?? 'No Summary',
            description: _stripHtml(a['note']?.toString() ?? ''),
            priority: 'Medium',
            priorityColor: const Color(0xFFF57C00),
            date: a['date_deadline']?.toString() ?? '',
            duration: '',
            icon: Icons.access_time_rounded,
            iconBgColor: const Color(0xFFE3F2FD),
          );
        }).toList();

        // Map Followers
        final followers = followersBatch.map((f) {
          final partnerInfo = f['partner_id'] as List;
          return LeadFollower(
            id: f['id'] as int,
            partnerId: partnerInfo[0] as int,
            name: partnerInfo[1].toString(),
          );
        }).toList();

        // Map Attachments
        final attachments = attachmentsBatch.map((a) {
          return LeadAttachment(
            id: a['id'] as int,
            name: a['name'].toString(),
            mimetype: a['mimetype']?.toString(),
            fileSize: (a['file_size'] ?? 0) as int,
            createDate: a['create_date']?.toString() ?? '',
          );
        }).toList();

        final baseLead = Lead.fromOdooJson(record);
        final updatedLead = Lead(
          id: baseLead.id,
          title: baseLead.title,
          tag: baseLead.tag,
          tagColor: baseLead.tagColor,
          value: baseLead.value,
          probability: baseLead.probability,
          assignee: baseLead.assignee,
          company: baseLead.company,
          stars: baseLead.stars,
          stage: baseLead.stage,
          dueDate: baseLead.dueDate,
          avatarColor: baseLead.avatarColor,
          avatarInitials: baseLead.avatarInitials,
          email: baseLead.email,
          phone: baseLead.phone,
          description: baseLead.description,
          expectedRevenue: baseLead.expectedRevenue,
          contactName: baseLead.contactName,
          location: baseLead.location,
          timeline: timelineEntries,
          notes: notes,
          scheduledActivities: scheduled,
          followers: followers,
          attachments: attachments,
        );

        // Update the lead in our list
        final index = _leads.indexWhere((l) => l.id == id.toString());
        if (index != -1) {
          _leads[index] = updatedLead;
        } else {
          _leads.add(updatedLead);
        }
        notifyListeners();
        return updatedLead;
      }
    } catch (e) {
      debugPrint('Fetch lead details error: $e');
    }
    return null;
  }

  String _stripHtml(String htmlString) {
    if (htmlString.isEmpty) return '';
    // Simple regex to strip HTML tags for UI display
    return htmlString.replaceAll(RegExp(r'<[^>]*>|&nbsp;'), ' ').trim();
  }

  Future<bool> createLead(Map<String, dynamic> values) async {
    _isLoading = true;
    notifyListeners();
    try {
      final id = await _crmService.createLead(values);
      if (id > 0) {
        await fetchLeads();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Create Lead Error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateLead(int id, Map<String, dynamic> values) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _crmService.updateLead(id, values);
      if (success) {
        await fetchLeads();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Update Lead Error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteLead(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _crmService.deleteLead(id);
      if (success) {
        _leads.removeWhere((l) => l.id == id.toString());
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Delete Lead Error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> markAsWon(int id) async {
    try {
      final success = await _crmService.markAsWon(id);
      if (success) {
        await fetchLeads();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Mark as Won Error: $e';
      return false;
    }
  }

  Future<bool> markAsLost(int id, {int? lostReasonId}) async {
    try {
      final success = await _crmService.markAsLost(
        id,
        lostReasonId: lostReasonId,
      );
      if (success) {
        await fetchLeads();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Mark as Lost Error: $e';
      return false;
    }
  }

  Future<bool> convertToOpportunity(int id) async {
    try {
      final success = await _crmService.convertToOpportunity(id);
      if (success) {
        await fetchLeads();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Convert to Opportunity Error: $e';
      return false;
    }
  }

  Future<bool> logMessage(int id, String body) async {
    try {
      final msgId = await _crmService.postMessage(leadId: id, body: body);
      return msgId > 0;
    } catch (e) {
      debugPrint('Log message error: $e');
      return false;
    }
  }

  Future<bool> scheduleActivity({
    required int leadId,
    required String summary,
    String? note,
    required String dateDeadline,
    int? activityTypeId,
  }) async {
    try {
      final actId = await _crmService.createActivity(
        leadId: leadId,
        summary: summary,
        note: note,
        dateDeadline: dateDeadline,
        activityTypeId: activityTypeId,
      );
      return actId > 0;
    } catch (e) {
      debugPrint('Schedule activity error: $e');
      return false;
    }
  }

  Future<bool> addFollower(int leadId, int partnerId) async {
    try {
      return await _crmService.addFollower(leadId, 'crm.lead', [partnerId]);
    } catch (e) {
      debugPrint('Add follower error: $e');
      return false;
    }
  }

  Future<bool> removeFollower(int leadId, int partnerId) async {
    try {
      return await _crmService.removeFollower(leadId, 'crm.lead', [partnerId]);
    } catch (e) {
      debugPrint('Remove follower error: $e');
      return false;
    }
  }

  Future<bool> uploadAttachment({
    required int leadId,
    required String fileName,
    required String base64Content,
  }) async {
    try {
      final attrId = await _crmService.uploadAttachment(
        resId: leadId,
        resModel: 'crm.lead',
        fileName: fileName,
        base64Content: base64Content,
      );
      return attrId > 0;
    } catch (e) {
      debugPrint('Upload attachment error: $e');
      return false;
    }
  }

  Future<List<int>> ensureLeadTagIds(List<String> tagNames) {
    return _crmService.ensureTagIds(tagNames);
  }

  Future<int?> ensureLeadSourceId(String sourceName) {
    return _crmService.ensureLeadSourceId(sourceName);
  }

  Future<int?> ensureLeadCampaignId(String campaignName) {
    return _crmService.ensureLeadCampaignId(campaignName);
  }

  Future<bool> assignSalesperson(int leadId, int userId) async {
    try {
      final success = await updateLead(leadId, {"user_id": userId});
      if (success) {
        await fetchLeadById(leadId);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Assign salesperson error: $e');
      return false;
    }
  }
}
