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
}
