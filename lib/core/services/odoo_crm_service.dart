import 'api_service.dart';
import 'auth_service.dart';

/// Service for Odoo CRM Lead/Opportunity operations using JSON-RPC 2.0
class OdooCrmService {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  static final OdooCrmService _instance = OdooCrmService._internal();
  factory OdooCrmService() => _instance;
  OdooCrmService._internal();

  Future<void> _ensureAuthenticated() async {
    final db = await _authService.getDatabase();
    final uid = await _authService.getUid();
    final token = await _authService.getToken();

    if (db == null || uid == null || token == null) {
      throw Exception('Not authenticated');
    }
  }

  Future<List<Map<String, dynamic>>> _searchRead({
    required String model,
    required List<dynamic> domain,
    required List<String> fields,
    int? limit,
    String? order,
  }) async {
    await _ensureAuthenticated();

    final result = await _apiService.call(
      '/web/dataset/call_kw',
      method: 'call',
      params: {
        'model': model,
        'method': 'search_read',
        'args': [domain],
        'kwargs': {
          'fields': fields,
          if (limit != null) 'limit': limit,
          if (order != null) 'order': order,
        },
      },
    );

    final list = result is List ? result : [];
    return List<Map<String, dynamic>>.from(list);
  }

  Future<int> _createRecord({
    required String model,
    required Map<String, dynamic> values,
  }) async {
    await _ensureAuthenticated();

    final result = await _apiService.call(
      '/web/dataset/call_kw',
      method: 'call',
      params: {
        'model': model,
        'method': 'create',
        'args': [values],
        'kwargs': {},
      },
    );

    return result is int ? result : 0;
  }

  Future<int?> _ensureRecordByName({
    required String model,
    required String name,
  }) async {
    final normalized = name.trim();
    if (normalized.isEmpty) return null;

    final records = await _searchRead(
      model: model,
      domain: [
        ['name', '=ilike', normalized],
      ],
      fields: ['id', 'name'],
      limit: 1,
      order: 'id desc',
    );

    if (records.isNotEmpty) {
      final id = records.first['id'];
      if (id is int) return id;
    }

    final createdId = await _createRecord(
      model: model,
      values: {'name': normalized},
    );

    return createdId > 0 ? createdId : null;
  }

  /// Fetch all CRM leads/opportunities
  Future<List<Map<String, dynamic>>> fetchLeads({
    List<dynamic>? domain,
    List<String>? fields,
    int? limit,
    int offset = 0,
    String? order,
  }) async {
    await _ensureAuthenticated();

    final result = await _apiService.call(
      '/web/dataset/call_kw',
      method: 'call',
      params: {
        'model': 'crm.lead',
        'method': 'search_read',
        'args': [
          domain ?? [],
        ],
        'kwargs': {
          'fields': fields ?? _defaultLeadFields,
          'limit': limit ?? 100,
          'offset': offset,
          'order': order ?? 'date_deadline desc, id desc',
        },
      },
    );

    final list = result is List ? result : [];
    return List<Map<String, dynamic>>.from(list);
  }

  /// Fetch a single lead by ID
  Future<Map<String, dynamic>?> fetchLeadById(int id) async {
    await _ensureAuthenticated();

    final result = await _apiService.call(
      '/web/dataset/call_kw',
      method: 'call',
      params: {
        'model': 'crm.lead',
        'method': 'read',
        'args': [
          [id],
        ],
        'kwargs': {
          'fields': _detailLeadFields,
        },
      },
    );

    final list = result is List ? result : [];
    final maps = List<Map<String, dynamic>>.from(list);
    return maps.isNotEmpty ? maps.first : null;
  }

  /// Create a new lead
  Future<int> createLead(Map<String, dynamic> values) async {
    await _ensureAuthenticated();

    final result = await _apiService.call(
      '/web/dataset/call_kw',
      method: 'call',
      params: {
        'model': 'crm.lead',
        'method': 'create',
        'args': [values],
        'kwargs': {},
      },
    );

    return result is int ? result : 0;
  }

