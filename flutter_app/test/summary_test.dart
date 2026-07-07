import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:what_do_you_do/src/agent_desktop_api.dart';
import 'package:what_do_you_do/src/app_controller.dart';
import 'package:what_do_you_do/src/collector_api.dart';
import 'package:what_do_you_do/src/models.dart';
import 'package:what_do_you_do/src/startup_manager.dart';

void main() {
  test('dashboard summary separates focus and idle time', () {
    final summary = DashboardSummary.fromSessions([
      const ActivitySession(
        id: 'coding',
        startTime: '09:00',
        endTime: '09:30',
        appName: 'Code',
        category: ActivityCategory.coding,
        subcategory: 'Implementation',
        durationMinutes: 30,
        confidence: 90,
        signalSources: ['active-app'],
      ),
      const ActivitySession(
        id: 'idle',
        startTime: '09:30',
        endTime: '09:40',
        appName: 'Desktop',
        category: ActivityCategory.idle,
        subcategory: 'Away',
        durationMinutes: 10,
        confidence: 100,
        signalSources: ['idle-detector'],
      ),
    ]);

    expect(summary.totalMinutes, 40);
    expect(summary.focusMinutes, 30);
    expect(summary.idleMinutes, 10);
    expect(summary.averageConfidence, 95);
  });

  test('agent desktop snapshot parses new service APIs', () {
    final snapshot = AgentDesktopSnapshot.fromJson(
      baseUrl: 'http://127.0.0.1:5050',
      live: {
        'stats': {
          'wellbeing_minutes': 49,
          'active_reminders': 1,
          'opportunities': 94,
        },
        'plan': {'summary': 'Handle interview or deadline work.'},
        'intelligence': {
          'accounts': 2,
          'unread_emails': 7,
          'urgent_emails': 3,
          'today': {
            'summary': '3 urgent email signals.',
            'items': [
              {'time': '08:30', 'title': 'Reply to Client A'},
            ],
          },
          'weekly': {
            'summary': 'Local weekly plan.',
            'items': [
              {'day': 'Monday', 'focus': 'Project work'},
            ],
          },
          'suggestions': [
            {'title': 'Follow up on internship email'},
          ],
          'deadlines': [
            {'summary': 'Finish dashboard by Friday'},
          ],
          'waiting_for': [
            {'summary': 'Client A reply'},
          ],
          'planning_events': {
            'events': [
              {
                'id': 7,
                'event_type': 'hackathon',
                'source': 'hackathon',
                'title': 'Build FlightIQ demo',
                'project': 'FlightIQ',
                'deadline': '2026-06-21T09:00:00',
                'planned_start': '2026-06-19T09:00:00',
                'planned_minutes': 90,
                'status': 'planned',
                'work_done': 'Repo initialized.',
                'work_left': 'Finish dashboard and video.',
                'repo_url': 'https://github.com/anura/flightiq',
                'repo_latest_activity': '2026-06-18: add dashboard',
                'next_question': 'What changed in FlightIQ?',
              },
            ],
            'agenda': {
              'today': [],
              'week': [
                {
                  'id': 7,
                  'event_type': 'hackathon',
                  'source': 'hackathon',
                  'title': 'Build FlightIQ demo',
                  'project': 'FlightIQ',
                  'deadline': '2026-06-21T09:00:00',
                  'planned_start': '2026-06-19T09:00:00',
                  'planned_minutes': 90,
                  'status': 'planned',
                  'work_done': 'Repo initialized.',
                  'work_left': 'Finish dashboard and video.',
                  'repo_url': 'https://github.com/anura/flightiq',
                  'repo_latest_activity': '2026-06-18: add dashboard',
                  'next_question': 'What changed in FlightIQ?',
                },
              ],
              'month': [
                {
                  'id': 7,
                  'event_type': 'hackathon',
                  'source': 'hackathon',
                  'title': 'Build FlightIQ demo',
                  'project': 'FlightIQ',
                  'deadline': '2026-06-21T09:00:00',
                  'planned_start': '2026-06-19T09:00:00',
                  'planned_minutes': 90,
                  'status': 'planned',
                  'work_done': 'Repo initialized.',
                  'work_left': 'Finish dashboard and video.',
                  'repo_url': 'https://github.com/anura/flightiq',
                  'repo_latest_activity': '2026-06-18: add dashboard',
                  'next_question': 'What changed in FlightIQ?',
                },
              ],
            },
            'plan_blocks': {
              'today': [],
              'week': [
                {
                  'event_id': 7,
                  'title': 'Build FlightIQ demo',
                  'project': 'FlightIQ',
                  'event_type': 'hackathon',
                  'start': '2026-06-19T09:00:00',
                  'duration_minutes': 90,
                  'deadline': '2026-06-21T09:00:00',
                  'next_action': 'Finish dashboard and video.',
                  'status': 'planned',
                },
              ],
              'month': [
                {
                  'event_id': 7,
                  'title': 'Build FlightIQ demo',
                  'project': 'FlightIQ',
                  'event_type': 'hackathon',
                  'start': '2026-06-19T09:00:00',
                  'duration_minutes': 90,
                  'deadline': '2026-06-21T09:00:00',
                  'next_action': 'Finish dashboard and video.',
                  'status': 'planned',
                },
              ],
            },
            'question_queue': [
              {
                'event_id': 7,
                'question': 'What changed in FlightIQ?',
                'title': 'Build FlightIQ demo',
                'project': 'FlightIQ',
                'event_type': 'hackathon',
                'status': 'planned',
                'deadline': '2026-06-21T09:00:00',
              },
            ],
          },
        },
        'latest_opportunity': {'title': 'Backend Intern Opening'},
        'latest_activity': {'agent_summary': 'Focus drift detected.'},
        'reminders': [
          {'id': 1, 'title': 'Follow up', 'due_at': '2026-06-18'},
        ],
        'updated_at': '2026-06-17T15:20:29',
      },
      desktop: {
        'desktop': true,
        'data_dir': 'C:/Users/anura/AppData/Local/AiOS Assistant',
        'imports_dir': 'C:/Users/anura/AppData/Local/AiOS Assistant/imports',
      },
      workers: {
        'items': [
          {'id': 'reminders', 'name': 'Reminder Worker', 'running': true},
          {
            'id': 'activity',
            'name': 'Desktop Activity Worker',
            'running': false,
          },
        ],
      },
      hackathons: {
        'hackathons': [{}, {}, {}],
        'unread_updates': 2,
      },
      placements: {
        'placements': [{}],
        'unread_updates': 1,
      },
      neopat: {
        'placements': [{}, {}],
        'unread_updates': 0,
      },
    );

    expect(snapshot.connected, isTrue);
    expect(snapshot.baseUrl, 'http://127.0.0.1:5050');
    expect(snapshot.runningWorkers, 1);
    expect(snapshot.hackathons, 3);
    expect(snapshot.placements, 1);
    expect(snapshot.neopat, 2);
    expect(snapshot.wellbeingMinutes, 49);
    expect(snapshot.latestOpportunityTitle, 'Backend Intern Opening');
    expect(snapshot.intelligence.accounts, 2);
    expect(snapshot.intelligence.urgentEmails, 3);
    expect(snapshot.intelligence.todayItems.single, 'Reply to Client A');
    expect(snapshot.intelligence.weeklyItems.single, 'Project work');
    expect(
      snapshot.intelligence.planningEvents.single.title,
      'Build FlightIQ demo',
    );
    expect(snapshot.intelligence.planningEvents.single.eventType, 'hackathon');
    expect(
      snapshot.intelligence.planningWeek.single.title,
      'Build FlightIQ demo',
    );
    expect(snapshot.intelligence.planningMonth.single.project, 'FlightIQ');
    expect(snapshot.intelligence.planWeek.single.durationMinutes, 90);
    expect(
      snapshot.intelligence.planMonth.single.nextAction,
      'Finish dashboard and video.',
    );
    expect(
      snapshot.intelligence.questionQueue.single.question,
      'What changed in FlightIQ?',
    );
  });

  test('theme preference is saved locally', () async {
    final tempDir = await Directory.systemTemp.createTemp('wdyd-settings-');
    addTearDown(() => tempDir.delete(recursive: true));
    final preferencesFile = File('${tempDir.path}\\settings.json');

    final controller = AppController(
      api: _FakeCollectorApi(),
      agentApi: _FakeAgentDesktopApi(),
      preferencesFile: preferencesFile,
    );
    addTearDown(controller.dispose);

    controller.toggleTheme();
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(await preferencesFile.readAsString(), contains('"darkMode":true'));
  });

  test('planner question answers are sent to AiOS', () async {
    final agentApi = _FakeAgentDesktopApi();
    final controller = AppController(
      api: _FakeCollectorApi(),
      agentApi: agentApi,
    );
    addTearDown(controller.dispose);

    await controller.answerPlanningQuestion(
      const PlanningQuestion(
        eventId: 7,
        question: 'What changed?',
        title: 'Build FlightIQ demo',
        project: 'FlightIQ',
        eventType: 'hackathon',
        status: 'planned',
        deadline: '',
      ),
      'Finished the repo setup and wrote notes.',
    );

    expect(agentApi.answeredEventId, 7);
    expect(agentApi.answer, 'Finished the repo setup and wrote notes.');
    expect(
      controller.message,
      'No activity recorded for ${controller.selectedDate}.',
    );
  });

  test('startup preference state is loaded from manager', () async {
    final controller = AppController(
      api: _FakeCollectorApi(),
      agentApi: _FakeAgentDesktopApi(),
      startupManager: _FakeStartupManager(),
    );
    addTearDown(controller.dispose);

    await controller.initialize();

    expect(controller.startupAvailable, isTrue);
    expect(controller.collectorStartupAvailable, isTrue);
    expect(controller.launchAppAtLogin, isTrue);
    expect(controller.launchAppHiddenAtLogin, isTrue);
    expect(controller.launchCollectorAtLogin, isFalse);
  });

  test('windows startup manager reads shortcut state', () async {
    if (!Platform.isWindows) return;

    final tempDir = await Directory.systemTemp.createTemp('wdyd-startup-');
    addTearDown(() => tempDir.delete(recursive: true));
    await File('${tempDir.path}\\What Do You Do.lnk').writeAsString('');
    final collectorLauncher = File('${tempDir.path}\\start-collector.ps1');
    await collectorLauncher.writeAsString('');

    final state = await WindowsStartupManager(
      startupDirectory: tempDir,
      collectorLauncherFile: collectorLauncher,
    ).load();

    expect(state.available, isTrue);
    expect(state.collectorAvailable, isTrue);
    expect(state.launchApp, isTrue);
    expect(state.launchAppHidden, isFalse);
    expect(state.launchCollector, isFalse);
  });
}

class _FakeCollectorApi extends CollectorApi {
  @override
  Future<Map<String, dynamic>> health() async => const {'ok': true};

  @override
  Future<SessionsResponse> sessions(String date) async => SessionsResponse(
    activeDateKey: date,
    availableDates: [date],
    date: date,
    isLiveDate: true,
    sessions: const [],
  );

  @override
  Future<List<Hackathon>> hackathons() async => const [];
}

class _FakeAgentDesktopApi extends AgentDesktopApi {
  int? answeredEventId;
  String? answer;

  @override
  Future<AgentDesktopSnapshot> snapshot() async =>
      AgentDesktopSnapshot.disconnected('Test agent disconnected.');

  @override
  Future<void> answerPlanningQuestion({
    required int eventId,
    required String answer,
  }) async {
    answeredEventId = eventId;
    this.answer = answer;
  }
}

class _FakeStartupManager extends StartupManager {
  @override
  Future<StartupState> load() async => const StartupState(
    available: true,
    collectorAvailable: true,
    launchApp: true,
    launchAppHidden: true,
    launchCollector: false,
    message: 'Startup test ready.',
  );
}
