import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/core/services/mobile_backend_adapter.dart';

void main() {
  group('MobileBackendAdapter', () {
    test('rejects non-whitelisted path', () async {
      final adapter = MobileBackendAdapter.test(httpClient: _FakeClient([]));
      adapter.updateConfig('https://odoo.example.com', null);

      expect(
        () => adapter.call(
          path: '/web/unknown',
          method: 'call',
          params: {'model': 'crm.lead', 'method': 'search_read'},
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('retries idempotent reads on transient status', () async {
      final fakeClient = _FakeClient([
        _FakeReply(
          response: http.Response(
            '{"error":{"message":"Too many requests"}}',
            429,
            headers: {'retry-after': '0'},
          ),
        ),
        _FakeReply(response: http.Response('{"result":[{"id":1}]}', 200)),
      ]);
      final delays = <Duration>[];
      final adapter = MobileBackendAdapter.test(
        httpClient: fakeClient,
        sleep: (duration) async => delays.add(duration),
      );
      adapter.updateConfig('https://odoo.example.com', 'session');

      final result = await adapter.call(
        path: '/web/dataset/call_kw',
        method: 'call',
        params: {'model': 'crm.lead', 'method': 'search_read'},
      );

      expect(result['result'], isNotNull);
      expect(fakeClient.requestCount, 2);
      expect(delays, isNotEmpty);
    });

    test('does not retry mutating writes', () async {
      final fakeClient = _FakeClient([
        _FakeReply(
          response: http.Response(
            '{"error":{"message":"Service unavailable"}}',
            503,
          ),
        ),
      ]);
      final adapter = MobileBackendAdapter.test(httpClient: fakeClient);
      adapter.updateConfig('https://odoo.example.com', 'session');

      await expectLater(
        () => adapter.call(
          path: '/web/dataset/call_kw',
          method: 'call',
          params: {'model': 'crm.lead', 'method': 'create'},
        ),
        throwsException,
      );
      expect(fakeClient.requestCount, 1);
    });

    test('captures session id from cookie during auth', () async {
      final adapter = MobileBackendAdapter.test(
        httpClient: _FakeClient([
          _FakeReply(
            response: http.Response(
              '{"result":{"uid":5,"name":"Demo","username":"demo"}}',
              200,
              headers: {'set-cookie': 'session_id=abc123; Path=/; HttpOnly'},
            ),
          ),
        ]),
      );

      final auth = await adapter.authenticate(
        rawBaseUrl: 'https://odoo.example.com',
        db: 'odoo',
        login: 'demo',
        password: 'demo',
      );

      expect(auth.uid, 5);
      expect(auth.sessionId, 'abc123');
      expect(adapter.sessionId, 'abc123');
    });
  });
}

class _FakeReply {
  final http.Response? response;

  const _FakeReply({this.response});
}

class _FakeClient extends http.BaseClient {
  final List<_FakeReply> _replies;
  int requestCount = 0;

  _FakeClient(this._replies);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requestCount++;
    if (_replies.isEmpty) {
      throw StateError('No fake responses left');
    }
    final current = _replies.removeAt(0);
    final response = current.response!;
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
      request: request,
    );
  }
}
