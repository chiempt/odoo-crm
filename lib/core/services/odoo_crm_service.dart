import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'api_service.dart';
import 'auth_service.dart';

typedef OdooRpcCall =
    Future<dynamic> Function(
      String path, {
      required String method,
      required Map<String, dynamic> params,
    });

typedef StringAuthGetter = Future<String?> Function();
typedef IntAuthGetter = Future<int?> Function();

class AttachmentDownloadResult {
  final String fileName;
  final String? mimetype;
  final Uint8List bytes;

  const AttachmentDownloadResult({
    required this.fileName,
    required this.bytes,
    this.mimetype,
  });
}

/// Service for Odoo CRM Lead/Opportunity operations using JSON-RPC 2.0
class OdooCrmService {
  final OdooRpcCall _rpcCall;
  final StringAuthGetter _getDatabase;
  final IntAuthGetter _getUid;
  final StringAuthGetter _getToken;
  final Map<String, int> _activityTypeIdCache = {};

  static const Map<String, List<String>> _activityTypeNameCandidates = {
    'call': ['call', 'phone call'],
    'meeting': ['meeting'],
    'email': ['email'],
    'todo': ['to do', 'todo'],
  };

  static final OdooCrmService _instance = OdooCrmService._internal();
  factory OdooCrmService() => _instance;
  OdooCrmService._internal({
    OdooRpcCall? rpcCall,
    StringAuthGetter? getDatabase,
    IntAuthGetter? getUid,
    StringAuthGetter? getToken,
  }) : _rpcCall =
           rpcCall ??
           ((path, {required method, required params}) {
             return ApiService().call(path, method: method, params: params);
           }),
       _getDatabase = getDatabase ?? AuthService().getDatabase,
       _getUid = getUid ?? AuthService().getUid,
       _getToken = getToken ?? AuthService().getToken;

  @visibleForTesting
  factory OdooCrmService.test({
    required OdooRpcCall rpcCall,
    required StringAuthGetter getDatabase,
    required IntAuthGetter getUid,
    required StringAuthGetter getToken,
  }) {
    return OdooCrmService._internal(
      rpcCall: rpcCall,
      getDatabase: getDatabase,
      getUid: getUid,
      getToken: getToken,
    );
  }

