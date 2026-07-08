import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'agent_desktop_api.dart';
import 'collector_api.dart';
import 'models.dart';
import 'startup_manager.dart';
import 'window_lifecycle.dart';

class AppController extends ChangeNotifier {
  AppController({
    CollectorApi? api,
    AgentDesktopApi? agentApi,
    File? preferencesFile,
    StartupManager? startupManager,
    WindowLifecycle? windowLifecycle,
  }) : _api = api ?? CollectorApi(),
       _agentApi = agentApi ?? AgentDesktopApi(),
       _preferencesFileOverride = preferencesFile,
       _startupManager = startupManager ?? WindowsStartupManager(),
       _windowLifecycle = windowLifecycle ?? const WindowLifecycle();

  final CollectorApi _api;
  final AgentDesktopApi _agentApi;
  final File? _preferencesFileOverride;
  final StartupManager _startupManager;
  final WindowLifecycle _windowLifecycle;
  Timer? _refreshTimer;

  bool darkMode = false;
  bool launchAppAtLogin = false;
  bool launchAppHiddenAtLogin = false;
  bool launchCollectorAtLogin = false;
  bool startupAvailable = false;
  bool collectorStartupAvailable = false;
  bool loading = true;
  bool collectorOnline = false;
  String message = 'Connecting to the local collector...';
  String startupMessage = 'Checking startup services...';
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
    await _loadStartupState();
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

  Future<void> answerPlanningQuestion(
    PlanningQuestion question,
    PlanningProgressUpdate update,
  ) async {
    if (update.isEmpty) return;
    message = 'Saving progress for ${question.title}...';
    notifyListeners();
    try {
      await _agentApi.answerPlanningQuestion(
        eventId: question.eventId,
        update: update,
      );
      message = 'Progress saved to AiOS.';
      await refresh(silent: true);
    } catch (error) {
      message = error is Exception
          ? error.toString().replaceFirst('Exception: ', '')
          : 'Could not save progress to AiOS.';
      notifyListeners();
    }
  }

  Future<void> createPlanningEvent(PlanningEventDraft draft) async {
    if (draft.title.trim().isEmpty) return;
    message = 'Adding ${draft.title} to AiOS planner...';
    notifyListeners();
    try {
      await _agentApi.createPlanningEvent(draft);
      message = 'Planner row added to AiOS.';
      await refresh(silent: true);
    } catch (error) {
      message = error is Exception
          ? error.toString().replaceFirst('Exception: ', '')
          : 'Could not add planner row to AiOS.';
      notifyListeners();
    }
  }

  Future<void> syncIntelligence() async {
    message = 'Syncing Gmail, planner rows, and local AI insights...';
    notifyListeners();
    try {
      final result = await _agentApi.syncIntelligence();
      await refresh(silent: true);
      message = result.summary;
      notifyListeners();
    } catch (error) {
      message = error is Exception
          ? error.toString().replaceFirst('Exception: ', '')
          : 'Could not sync AiOS intelligence.';
      notifyListeners();
    }
  }

  void toggleTheme() {
    darkMode = !darkMode;
    notifyListeners();
    unawaited(_savePreferences());
  }

  Future<void> setLaunchAppAtLogin(bool enabled) async {
    launchAppAtLogin = enabled;
    startupMessage = enabled
        ? 'Enabling app launch at sign-in...'
        : 'Disabling app launch at sign-in...';
    notifyListeners();
    try {
      await _startupManager.setLaunchApp(
        enabled,
        hidden: launchAppHiddenAtLogin,
      );
    } catch (error) {
      startupMessage = _friendlyStartupError(error);
    }
    await _loadStartupState();
  }

  Future<void> setLaunchAppHiddenAtLogin(bool enabled) async {
    launchAppHiddenAtLogin = enabled;
    startupMessage = enabled
        ? 'Enabling tray startup mode...'
        : 'Disabling tray startup mode...';
    notifyListeners();
    try {
      await _startupManager.setLaunchApp(launchAppAtLogin, hidden: enabled);
    } catch (error) {
      startupMessage = _friendlyStartupError(error);
    }
    await _loadStartupState();
  }

  Future<void> setLaunchCollectorAtLogin(bool enabled) async {
    launchCollectorAtLogin = enabled;
    startupMessage = enabled
        ? 'Enabling local collector at sign-in...'
        : 'Disabling local collector at sign-in...';
    notifyListeners();
    try {
      await _startupManager.setLaunchCollector(enabled);
    } catch (error) {
      startupMessage = _friendlyStartupError(error);
    }
    await _loadStartupState();
  }

  Future<void> hideToTray() async {
    await _windowLifecycle.hideToTray();
  }

  Future<void> exitApp() async {
    await _windowLifecycle.exit();
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

  Future<void> _loadStartupState() async {
    try {
      final state = await _startupManager.load();
      startupAvailable = state.available;
      collectorStartupAvailable = state.collectorAvailable;
      launchAppAtLogin = state.launchApp;
      launchAppHiddenAtLogin = state.launchAppHidden;
      launchCollectorAtLogin = state.launchCollector;
      startupMessage = state.message;
    } catch (error) {
      startupAvailable = false;
      collectorStartupAvailable = false;
      launchAppAtLogin = false;
      launchAppHiddenAtLogin = false;
      launchCollectorAtLogin = false;
      startupMessage = _friendlyStartupError(error);
    }
    notifyListeners();
  }

  String _friendlyStartupError(Object error) {
    final message = error is Exception || error is Error
        ? error.toString().replaceFirst(
            RegExp(r'^(Exception|StateError): '),
            '',
          )
        : 'Startup settings are unavailable.';
    return message.isEmpty ? 'Startup settings are unavailable.' : message;
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
    final base =
        Platform.environment['LOCALAPPDATA'] ??
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