  /// Update an existing lead
  Future<bool> updateLead(int id, Map<String, dynamic> values) async {
    await _ensureAuthenticated();

    final result = await _apiService.call(
      '/web/dataset/call_kw',
      method: 'call',
      params: {
        'model': 'crm.lead',
        'method': 'write',
        'args': [
          [id],
          values,
        ],
        'kwargs': {},
      },
    );

    return result == true;
  }

  /// Delete a lead
  Future<bool> deleteLead(int id) async {
    await _ensureAuthenticated();

    final result = await _apiService.call(
      '/web/dataset/call_kw',
      method: 'call',
      params: {
        'model': 'crm.lead',
        'method': 'unlink',
        'args': [
          [id],
        ],
        'kwargs': {},
      },
    );

    return result == true;
  }

  /// Fetch CRM stages
  Future<List<Map<String, dynamic>>> fetchStages() async {
    await _ensureAuthenticated();

    final result = await _apiService.call(
      '/web/dataset/call_kw',
      method: 'call',
      params: {
        'model': 'crm.stage',
        'method': 'search_read',
        'args': [
          [],
        ],
        'kwargs': {
          'fields': ['id', 'name', 'sequence', 'fold', 'probability'],
          'order': 'sequence asc',
        },
      },
    );

    final list = result is List ? result : [];
    return List<Map<String, dynamic>>.from(list);
  }

  /// Fetch lead activities (mail.activity)
  Future<List<Map<String, dynamic>>> fetchActivities(int leadId) async {
    await _ensureAuthenticated();

    final result = await _apiService.call(
      '/web/dataset/call_kw',
      method: 'call',
      params: {
        'model': 'mail.activity',
        'method': 'search_read',
        'args': [
          [
            ['res_model', '=', 'crm.lead'],
            ['res_id', '=', leadId],
          ],
        ],
        'kwargs': {
          'fields': [
            'id',
            'summary',
            'note',
            'date_deadline',
            'activity_type_id',
            'user_id',
            'state',
          ],
          'order': 'date_deadline asc',
        },
      },
    );

    final list = result is List ? result : [];
    return List<Map<String, dynamic>>.from(list);
  }

  /// Fetch lead message history (mail.message)
  Future<List<Map<String, dynamic>>> fetchMessages(int leadId) async {
    await _ensureAuthenticated();

    final result = await _apiService.call(
      '/web/dataset/call_kw',
      method: 'call',
      params: {
        'model': 'mail.message',
        'method': 'search_read',
        'args': [
          [
            ['model', '=', 'crm.lead'],
            ['res_id', '=', leadId],
          ],
        ],
        'kwargs': {
          'fields': [
            'id',
            'body',
            'date',
            'author_id',
            'message_type',
            'subtype_id',
          ],
          'order': 'date desc',
          'limit': 50,
        },
      },
    );

    final list = result is List ? result : [];
    return List<Map<String, dynamic>>.from(list);
  }

  /// Create activity for a lead
  Future<int> createActivity({
    required int leadId,
    required String summary,
    String? note,
    required String dateDeadline,
    int? activityTypeId,
  }) async {
    await _ensureAuthenticated();
    final uid = await _authService.getUid();
    if (uid == null) {
      throw Exception('Not authenticated');
    }

    final result = await _apiService.call(
      '/web/dataset/call_kw',
      method: 'call',
      params: {
        'model': 'mail.activity',
        'method': 'create',
        'args': [
          {
            'res_model': 'crm.lead',
            'res_id': leadId,
            'summary': summary,
            'note': note,
            'date_deadline': dateDeadline,
            'activity_type_id': activityTypeId ?? 1, // Default activity type
            'user_id': uid,
          }
        ],
        'kwargs': {},
      },
    );

    return result is int ? result : 0;
  }