  Future<void> _ensureAuthenticated() async {
    final db = await _getDatabase();
    final uid = await _getUid();
    final token = await _getToken();

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

    final result = await _rpcCall(
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

    final result = await _rpcCall(
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

    final result = await _rpcCall(
      '/web/dataset/call_kw',
      method: 'call',
      params: {
        'model': 'crm.lead',
        'method': 'search_read',
        'args': [domain ?? []],
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

    final result = await _rpcCall(
      '/web/dataset/call_kw',
      method: 'call',
      params: {
        'model': 'crm.lead',
        'method': 'read',
        'args': [
          [id],
        ],
        'kwargs': {'fields': _detailLeadFields},
      },
    );

    final list = result is List ? result : [];
    final maps = List<Map<String, dynamic>>.from(list);
    return maps.isNotEmpty ? maps.first : null;
  }

  /// Create a new lead
  Future<int> createLead(Map<String, dynamic> values) async {
    await _ensureAuthenticated();

    final result = await _rpcCall(
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

    final result = await _rpcCall(
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

    final result = await _rpcCall(
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

    final result = await _rpcCall(
      '/web/dataset/call_kw',
      method: 'call',
      params: {
        'model': 'crm.stage',
        'method': 'search_read',
        'args': [[]],
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

    final result = await _rpcCall(
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

    final result = await _rpcCall(
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
    String? activityTypeKey,
  }) async {
    await _ensureAuthenticated();
    final uid = await _getUid();
    if (uid == null) {
      throw Exception('Not authenticated');
    }
    final resolvedActivityTypeId = await _resolveActivityTypeId(
      explicitId: activityTypeId,
      semanticKey: activityTypeKey,
    );

    final result = await _rpcCall(
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
            'activity_type_id': resolvedActivityTypeId,
            'user_id': uid,
          },
        ],
        'kwargs': {},
      },
    );

    return result is int ? result : 0;
  }

  Future<int> _resolveActivityTypeId({
    int? explicitId,
    String? semanticKey,
  }) async {
    if (explicitId != null && explicitId > 0) {
      return explicitId;
    }

    final key = (semanticKey?.trim().toLowerCase() ?? 'todo');
    final normalizedKey = key.isEmpty ? 'todo' : key;

    final cached = _activityTypeIdCache[normalizedKey];
    if (cached != null) {
      return cached;
    }

    final candidates = [
      ...?_activityTypeNameCandidates[normalizedKey],
      if (normalizedKey != 'todo') ...?_activityTypeNameCandidates['todo'],
    ];

    for (final candidate in candidates) {
      final found = await _findActivityTypeIdByName(candidate);
      if (found != null) {
        _activityTypeIdCache[normalizedKey] = found;
        return found;
      }
    }

    final fallback = await _searchRead(
      model: 'mail.activity.type',
      domain: [],
      fields: ['id'],
      limit: 1,
      order: 'sequence asc, id asc',
    );
    if (fallback.isNotEmpty && fallback.first['id'] is int) {
      final id = fallback.first['id'] as int;
      _activityTypeIdCache[normalizedKey] = id;
      return id;
    }

    throw Exception('No activity type is available in Odoo.');
  }

  Future<int?> _findActivityTypeIdByName(String name) async {
    final rows = await _searchRead(
      model: 'mail.activity.type',
      domain: [
        ['name', '=ilike', name],
      ],
      fields: ['id'],
      limit: 1,
      order: 'sequence asc, id asc',
    );

    if (rows.isNotEmpty && rows.first['id'] is int) {
      return rows.first['id'] as int;
    }
    return null;
  }

  /// Post a message/note to a lead
  Future<int> postMessage({
    required int leadId,
    required String body,
    String messageType = 'comment',
  }) async {
    await _ensureAuthenticated();

    final result = await _rpcCall(
      '/web/dataset/call_kw',
      method: 'call',
      params: {
        'model': 'crm.lead',
        'method': 'message_post',
        'args': [
          [leadId],
        ],
        'kwargs': {'body': body, 'message_type': messageType},
      },
    );

    return result is int ? result : 0;
  }

  /// Convert lead to opportunity
  Future<bool> convertToOpportunity(int leadId) async {
    await _ensureAuthenticated();

    final result = await _rpcCall(
      '/web/dataset/call_kw',
      method: 'call',
      params: {
        'model': 'crm.lead',
        'method': 'convert_opportunity',
        'args': [
          [leadId],
        ],
        'kwargs': {'partner_id': false},
      },
    );

    return result != null;
  }

  /// Mark lead as won
  Future<bool> markAsWon(int leadId) async {
    await _ensureAuthenticated();

    final result = await _rpcCall(
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

    final result = await _rpcCall(
      '/web/dataset/call_kw',
      method: 'call',
      params: {
        'model': 'crm.lead',
        'method': 'action_set_lost',
        'args': [
          [leadId],
        ],
        'kwargs': {if (lostReasonId != null) 'lost_reason_id': lostReasonId},
      },
    );

    return result != null;
  }

  /// Fetch followers for a record
  Future<List<Map<String, dynamic>>> fetchFollowers(
    int resId,
    String resModel,
  ) async {
    await _ensureAuthenticated();

    final result = await _rpcCall(
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
  Future<bool> addFollower(
    int resId,
    String resModel,
    List<int> partnerIds,
  ) async {
    await _ensureAuthenticated();

    final result = await _rpcCall(
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
  Future<bool> removeFollower(
    int resId,
    String resModel,
    List<int> partnerIds,
  ) async {
    await _ensureAuthenticated();

    final result = await _rpcCall(
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
  Future<List<Map<String, dynamic>>> fetchAttachments(
    int resId,
    String resModel,
  ) async {
    await _ensureAuthenticated();

    final result = await _rpcCall(
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

    final result = await _rpcCall(
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
          },
        ],
        'kwargs': {},
      },
    );

    return result is int ? result : 0;
  }

  Future<Map<String, dynamic>?> _fetchAttachmentForRecord({
    required int attachmentId,
    required int resId,
    required String resModel,
    required List<String> fields,
  }) async {
    final records = await _searchRead(
      model: 'ir.attachment',
      domain: [
        ['id', '=', attachmentId],
        ['res_model', '=', resModel],
        ['res_id', '=', resId],
      ],
      fields: fields,
      limit: 1,
    );

    return records.isEmpty ? null : records.first;
  }

  /// Download an attachment for a given record.
  ///
  /// Access is validated against record ownership via res_model/res_id.
  Future<AttachmentDownloadResult> downloadAttachment({
    required int attachmentId,
    required int resId,
    required String resModel,
  }) async {
    final record = await _fetchAttachmentForRecord(
      attachmentId: attachmentId,
      resId: resId,
      resModel: resModel,
      fields: ['id', 'name', 'mimetype', 'datas'],
    );
    if (record == null) {
      throw Exception('Attachment not found or access denied.');
    }

    final datas = record['datas'];
    if (datas is! String || datas.isEmpty) {
      throw Exception('Attachment data is empty.');
    }

    final normalized = base64.normalize(datas);
    return AttachmentDownloadResult(
      fileName: record['name']?.toString() ?? 'attachment-$attachmentId',
      mimetype: record['mimetype']?.toString(),
      bytes: base64Decode(normalized),
    );
  }

  /// Delete an attachment after validating it belongs to the given record.
  Future<bool> deleteAttachment({
    required int attachmentId,
    required int resId,
    required String resModel,
  }) async {
    final record = await _fetchAttachmentForRecord(
      attachmentId: attachmentId,
      resId: resId,
      resModel: resModel,
      fields: ['id'],
    );
    if (record == null) {
      throw Exception('Attachment not found or access denied.');
    }

    final result = await _rpcCall(
      '/web/dataset/call_kw',
      method: 'call',
      params: {
        'model': 'ir.attachment',
        'method': 'unlink',
        'args': [
          [attachmentId],
        ],
        'kwargs': {},
      },
    );

    return result == true;
  }

  /// Fetch users (salespeople)
  Future<List<Map<String, dynamic>>> fetchUsers() async {
    await _ensureAuthenticated();

    final result = await _rpcCall(
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

    final result = await _rpcCall(
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
