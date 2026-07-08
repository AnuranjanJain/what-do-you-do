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
        ..agent = AgentDesktopSnapshot.disconnected(
          'Test agent disconnected.',
        ).copyWithIntelligenceForTest()
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
      await tester.tap(find.text('Planner').first);
      await tester.pumpAndSettle();
      final pageScroll = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Today 1'),
        500,
        scrollable: pageScroll,
      );
      expect(find.text('Today 1'), findsOneWidget);
      expect(find.text('Week 1'), findsOneWidget);
      expect(find.text('Month 1'), findsOneWidget);
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Week 1'))
          .onSelected
          ?.call(true);
      await tester.pumpAndSettle();
      expect(find.textContaining('This week plan blocks'), findsOneWidget);
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Month 1'))
          .onSelected
          ?.call(true);
      await tester.pumpAndSettle();
      expect(find.textContaining('This month plan blocks'), findsOneWidget);
      expect(tester.takeException(), isNull);
      controller.dispose();
    });
  }
}

extension on AgentDesktopSnapshot {
  AgentDesktopSnapshot copyWithIntelligenceForTest() {
    const block = PlanningBlock(
      eventId: 1,
      title: 'Build FlightIQ demo',
      project: 'FlightIQ',
      eventType: 'hackathon',
      start: '2026-06-14T09:00:00',
      durationMinutes: 90,
      deadline: '2026-06-21T09:00:00',
      nextAction: 'Finish dashboard and video.',
      status: 'planned',
    );
    return AgentDesktopSnapshot(
      baseUrl: baseUrl,
      connected: connected,
      desktop: desktop,
      message: message,
      wellbeingMinutes: wellbeingMinutes,
      activeReminders: activeReminders,
      opportunities: opportunities,
      hackathons: hackathons,
      placements: placements,
      neopat: neopat,
      unreadHackathonUpdates: unreadHackathonUpdates,
      unreadPlacementUpdates: unreadPlacementUpdates,
      unreadNeoPatUpdates: unreadNeoPatUpdates,
      workers: workers,
      reminders: reminders,
      planSummary: planSummary,
      latestOpportunityTitle: latestOpportunityTitle,
      latestActivitySummary: latestActivitySummary,
      intelligence: const IntelligenceSnapshot(
        accounts: 0,
        unreadEmails: 0,
        urgentEmails: 0,
        todaySummary: '',
        todayItems: [],
        weeklySummary: '',
        weeklyItems: [],
        suggestions: [],
        deadlines: [],
        waitingFor: [],
        planningEvents: [],
        planningToday: [],
        planningWeek: [],
        planningMonth: [],
        questionQueue: [],
        planToday: [block],
        planWeek: [block],
        planMonth: [block],
        briefing: PlannerBriefing(
          headline: '',
          todayCount: 0,
          weekCount: 0,
          monthCount: 0,
          needsAnswerCount: 0,
          blockedCount: 0,
          focus: [],
          dueSoon: [],
          askNext: [],
        ),
      ),
      readiness: readiness,
      dataDir: dataDir,
      importsDir: importsDir,
      updatedAt: updatedAt,
    );
  }
}
