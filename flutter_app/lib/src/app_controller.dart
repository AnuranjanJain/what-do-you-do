import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'agent_desktop_api.dart';
import 'collector_api.dart';
import 'models.dart';

class AppController extends ChangeNotifier {
  AppController({
    CollectorApi? api,
    AgentDesktopApi? agentApi,
    File? preferencesFile,
  })
    : _api = api ?? CollectorApi(),
      _agentApi = agentApi ?? AgentDesktopApi(),
      _preferencesFileOverride = preferencesFile;

  final CollectorApi _api;
  final AgentDesktopApi _agentApi;
  final File? _preferencesFileOverride;
  Timer? _refreshTimer;

  bool darkMode = false;
  bool loading = true;
  bool collectorOnline = false;
  String message = 'Connecting to the local collector...';
  String selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String activeDate = '';
  List<String> availableDates = const [];
  List<ActivitySession> sessions = const [];
  List<Hackathon> hackathons = const [];
  AgentDesktopSnapshot agent = AgentDesktopSnapshot.disconnected(
    'AiOS Desktop has not been checked yet.',
  );

  DashboardSummary get summary => DashboardSummary.fromSessions(sessions);

  Future<void> initialize() async {
    await _loadPreferences();
    await refresh();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => refresh(silent: true),
    );
  }

  Future<void> refresh({bool silent = false}) async {
    if (!silent) {
      loading = true;
      notifyListeners();
    }

    try {
      await _api.health();
      final response = await _api.sessions(selectedDate);
      List<Hackathon> loadedHackathons = hackathons;
      AgentDesktopSnapshot loadedAgent = agent;
      try {
        loadedHackathons = await _api.hackathons();
      } catch (_) {
        // Activity remains usable if the optional board cannot be loaded.
      }
      try {
        loadedAgent = await _agentApi.snapshot();
      } catch (error) {
        loadedAgent = AgentDesktopSnapshot.disconnected(
          error is Exception
              ? error.toString().replaceFirst('Exception: ', '')
              : 'AiOS Desktop is unavailable.',
        );
      }

      collectorOnline = true;
      activeDate = response.activeDateKey;
      availableDates = response.availableDates;
      sessions = response.sessions;
      hackathons = loadedHackathons;
      agent = loadedAgent;
      message = sessions.isEmpty
          ? 'No activity recorded for $selectedDate.'
          : '${sessions.length} private local sessions loaded.';
    } catch (_) {
      collectorOnline = false;
      sessions = const [];
      try {
        agent = await _agentApi.snapshot();
      } catch (error) {
        agent = AgentDesktopSnapshot.disconnected(
          error is Exception
              ? error.toString().replaceFirst('Exception: ', '')
              : 'AiOS Desktop is unavailable.',
        );
      }
      message =
          'Collector is offline. Start the local collector to show real data.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> selectDate(DateTime date) async {
    selectedDate = DateFormat('yyyy-MM-dd').format(date);
    await refresh();
  }

  void toggleTheme() {
    darkMode = !darkMode;
    notifyListeners();
    unawaited(_savePreferences());
  }

  Future<void> _loadPreferences() async {
    try {
      final file = _preferencesFile();
      if (!await file.exists()) return;
      final data = jsonDecode(await file.readAsString());
      if (data case {'darkMode': final bool savedDarkMode}) {
        darkMode = savedDarkMode;
      }
    } catch (_) {
      // Corrupt preferences should never block the local dashboard.
    }
  }

  Future<void> _savePreferences() async {
    try {
      final file = _preferencesFile();
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode({'darkMode': darkMode}));
    } catch (_) {
      // Theme persistence is best-effort and must not interrupt the app.
    }
  }

  File _preferencesFile() {
    if (_preferencesFileOverride case final override?) return override;
    final base = Platform.environment['LOCALAPPDATA'] ??
        Platform.environment['APPDATA'] ??
        Directory.current.path;
    return File('$base\\What Do You Do\\settings.json');
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