  /// Post a message/note to a lead
  Future<int> postMessage({
    required int leadId,
    required String body,
    String messageType = 'comment',
  }) async {
    await _ensureAuthenticated();

    final result = await _apiService.call(
      '/web/dataset/call_kw',
      method: 'call',
      params: {
        'model': 'crm.lead',
        'method': 'message_post',
        'args': [
          [leadId],
        ],
        'kwargs': {
          'body': body,
          'message_type': messageType,
        },
      },
    );

    return result is int ? result : 0;
  }

  /// Convert lead to opportunity
  Future<bool> convertToOpportunity(int leadId) async {
    await _ensureAuthenticated();

    final result = await _apiService.call(
      '/web/dataset/call_kw',
      method: 'call',
      params: {
        'model': 'crm.lead',
        'method': 'convert_opportunity',
        'args': [
          [leadId],
        ],
        'kwargs': {
          'partner_id': false,
        },
      },
    );

    return result != null;
  }

  /// Mark lead as won
  Future<bool> markAsWon(int leadId) async {
    await _ensureAuthenticated();

    final result = await _apiService.call(
      '/web/dataset/call_kw',
      method: 'call',
      params: {
        'model': 'crm.lead',
        'method': 'action_set_won',
        'args': [
          [leadId],
        ],
        'kwargs': {},
      },
    );

    return result != null;
  }

  /// Mark lead as lost
  Future<bool> markAsLost(int leadId, {int? lostReasonId}) async {
    await _ensureAuthenticated();

    final result = await _apiService.call(
      '/web/dataset/call_kw',
      method: 'call',
      params: {
        'model': 'crm.lead',
        'method': 'action_set_lost',
        'args': [
          [leadId],
        ],
        'kwargs': {
          if (lostReasonId != null) 'lost_reason_id': lostReasonId,
        },
      },
    );

    return result != null;
  }

  /// Fetch followers for a record
  Future<List<Map<String, dynamic>>> fetchFollowers(int resId, String resModel) async {
    await _ensureAuthenticated();

    final result = await _apiService.call(
      '/web/dataset/call_kw',
      method: 'call',
      params: {
        'model': 'mail.followers',
        'method': 'search_read',
        'args': [
          [
            ['res_model', '=', resModel],
            ['res_id', '=', resId],
          ],
        ],
        'kwargs': {
          'fields': ['id', 'partner_id', 'subtype_ids'],
        },
      },
    );

    final list = result is List ? result : [];
    return List<Map<String, dynamic>>.from(list);
  }

  /// Add a follower to a record
  Future<bool> addFollower(int resId, String resModel, List<int> partnerIds) async {
    await _ensureAuthenticated();

    final result = await _apiService.call(
      '/web/dataset/call_kw',
      method: 'call',
      params: {
        'model': resModel,
        'method': 'message_subscribe',
        'args': [
          [resId],
          partnerIds,
        ],
        'kwargs': {},
      },
    );

    return result == true;
  }

  /// Remove a follower from a record
  Future<bool> removeFollower(int resId, String resModel, List<int> partnerIds) async {
    await _ensureAuthenticated();

    final result = await _apiService.call(
      '/web/dataset/call_kw',
      method: 'call',
      params: {
        'model': resModel,
        'method': 'message_unsubscribe',
        'args': [
          [resId],
          partnerIds,
        ],
        'kwargs': {},
      },
    );

    return result == true;
  }

  /// Fetch attachments for a record
  Future<List<Map<String, dynamic>>> fetchAttachments(int resId, String resModel) async {
    await _ensureAuthenticated();

    final result = await _apiService.call(
      '/web/dataset/call_kw',
      method: 'call',
      params: {
        'model': 'ir.attachment',
        'method': 'search_read',
        'args': [
          [
            ['res_model', '=', resModel],
            ['res_id', '=', resId],
          ],
        ],
        'kwargs': {
          'fields': ['id', 'name', 'mimetype', 'file_size', 'create_date'],
          'order': 'create_date desc',
        },
      },
    );

    final list = result is List ? result : [];
    return List<Map<String, dynamic>>.from(list);
  }

