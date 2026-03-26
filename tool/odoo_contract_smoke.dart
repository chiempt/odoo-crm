import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

const _ok = '[OK]';
const _info = '[INFO]';
const _fail = '[FAIL]';

void main() async {
  final baseUrl = _requireEnv('ODOO_SMOKE_BASE_URL');
  final database = _requireEnv('ODOO_SMOKE_DB');
  final login = _requireEnv('ODOO_SMOKE_LOGIN');
  final password = _requireEnv('ODOO_SMOKE_PASSWORD');

  final client = OdooSmokeClient(
    baseUrl: baseUrl,
    database: database,
    login: login,
    password: password,
  );

  int? leadId;
  try {
    stdout.writeln('$_info Authenticating to $baseUrl ($database)...');
    await client.authenticate();
    stdout.writeln('$_ok Login');

    final token = DateTime.now().millisecondsSinceEpoch;
    final leadName = 'Smoke Lead #$token';
    final updatedLeadName = '$leadName [updated]';

    leadId = await client.createLead(leadName);
    stdout.writeln('$_ok Lead create (id=$leadId)');

    final createdLead = await client.readLead(leadId);
    _expect(createdLead != null, 'Lead read');
    stdout.writeln('$_ok Lead read');

    final stageChanged = await client.changeLeadStage(leadId);
    _expect(stageChanged, 'Lead stage change');
    stdout.writeln('$_ok Lead stage change');

    final activityId = await client.createActivity(
      leadId: leadId,
      summary: 'Smoke activity $token',
      note: 'Activity from contract smoke test',
    );
    _expect(activityId > 0, 'Activity create');
    stdout.writeln('$_ok Activity create (id=$activityId)');

    final messageId = await client.postMessage(
      leadId: leadId,
      body: 'Smoke chatter note $token',
    );
    _expect(messageId > 0, 'Chatter note post');
    stdout.writeln('$_ok Chatter note post (id=$messageId)');

    final attachmentId = await client.uploadAttachment(
      leadId: leadId,
      fileName: 'smoke-$token.txt',
      content: 'contract-smoke:$token',
    );
    _expect(attachmentId > 0, 'Attachment upload');

    final attachments = await client.listAttachments(leadId);
    _expect(
      attachments.any((attachment) => attachment['id'] == attachmentId),
      'Attachment list',
    );
    stdout.writeln('$_ok Attachment upload/list (id=$attachmentId)');

    final downloadedBytes = await client.downloadAttachment(attachmentId);
    _expect(
      utf8.decode(downloadedBytes) == 'contract-smoke:$token',
      'Attachment download',
    );
    stdout.writeln('$_ok Attachment download');

    final attachmentDeleted = await client.deleteAttachment(attachmentId);
    _expect(attachmentDeleted, 'Attachment delete');

    final attachmentsAfterDelete = await client.listAttachments(leadId);
    _expect(
      !attachmentsAfterDelete.any(
        (attachment) => attachment['id'] == attachmentId,
      ),
      'Attachment delete verification',
    );
    stdout.writeln('$_ok Attachment delete');

    final updated = await client.updateLeadName(leadId, updatedLeadName);
    _expect(updated, 'Lead update');
    stdout.writeln('$_ok Lead update');

    final deleted = await client.deleteLead(leadId);
    _expect(deleted, 'Lead delete');
    leadId = null;

    final stillExists = await client.leadExistsByName(updatedLeadName);
    _expect(!stillExists, 'Lead deletion verification');
    stdout.writeln('$_ok Lead delete');

    stdout.writeln('');
    stdout.writeln('$_ok Contract smoke test PASSED');
  } catch (error, stackTrace) {
    stderr.writeln('$_fail Contract smoke test failed: $error');
    stderr.writeln(stackTrace);
    exitCode = 1;
  } finally {
    if (leadId != null) {
      try {
        await client.deleteLead(leadId);
        stdout.writeln('$_info Cleanup: deleted leftover lead $leadId');
      } catch (_) {
        stderr.writeln('$_fail Cleanup failed for lead $leadId');
      }
    }
    await client.close();
  }
}

String _requireEnv(String key) {
  final value = Platform.environment[key];
  if (value == null || value.trim().isEmpty) {
    stderr.writeln('Missing required env var: $key');
    exit(64);
  }
  return value.trim();
}

void _expect(bool condition, String step) {
  if (!condition) {
    throw StateError('Step failed: $step');
  }
}

class OdooSmokeClient {
  OdooSmokeClient({
    required this.baseUrl,
    required this.database,
    required this.login,
    required this.password,
  });

