import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_do_you_do/src/app_controller.dart';
import 'package:what_do_you_do/src/models.dart';
import 'package:what_do_you_do/src/shell.dart';
import 'package:what_do_you_do/src/theme.dart';

void main() {
  for (final size in [const Size(1280, 800), const Size(390, 844)]) {
    testWidgets('dashboard has no layout exceptions at ${size.width}px', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = AppController()
        ..loading = false
        ..collectorOnline = true
        ..selectedDate = '2026-06-14'
        ..activeDate = '2026-06-14'
        ..sessions = const [
          ActivitySession(
            id: 'coding',
            startTime: '09:00',
            endTime: '09:42',
            appName: 'VS Code',
            category: ActivityCategory.coding,
            subcategory: 'Building the Flutter client',
            durationMinutes: 42,
            confidence: 91,
            signalSources: ['active-app'],
          ),
          ActivitySession(
            id: 'research',
            startTime: '09:45',
            endTime: '10:10',
            appName: 'Chrome',
            category: ActivityCategory.browsing,
            subcategory: 'Reading documentation',
            durationMinutes: 25,
            confidence: 82,
            signalSources: ['browser-domain'],
          ),
        ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AppShell(controller: controller),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Welcome back.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      controller.dispose();
    });
  }
}