  /// Upload an attachment to a record
  Future<int> uploadAttachment({
    required int resId,
    required String resModel,
    required String fileName,
    required String base64Content,
  }) async {
    await _ensureAuthenticated();

    final result = await _apiService.call(
      '/web/dataset/call_kw',
      method: 'call',
      params: {
        'model': 'ir.attachment',
        'method': 'create',
        'args': [
          {
            'name': fileName,
            'datas': base64Content,
            'res_model': resModel,
            'res_id': resId,
            'type': 'binary',
          }
        ],
        'kwargs': {},
      },
    );

    return result is int ? result : 0;
  }

  /// Fetch users (salespeople)
  Future<List<Map<String, dynamic>>> fetchUsers() async {
    await _ensureAuthenticated();

    final result = await _apiService.call(
      '/web/dataset/call_kw',
      method: 'call',
      params: {
        'model': 'res.users',
        'method': 'search_read',
        'args': [
          [
            ['active', '=', true],
          ],
        ],
        'kwargs': {
          'fields': ['id', 'name', 'email', 'image_128'],
          'order': 'name asc',
        },
      },
    );

    final list = result is List ? result : [];
    return List<Map<String, dynamic>>.from(list);
  }

  /// Fetch partners (companies/contacts)
  Future<List<Map<String, dynamic>>> fetchPartners({
    String? searchTerm,
    int limit = 50,
  }) async {
    await _ensureAuthenticated();

    List<dynamic> domain = [];
    if (searchTerm != null && searchTerm.isNotEmpty) {
      domain = [
        '|',
        ['name', 'ilike', searchTerm],
        ['email', 'ilike', searchTerm],
      ];
    }

    final result = await _apiService.call(
      '/web/dataset/call_kw',
      method: 'call',
      params: {
        'model': 'res.partner',
        'method': 'search_read',
        'args': [domain],
        'kwargs': {
          'fields': ['id', 'name', 'email', 'phone', 'mobile', 'image_128'],
          'limit': limit,
          'order': 'name asc',
        },
      },
    );

    final list = result is List ? result : [];
    return List<Map<String, dynamic>>.from(list);
  }

  Future<List<int>> ensureTagIds(List<String> tagNames) async {
    final ids = <int>[];

    for (final raw in tagNames) {
      final name = raw.trim();
      if (name.isEmpty) continue;

      final id = await _ensureRecordByName(model: 'crm.tag', name: name);
      if (id != null) {
        ids.add(id);
      }
    }

    return ids;
  }

  Future<int?> ensureLeadSourceId(String sourceName) {
    return _ensureRecordByName(model: 'utm.source', name: sourceName);
  }

  Future<int?> ensureLeadCampaignId(String campaignName) {
    return _ensureRecordByName(model: 'utm.campaign', name: campaignName);
  }

  /// Default fields for lead list view
  static const List<String> _defaultLeadFields = [
    'id',
    'name',
    'partner_id',
    'partner_name',
    'contact_name',
    'email_from',
    'phone',
    'mobile',
    'expected_revenue',
    'probability',
    'stage_id',
    'user_id',
    'team_id',
    'date_deadline',
    'priority',
    'type',
    'active',
    'create_date',
    'write_date',
  ];

  /// Detailed fields for lead detail view
  static const List<String> _detailLeadFields = [
    'id',
    'name',
    'partner_id',
    'partner_name',
    'contact_name',
    'title',
    'email_from',
    'phone',
    'mobile',
    'website',
    'street',
    'street2',
    'city',
    'state_id',
    'zip',
    'country_id',
    'expected_revenue',
    'probability',
    'stage_id',
    'user_id',
    'team_id',
    'date_deadline',
    'date_closed',
    'priority',
    'type',
    'description',
    'tag_ids',
    'company_id',
    'referred',
    'active',
    'create_date',
    'write_date',
    'activity_ids',
    'message_ids',
  ];
}
