import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:what_do_you_do/src/agent_desktop_api.dart';

void main() {
  const baseUrl = 'http://127.0.0.1:5999';

  test('one optional HTML response does not disconnect AiOS', () async {
    final requestedPaths = <String>[];
    final client = MockClient((request) async {
      requestedPaths.add(request.url.path);
      if (request.url.path == '/api/local/pairing') {
        return jsonResponse({
          'ok': true,
          'service': 'aios-assistant',
          'base_url': baseUrl,
          'api_token': 'test-token',
        });
      }
      if (request.url.path == '/api/live') {
        return jsonResponse({
          'stats': {'wellbeing_minutes': 45},
          'intelligence': <String, dynamic>{},
          'readiness': <String, dynamic>{},
        });
      }
      if (request.url.path == '/api/college/pat') {
        return http.Response('\n<!doctype html><title>Restarting</title>', 200);
      }
      return jsonResponse(<String, dynamic>{});
    });
    final api = AgentDesktopApi(
      client: client,
      candidateBaseUrls: const [baseUrl],
    );

    final snapshot = await api.snapshot();

    expect(requestedPaths, contains('/api/live'));
    expect(snapshot.connected, isTrue);
    expect(snapshot.wellbeingMinutes, 45);
    expect(snapshot.message, contains('1 optional feed'));
    expect(snapshot.college.emailsScanned, 0);
  });

  test('core HTML response names the failing AiOS endpoint', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/local/pairing') {
        return jsonResponse({
          'ok': true,
          'service': 'aios-assistant',
          'base_url': baseUrl,
          'api_token': 'test-token',
        });
      }
      return http.Response('<!doctype html><title>Wrong service</title>', 200);
    });
    final api = AgentDesktopApi(
      client: client,
      candidateBaseUrls: const [baseUrl],
    );

    await expectLater(
      api.snapshot(),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('/api/live returned a web page'),
        ),
      ),
    );
  });
}

http.Response jsonResponse(Object body) {
  return http.Response(
    jsonEncode(body),
    200,
    headers: const {'content-type': 'application/json'},
  );
}
