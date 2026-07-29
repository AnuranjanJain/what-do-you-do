import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:what_do_you_do/src/agent_desktop_api.dart';
import 'package:what_do_you_do/src/models.dart';

void main() {
  const baseUrl = 'http://127.0.0.1:5999';

  test(
    'runtime descriptor and consolidated snapshot use one fast request',
    () async {
      final tempDir = await Directory.systemTemp.createTemp('wdyd-aios-fast-');
      addTearDown(() => tempDir.delete(recursive: true));
      final runtimeFile = File('${tempDir.path}\\runtime.json');
      final cacheFile = File('${tempDir.path}\\snapshot.json');
      await runtimeFile.writeAsString(
        jsonEncode({
          'service': 'aios-assistant',
          'base_url': baseUrl,
          'api_token': 'runtime-token',
          'snapshot_path': '/api/wdyd/snapshot',
        }),
      );
      final requestedPaths = <String>[];
      final client = MockClient((request) async {
        requestedPaths.add(request.url.path);
        expect(request.headers['X-AiOS-Token'], 'runtime-token');
        return jsonResponse(unifiedSnapshot(wellbeingMinutes: 75));
      });
      final api = AgentDesktopApi(
        client: client,
        runtimeDescriptorFile: runtimeFile,
        snapshotCacheFile: cacheFile,
        candidateBaseUrls: const [baseUrl],
      );

      final snapshot = await api.snapshot();

      expect(requestedPaths, ['/api/wdyd/snapshot']);
      expect(snapshot.connected, isTrue);
      expect(snapshot.stale, isFalse);
      expect(snapshot.wellbeingMinutes, 75);
      expect(await cacheFile.exists(), isTrue);
    },
  );

  test(
    'last private snapshot remains visible during an AiOS restart',
    () async {
      final tempDir = await Directory.systemTemp.createTemp('wdyd-aios-cache-');
      addTearDown(() => tempDir.delete(recursive: true));
      final cacheFile = File('${tempDir.path}\\snapshot.json');
      final onlineApi = AgentDesktopApi(
        client: MockClient((request) async {
          if (request.url.path == '/api/local/pairing') {
            return jsonResponse({
              'ok': true,
              'service': 'aios-assistant',
              'base_url': baseUrl,
              'api_token': 'test-token',
              'snapshot_path': '/api/wdyd/snapshot',
            });
          }
          return jsonResponse(unifiedSnapshot(wellbeingMinutes: 92));
        }),
        candidateBaseUrls: const [baseUrl],
        snapshotCacheFile: cacheFile,
      );
      final live = await onlineApi.snapshot();
      onlineApi.close();
      expect(live.stale, isFalse);

      final offlineApi = AgentDesktopApi(
        client: MockClient((_) async => throw const SocketException('offline')),
        candidateBaseUrls: const [baseUrl],
        snapshotCacheFile: cacheFile,
        discoveryTimeout: const Duration(milliseconds: 20),
      );

      final cached = await offlineApi.snapshot();

      expect(cached.connected, isTrue);
      expect(cached.stale, isTrue);
      expect(cached.wellbeingMinutes, 92);
      expect(cached.message, contains('last private snapshot'));
    },
  );

  test('failed planner writes are never replayed automatically', () async {
    var writeCount = 0;
    final api = AgentDesktopApi(
      client: MockClient((request) async {
        if (request.url.path == '/api/local/pairing') {
          return jsonResponse({
            'ok': true,
            'service': 'aios-assistant',
            'base_url': baseUrl,
            'api_token': 'test-token',
          });
        }
        writeCount += 1;
        return http.Response('temporary failure', 500);
      }),
      candidateBaseUrls: const [baseUrl],
    );

    await expectLater(
      api.createPlanningEvent(
        const PlanningEventDraft(
          eventType: 'task',
          title: 'Prepare interview notes',
          project: 'Career',
          idea: '',
          deadline: '',
          plannedStart: '',
          plannedMinutes: 30,
          workDone: '',
          workLeft: 'Prepare examples',
          repoUrl: '',
        ),
      ),
      throwsA(isA<Exception>()),
    );
    expect(writeCount, 1);
  });

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
              'total': 1,
              'applied': 1,
              'selected': 1,
              'selected_rate': 100,
              'no_response': 0,
              'no_further_email': 0,
              'awaiting_response': 0,
              'rejected': 0,
              'active': 1,
              'archived': 0,
              'emails_scanned': 500,
              'emails_available': 649,
              'scan_limit': 500,
              'accounts': 2,
            },
            'hackathons': {
              'stats': {
                'total': 3,
                'applied': 2,
                'selected': 1,
                'building': 1,
                'submitted': 1,
                'won': 0,
              },
              'items': [
                {
                  'id': 'promptwars',
                  'title': 'PromptWars',
                  'stage': 'building',
                  'stage_label': 'Building',
                  'platforms': ['Hack2Skill'],
                  'source_accounts': ['hackathons@example.com'],
                  'mail_count': 4,
                  'deadline': '2026-07-31T23:59:00',
                  'days_left': 2,
                  'latest_activity_at': '2026-07-29T08:00:00',
                  'summary': 'Two days remain to finish and submit the build.',
                },
              ],
            },
            'active': [
              {
                'id': 'example',
                'company': 'Example',
                'role': 'Software Intern',
                'roles': ['Software Intern'],
                'stage': 'assessment',
                'stage_label': 'Assessment / test',
                'response_status': 'selected',
                'response_label': 'Selected',
                'selected_for_next_step': true,
                'has_further_email': true,
                'mail_count': 3,
                'days_waiting': 1,
                'confidence': 0.92,
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
      expect(snapshot.applications.stats.applied, 1);
      expect(snapshot.applications.stats.selected, 1);
      expect(snapshot.applications.stats.selectedRate, 100);
      expect(snapshot.applications.stats.emailsScanned, 500);
      expect(snapshot.applications.active.first.responseStatus, 'selected');
      expect(snapshot.applications.active.first.mailCount, 3);
      expect(snapshot.applications.hackathons.stats.total, 3);
      expect(snapshot.applications.hackathons.stats.selected, 1);
      expect(snapshot.applications.hackathons.items.single.title, 'PromptWars');
      expect(snapshot.applications.hackathons.items.single.daysLeft, 2);
      expect(
        snapshot.applications.hackathons.items.single.sourceAccounts.single,
        'hackathons@example.com',
      );
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

Map<String, dynamic> unifiedSnapshot({required int wellbeingMinutes}) {
  return {
    'ok': true,
    'service': 'aios-assistant',
    'schema_version': 1,
    'generated_at': '2026-07-21T12:00:00Z',
    'live': {
      'stats': {'wellbeing_minutes': wellbeingMinutes},
      'intelligence': <String, dynamic>{},
      'readiness': <String, dynamic>{},
      'updated_at': '2026-07-21T12:00:00Z',
    },
    'desktop': {'desktop': true},
    'workers': {'items': <dynamic>[]},
    'hackathons': <String, dynamic>{},
    'placements': <String, dynamic>{},
    'applications': <String, dynamic>{},
    'neopat': <String, dynamic>{},
    'projects': <String, dynamic>{},
    'college': <String, dynamic>{},
  };
}
