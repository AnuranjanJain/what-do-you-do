import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_do_you_do/src/app_controller.dart';
import 'package:what_do_you_do/src/models.dart';
import 'package:what_do_you_do/src/shell.dart';
import 'package:what_do_you_do/src/theme.dart';

void main() {
  for (final size in [const Size(1280, 800), const Size(390, 844)]) {
    testWidgets('applications workspace fits at ${size.width}px', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = AppController()
        ..loading = false
        ..collectorOnline = true
        ..agent = _snapshot();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AppShell(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Applications').first);
      await tester.pumpAndSettle();

      expect(find.text('Career pipeline'.toUpperCase()), findsOneWidget);
      expect(find.text('All 2'), findsOneWidget);
      expect(find.text('No response'), findsWidgets);
      expect(find.text('Archive 1'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final scrollable = find.byType(Scrollable).at(0);
      await tester.scrollUntilVisible(
        find.textContaining('NeuralStack').at(0),
        420,
        scrollable: scrollable,
      );
      expect(find.textContaining('Mail: career@example.com'), findsOneWidget);

      await tester.ensureVisible(find.text('Archive 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive 1'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.textContaining('Old Company').at(0),
        420,
        scrollable: scrollable,
      );
      expect(find.textContaining('Old Company'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final theme in [AppTheme.light, AppTheme.dark]) {
    testWidgets('hackathon intelligence fits in both themes', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = AppController()
        ..loading = false
        ..collectorOnline = true
        ..agent = _snapshot();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(body: HackathonsPage(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hackathon corner'), findsOneWidget);
      expect(find.text('PromptWars'), findsOneWidget);
      expect(find.text('2 days left'), findsOneWidget);
      expect(find.text('hackathons@example.com'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

AgentDesktopSnapshot _snapshot() {
  return AgentDesktopSnapshot.fromJson(
    baseUrl: 'http://127.0.0.1:5050',
    live: {
      'stats': <String, dynamic>{},
      'intelligence': <String, dynamic>{},
      'readiness': <String, dynamic>{},
    },
    desktop: const {'desktop': true},
    workers: const {},
    hackathons: const {},
    placements: const {},
    neopat: const {},
    applications: {
      'stats': {
        'active': 1,
        'archived': 1,
        'total': 2,
        'applied': 2,
        'selected': 1,
        'selected_rate': 50,
        'no_response': 0,
        'no_further_email': 1,
        'awaiting_response': 0,
        'rejected': 1,
        'needs_action': 1,
        'next_steps': 1,
        'offers': 0,
        'emails_scanned': 200,
        'emails_available': 200,
        'scan_limit': 500,
        'accounts': 2,
        'accounts_scanned': 2,
      },
      'active': [
        {
          'id': 'neural-stack',
          'company': 'NeuralStack',
          'role': 'Backend Intern',
          'roles': ['Backend Intern'],
          'stage': 'interview',
          'stage_label': 'Interview scheduled',
          'response_status': 'selected',
          'response_label': 'Selected / next round',
          'selected_for_next_step': true,
          'needs_action': true,
          'has_further_email': true,
          'mail_count': 2,
          'days_waiting': 6,
          'confidence': 0.94,
          'applied_at': '2026-07-12T09:00:00',
          'latest_activity_at': '2026-07-18T09:00:00',
          'deadline': '2026-07-20T09:00:00',
          'days_left': 2,
          'platform': 'LinkedIn',
          'platforms': ['LinkedIn'],
          'source_accounts': ['career@example.com'],
          'source_email': {
            'id': 10,
            'account_email': 'career@example.com',
            'sender': 'recruiting@neuralstack.example',
            'subject': 'Backend interview scheduled',
            'received_at': '2026-07-18T09:00:00',
            'platform': 'LinkedIn',
          },
          'source_emails': <Map<String, dynamic>>[],
          'summary': 'The recruiter scheduled the technical interview.',
          'next_action': 'Prepare the project walkthrough.',
          'timeline': <Map<String, dynamic>>[],
          'project': {
            'id': 1,
            'title': 'FlightIQ',
            'progress': 68,
            'repository': 'https://github.com/example/flightiq',
            'working_directory': r'C:\Projects\FlightIQ',
            'next_action': 'Finish the dashboard.',
            'signals': ['local_workspace', 'github'],
          },
          'archived': false,
        },
      ],
      'archive': [
        {
          'id': 'old-company',
          'company': 'Old Company',
          'role': 'Software Intern',
          'roles': ['Software Intern'],
          'stage': 'rejected',
          'stage_label': 'Closed / rejected',
          'response_status': 'rejected',
          'response_label': 'Closed / rejected',
          'selected_for_next_step': false,
          'needs_action': false,
          'has_further_email': true,
          'mail_count': 2,
          'days_waiting': 18,
          'confidence': 0.91,
          'applied_at': '2025-01-02T09:00:00',
          'latest_activity_at': '2025-01-20T09:00:00',
          'platform': 'Company website',
          'platforms': ['Company website'],
          'source_accounts': ['career@example.com'],
          'source_emails': <Map<String, dynamic>>[],
          'summary': 'Application closed.',
          'next_action': 'Keep useful feedback.',
          'timeline': <Map<String, dynamic>>[],
          'archived': true,
        },
      ],
      'today': <Map<String, dynamic>>[],
      'due_soon': <Map<String, dynamic>>[],
      'hackathons': {
        'stats': {
          'total': 1,
          'discovered': 0,
          'applied': 1,
          'building': 1,
          'submitted': 0,
          'selected': 0,
          'won': 0,
          'due_soon': 1,
        },
        'items': <Map<String, dynamic>>[
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
      'updated_at': '2026-07-18T09:00:00',
    },
  );
}
