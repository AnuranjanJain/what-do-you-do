import 'package:flutter_test/flutter_test.dart';
import 'package:what_do_you_do/src/agent_desktop_api.dart';
import 'package:what_do_you_do/src/app_controller.dart';
import 'package:what_do_you_do/src/collector_api.dart';
import 'package:what_do_you_do/src/models.dart';

void main() {
  test(
    'keeps saved sessions visible when the collector is temporarily offline',
    () async {
      final savedSession = const ActivitySession(
        id: 'saved-session',
        startTime: '09:00',
        endTime: '09:45',
        appName: 'Code',
        category: ActivityCategory.coding,
        subcategory: 'Implementation',
        durationMinutes: 45,
        confidence: 94,
        signalSources: ['active-app'],
      );
      final controller = AppController(
        api: _OfflineCollector(savedSession),
        agentApi: _DisconnectedAgentApi(),
      );
      addTearDown(controller.dispose);

      await controller.refresh();

      expect(controller.collectorOnline, isFalse);
      expect(controller.sessions, hasLength(1));
      expect(controller.sessions.single.id, 'saved-session');
      expect(controller.message, contains('saved local sessions'));
    },
  );
}

class _OfflineCollector extends CollectorApi {
  _OfflineCollector(this.savedSession);

  final ActivitySession savedSession;

  @override
  Future<Map<String, dynamic>> health() async => {
    'ok': false,
    'lastError': 'Native activity probe is unavailable.',
  };

  @override
  Future<SessionsResponse> sessions(String date) async => SessionsResponse(
    activeDateKey: date,
    availableDates: [date],
    date: date,
    isLiveDate: true,
    sessions: [savedSession],
  );
}

class _DisconnectedAgentApi extends AgentDesktopApi {
  _DisconnectedAgentApi() : super(candidateBaseUrls: const []);

  @override
  Future<AgentDesktopSnapshot> snapshot({bool forceDiscovery = false}) async =>
      AgentDesktopSnapshot.disconnected('AiOS is not running.');
}
