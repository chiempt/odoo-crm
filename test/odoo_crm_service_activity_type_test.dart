import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/core/services/odoo_crm_service.dart';

void main() {
  group('OdooCrmService activity type resolution', () {
    test('resolves activity type by semantic key for create flow', () async {
      final backend = _FakeBackend();
      final service = _buildService(backend.call);

      final createdId = await service.createActivity(
        leadId: 15,
        summary: 'Follow-up call',
        dateDeadline: '2026-03-25',
        activityTypeKey: 'call',
      );

      expect(createdId, 101);
      expect(backend.searchReadCallsByModel['mail.activity.type'], 1);
      expect(backend.lastCreateActivityValues?['activity_type_id'], 42);
    });

    test('reuses cached type mapping across activity creates', () async {
      final backend = _FakeBackend();
      final service = _buildService(backend.call);

      await service.createActivity(
        leadId: 15,
        summary: 'Call 1',
        dateDeadline: '2026-03-25',
        activityTypeKey: 'call',
      );
      await service.createActivity(
        leadId: 16,
        summary: 'Call 2',
        dateDeadline: '2026-03-26',
        activityTypeKey: 'call',
      );

      expect(backend.searchReadCallsByModel['mail.activity.type'], 1);
    });

    test(
      'keeps explicit activity type id for edit/update style flow',
      () async {
        final backend = _FakeBackend();
        final service = _buildService(backend.call);

        final createdId = await service.createActivity(
          leadId: 22,
          summary: 'Preserve mapped id',
          dateDeadline: '2026-03-25',
          activityTypeId: 99,
          activityTypeKey: 'call',
        );

        expect(createdId, 101);
        expect(backend.searchReadCallsByModel['mail.activity.type'] ?? 0, 0);
        expect(backend.lastCreateActivityValues?['activity_type_id'], 99);
      },
    );
  });
}

OdooCrmService _buildService(OdooRpcCall rpcCall) {
  return OdooCrmService.test(
    rpcCall: rpcCall,
    getDatabase: () async => 'odoo_db',
    getUid: () async => 7,
    getToken: () async => 'token',
  );
}

class _FakeBackend {
  final Map<String, int> searchReadCallsByModel = {};
  Map<String, dynamic>? lastCreateActivityValues;

  Future<dynamic> call(
    String path, {
    required String method,
    required Map<String, dynamic> params,
  }) async {
    expect(path, '/web/dataset/call_kw');
    expect(method, 'call');

    final model = params['model'] as String;
    final rpcMethod = params['method'] as String;

    if (rpcMethod == 'search_read') {
      searchReadCallsByModel[model] = (searchReadCallsByModel[model] ?? 0) + 1;
      if (model == 'mail.activity.type') {
        final args = params['args'] as List<dynamic>;
        final domain = args.first as List<dynamic>;
        final hasNameFilter =
            domain.isNotEmpty && domain.first is List<dynamic>;
        if (hasNameFilter) {
          final name = (domain.first as List<dynamic>)[2]
              .toString()
              .toLowerCase();
          if (name == 'call') {
            return [
              {'id': 42, 'name': 'Call'},
            ];
          }
          return [];
        }
        return [
          {'id': 5},
        ];
      }
      return [];
    }

    if (model == 'mail.activity' && rpcMethod == 'create') {
      final args = params['args'] as List<dynamic>;
      lastCreateActivityValues = Map<String, dynamic>.from(args.first as Map);
      return 101;
    }

    return [];
  }
}
