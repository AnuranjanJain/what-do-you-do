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

  test(
    'application intelligence parses grouped company and source email',
    () async {
      final client = MockClient((request) async {
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
            'stats': <String, dynamic>{},
            'intelligence': <String, dynamic>{},
            'readiness': <String, dynamic>{},
          });
        }
        if (request.url.path == '/api/applications') {
          return jsonResponse({
            'stats': {
              'active': 1,
              'archived': 0,
              'emails_scanned': 100,
              'accounts': 2,
            },
            'active': [
              {
                'id': 'example',
                'company': 'Example',
                'role': 'Software Intern',
                'roles': ['Software Intern'],
                'stage': 'assessment',
                'stage_label': 'Assessment / test',
                'selected_for_next_step': true,
                'needs_action': true,
                'platform': 'LinkedIn',
                'platforms': ['LinkedIn'],
                'source_accounts': ['jobs@example.com'],
                'source_email': {
                  'id': 7,
                  'account_email': 'jobs@example.com',
                  'sender': 'recruiter@example.com',
                  'subject': 'Assessment invitation',
                  'received_at': '2026-07-18T09:00:00',
                  'platform': 'LinkedIn',
                },
              },
            ],
          });
        }
        return jsonResponse(<String, dynamic>{});
      });
      final api = AgentDesktopApi(
        client: client,
        candidateBaseUrls: const [baseUrl],
      );

      final snapshot = await api.snapshot();

      expect(snapshot.applications.active, hasLength(1));
      expect(snapshot.applications.active.first.company, 'Example');
      expect(
        snapshot.applications.active.first.sourceEmail?.accountEmail,
        'jobs@example.com',
      );
      expect(snapshot.placements, 1);
    },
  );
}

http.Response jsonResponse(Object body) {
  return http.Response(
    jsonEncode(body),
    200,
    headers: const {'content-type': 'application/json'},
  );
}
