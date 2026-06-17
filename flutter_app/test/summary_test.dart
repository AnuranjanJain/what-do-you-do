import 'package:flutter_test/flutter_test.dart';
import 'package:what_do_you_do/src/models.dart';

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
  });
}
