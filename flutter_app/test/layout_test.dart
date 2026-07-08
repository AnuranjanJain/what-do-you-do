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
        find.textContaining('Today plan blocks'),
        500,
        scrollable: pageScroll,
      );
      expect(find.text('Today 1'), findsWidgets);
      expect(find.text('Week 1'), findsWidgets);
      expect(find.text('Month 1'), findsOneWidget);
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Week 1').first)
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
      await tester.scrollUntilVisible(
        find.text('Questions 1'),
        500,
        scrollable: pageScroll,
      );
      expect(find.text('All 2'), findsOneWidget);
      expect(find.text('Today 1'), findsWidgets);
      expect(find.text('Week 1'), findsWidgets);
      expect(find.text('Month 2'), findsOneWidget);
      tester
          .widget<ChoiceChip>(
            find.widgetWithText(ChoiceChip, 'Questions 1').last,
          )
          .onSelected
          ?.call(true);
      await tester.pumpAndSettle();
      expect(find.text('Build FlightIQ demo'), findsWidgets);
      expect(find.text('Refactor portfolio repo'), findsNothing);
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
    const hackathonEvent = PlanningEventSummary(
      id: 1,
      eventType: 'hackathon',
      source: 'hackathon',
      title: 'Build FlightIQ demo',
      project: 'FlightIQ',
      idea: 'Prioritize traveler actions.',
      deadline: '2026-06-21T09:00:00',
      plannedStart: '2026-06-14T09:00:00',
      plannedMinutes: 90,
      status: 'planned',
      workDone: 'Repo initialized.',
      workLeft: 'Finish dashboard and video.',
      repoUrl: '',
      repoLatestActivity: '',
      nextQuestion: 'What changed in FlightIQ?',
      lastProgressNote: '',
      progressLog: [],
    );
    const repoEvent = PlanningEventSummary(
      id: 2,
      eventType: 'repo',
      source: 'manual',
      title: 'Refactor portfolio repo',
      project: 'Portfolio',
      idea: 'Clean project cards.',
      deadline: '2026-06-30T09:00:00',
      plannedStart: '2026-06-20T14:00:00',
      plannedMinutes: 60,
      status: 'planned',
      workDone: '',
      workLeft: 'Ship README polish.',
      repoUrl: '',
      repoLatestActivity: '',
      nextQuestion: '',
      lastProgressNote: '',
      progressLog: [],
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
        planningEvents: [hackathonEvent, repoEvent],
        planningToday: [hackathonEvent],
        planningWeek: [hackathonEvent],
        planningMonth: [hackathonEvent, repoEvent],
        questionQueue: [
          PlanningQuestion(
            eventId: 1,
            question: 'What changed in FlightIQ?',
            title: 'Build FlightIQ demo',
            project: 'FlightIQ',
            eventType: 'hackathon',
            status: 'planned',
            deadline: '2026-06-21T09:00:00',
            lastProgressNote: '',
          ),
        ],
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
