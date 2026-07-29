import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_do_you_do/src/app_controller.dart';
import 'package:what_do_you_do/src/models.dart';
import 'package:what_do_you_do/src/shell.dart';
import 'package:what_do_you_do/src/theme.dart';

void main() {
  for (final size in [const Size(1280, 800), const Size(390, 844)]) {
    testWidgets('AiOS reconnecting state fits at ${size.width}px', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = AppController()
        ..loading = false
        ..agent = _liveSnapshot().asStale('The local core is restarting.');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: AgentPage(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reconnecting to AiOS Desktop'), findsOneWidget);
      expect(find.text('Saved locally'), findsNothing);
      expect(find.byTooltip('Open AiOS Desktop'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
}

AgentDesktopSnapshot _liveSnapshot() {
  return AgentDesktopSnapshot.fromJson(
    baseUrl: 'http://127.0.0.1:5050',
    live: {
      'stats': {'active_reminders': 4, 'opportunities': 12},
      'intelligence': <String, dynamic>{},
      'readiness': <String, dynamic>{},
      'updated_at': '2026-07-21T12:00:00Z',
    },
    desktop: const {'desktop': true},
    workers: const {'items': <dynamic>[]},
    hackathons: const {},
    placements: const {},
    neopat: const {},
  );
}