  final String baseUrl;
  final String database;
  final String login;
  final String password;
  final http.Client _http = http.Client();

  String? _sessionId;

  Future<void> authenticate() async {
    final payload = {
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {'db': database, 'login': login, 'password': password},
      'id': DateTime.now().millisecondsSinceEpoch,
    };
    final response = await _http.post(
      _uri('/web/session/authenticate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    final data = _decodeJson(response);
    _assertNoError(data);
    final result = data['result'] as Map<String, dynamic>?;
    final uid = result?['uid'];
    if (uid is! int) {
      throw StateError('Authentication returned invalid uid: $uid');
    }

    final bodySession = result?['session_id'];
    if (bodySession is String && bodySession.isNotEmpty) {
      _sessionId = bodySession;
    } else {
      _sessionId = _extractSessionId(response.headers);
    }

    if (_sessionId == null || _sessionId!.isEmpty) {
      throw StateError('Authentication succeeded without session_id cookie');
    }
  }

  Future<int> createLead(String leadName) async {
    final result = await _callKw(
      model: 'crm.lead',
      method: 'create',
      args: [
        {
          'name': leadName,
          'type': 'lead',
          'description': 'Created by contract smoke test',
          'email_from': 'smoke.test@example.com',
          'contact_name': 'Smoke Contract Bot',
        },
      ],
    );
    return _asInt(result, 'crm.lead.create');
  }

  Future<Map<String, dynamic>?> readLead(int leadId) async {
    final result = await _callKw(
      model: 'crm.lead',
      method: 'read',
      args: [
        [leadId],
      ],
      kwargs: {
        'fields': ['id', 'name', 'stage_id', 'write_date'],
      },
    );
    final records = (result as List).cast<Map<String, dynamic>>();
    return records.isEmpty ? null : records.first;
  }

  Future<bool> changeLeadStage(int leadId) async {
    final stagesRaw = await _callKw(
      model: 'crm.stage',
      method: 'search_read',
      args: [[]],
      kwargs: {
        'fields': ['id', 'sequence', 'name'],
        'order': 'sequence asc,id asc',
      },
    );
    final stages = (stagesRaw as List).cast<Map<String, dynamic>>();
    if (stages.isEmpty) {
      throw StateError('No crm.stage records found');
    }

    final current = await readLead(leadId);
    final currentStageRef = current?['stage_id'];
    final currentStageId = _extractMany2OneId(currentStageRef);

    final targetStageId = stages
        .map((stage) => stage['id'])
        .whereType<int>()
        .firstWhere(
          (stageId) => stageId != currentStageId,
          orElse: () => currentStageId ?? stages.first['id'] as int,
        );

    final result = await _callKw(
      model: 'crm.lead',
      method: 'write',
      args: [
        [leadId],
        {'stage_id': targetStageId},
      ],
    );
    return result == true;
  }

  Future<int> createActivity({
    required int leadId,
    required String summary,
    required String note,
  }) async {
    final activityTypeId = await _resolveActivityTypeId();
    final deadline = DateTime.now().add(const Duration(days: 1));
    final deadlineDate =
        '${deadline.year.toString().padLeft(4, '0')}-'
        '${deadline.month.toString().padLeft(2, '0')}-'
        '${deadline.day.toString().padLeft(2, '0')}';

    final result = await _callKw(
      model: 'mail.activity',
      method: 'create',
      args: [
        {
          'res_model': 'crm.lead',
          'res_id': leadId,
          'summary': summary,
          'note': note,
          'activity_type_id': activityTypeId,
          'date_deadline': deadlineDate,
        },
      ],
    );
    return _asInt(result, 'mail.activity.create');
  }

  Future<int> postMessage({required int leadId, required String body}) async {
    final result = await _callKw(
      model: 'crm.lead',
      method: 'message_post',
      args: [
        [leadId],
      ],
      kwargs: {'body': body, 'message_type': 'comment'},
    );
    return _asInt(result, 'crm.lead.message_post');
  }

  Future<int> uploadAttachment({
    required int leadId,
    required String fileName,
    required String content,
  }) async {
    final result = await _callKw(
      model: 'ir.attachment',
      method: 'create',
      args: [
        {
          'name': fileName,
          'datas': base64Encode(utf8.encode(content)),
          'res_model': 'crm.lead',
          'res_id': leadId,
          'type': 'binary',
          'mimetype': 'text/plain',
        },
      ],
    );
    return _asInt(result, 'ir.attachment.create');
  }

  Future<List<Map<String, dynamic>>> listAttachments(int leadId) async {
    final result = await _callKw(
      model: 'ir.attachment',
      method: 'search_read',
      args: [
        [
          ['res_model', '=', 'crm.lead'],
          ['res_id', '=', leadId],
        ],
      ],
      kwargs: {
        'fields': ['id', 'name', 'mimetype', 'file_size'],
      },
    );
    return (result as List).cast<Map<String, dynamic>>();
  }

  Future<Uint8List> downloadAttachment(int attachmentId) async {
    final result = await _callKw(
      model: 'ir.attachment',
      method: 'read',
      args: [
        [attachmentId],
      ],
      kwargs: {
        'fields': ['id', 'name', 'datas'],
      },
    );
    final rows = (result as List).cast<Map<String, dynamic>>();
    if (rows.isEmpty) {
      throw StateError('Attachment not found: $attachmentId');
    }
    final datas = rows.first['datas'];
    if (datas is! String || datas.isEmpty) {
      throw StateError('Attachment data missing: $attachmentId');
    }
    return base64Decode(base64.normalize(datas));
  }

  Future<bool> deleteAttachment(int attachmentId) async {
    final result = await _callKw(
      model: 'ir.attachment',
      method: 'unlink',
      args: [
        [attachmentId],
      ],
    );
    return result == true;
  }

  Future<bool> updateLeadName(int leadId, String updatedName) async {
    final result = await _callKw(
      model: 'crm.lead',
      method: 'write',
      args: [
        [leadId],
        {'name': updatedName},
      ],
    );
    return result == true;
  }

  Future<bool> deleteLead(int leadId) async {
    final result = await _callKw(
      model: 'crm.lead',
      method: 'unlink',
      args: [
        [leadId],
      ],
    );
    return result == true;
  }

  Future<bool> leadExistsByName(String leadName) async {
    final result = await _callKw(
      model: 'crm.lead',
      method: 'search_count',
      args: [
        [
          ['name', '=', leadName],
        ],
      ],
    );
    final count = _asInt(result, 'crm.lead.search_count');
    return count > 0;
  }

  Future<int> _resolveActivityTypeId() async {
    final result = await _callKw(
      model: 'mail.activity.type',
      method: 'search_read',
      args: [[]],
      kwargs: {
        'fields': ['id', 'name'],
        'limit': 1,
        'order': 'id asc',
      },
    );
    final rows = (result as List).cast<Map<String, dynamic>>();
    if (rows.isEmpty) {
      throw StateError('No activity type available in mail.activity.type');
    }
    final id = rows.first['id'];
    if (id is! int) {
      throw StateError('Invalid activity type id: $id');
    }
    return id;
  }

  Future<dynamic> _callKw({
    required String model,
    required String method,
    required List<dynamic> args,
    Map<String, dynamic>? kwargs,
  }) async {
    if (_sessionId == null || _sessionId!.isEmpty) {
      throw StateError('Session not established. Call authenticate first.');
    }

    final payload = {
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'model': model,
        'method': method,
        'args': args,
        'kwargs': kwargs ?? <String, dynamic>{},
      },
      'id': DateTime.now().millisecondsSinceEpoch,
    };

    final response = await _http.post(
      _uri('/web/dataset/call_kw'),
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'session_id=$_sessionId',
        'X-Openerp-Session-Id': _sessionId!,
      },
      body: jsonEncode(payload),
    );

    final data = _decodeJson(response);
    _assertNoError(data);
    return data['result'];
  }

  Uri _uri(String path) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath');
  }

  Map<String, dynamic> _decodeJson(http.Response response) {
    if (response.statusCode != 200) {
      throw HttpException(
        'HTTP ${response.statusCode}: ${response.body}',
        uri: response.request?.url,
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Unexpected response body: ${response.body}');
    }
    return decoded;
  }

  void _assertNoError(Map<String, dynamic> payload) {
    final error = payload['error'];
    if (error != null) {
      throw StateError('Odoo RPC error: $error');
    }
  }

  String? _extractSessionId(Map<String, String> headers) {
    final rawCookie = headers.entries
        .where((entry) => entry.key.toLowerCase() == 'set-cookie')
        .map((entry) => entry.value)
        .join(';');
    final match = RegExp(r'session_id=([^;]+)').firstMatch(rawCookie);
    return match?.group(1);
  }

  int _asInt(dynamic value, String label) {
    if (value is int) return value;
    throw StateError('Expected int from $label, got: $value');
  }

  int? _extractMany2OneId(dynamic value) {
    if (value is int) return value;
    if (value is List && value.isNotEmpty && value.first is int) {
      return value.first as int;
    }
    return null;
  }

  Future<void> close() async {
    _http.close();
  }
}
