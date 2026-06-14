import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'collector_api.dart';
import 'models.dart';

class AppController extends ChangeNotifier {
  AppController({CollectorApi? api}) : _api = api ?? CollectorApi();

  final CollectorApi _api;
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

  DashboardSummary get summary => DashboardSummary.fromSessions(sessions);

  Future<void> initialize() async {
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
      try {
        loadedHackathons = await _api.hackathons();
      } catch (_) {
        // Activity remains usable if the optional board cannot be loaded.
      }

      collectorOnline = true;
      activeDate = response.activeDateKey;
      availableDates = response.availableDates;
      sessions = response.sessions;
      hackathons = loadedHackathons;
      message = sessions.isEmpty
          ? 'No activity recorded for $selectedDate.'
          : '${sessions.length} private local sessions loaded.';
    } catch (_) {
      collectorOnline = false;
      sessions = const [];
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
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
