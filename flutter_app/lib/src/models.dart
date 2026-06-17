enum ActivityCategory {
  coding,
  browsing,
  communication,
  gaming,
  watching,
  idle;

  static ActivityCategory parse(String value) {
    return ActivityCategory.values.firstWhere(
      (category) => category.name == value,
      orElse: () => ActivityCategory.browsing,
    );
  }
}

class ActivitySession {
  const ActivitySession({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.appName,
    required this.category,
    required this.subcategory,
    required this.durationMinutes,
    required this.confidence,
    required this.signalSources,
    this.note,
  });

  factory ActivitySession.fromJson(Map<String, dynamic> json) {
    return ActivitySession(
      id: json['id']?.toString() ?? '',
      startTime: json['startTime']?.toString() ?? '--:--',
      endTime: json['endTime']?.toString() ?? '--:--',
      appName: json['appName']?.toString() ?? 'Unknown app',
      category: ActivityCategory.parse(json['category']?.toString() ?? ''),
      subcategory: json['subcategory']?.toString() ?? 'Unclassified activity',
      durationMinutes: (json['durationMinutes'] as num?)?.round() ?? 0,
      confidence: (json['confidence'] as num?)?.round() ?? 0,
      signalSources: (json['signalSources'] as List<dynamic>? ?? const [])
          .map((source) => source.toString())
          .toList(),
      note: json['note']?.toString(),
    );
  }

  final String id;
  final String startTime;
  final String endTime;
  final String appName;
  final ActivityCategory category;
  final String subcategory;
  final int durationMinutes;
  final int confidence;
  final List<String> signalSources;
  final String? note;
}

class SessionsResponse {
  const SessionsResponse({
    required this.activeDateKey,
    required this.availableDates,
    required this.date,
    required this.isLiveDate,
    required this.sessions,
  });

  factory SessionsResponse.fromJson(Map<String, dynamic> json) {
    return SessionsResponse(
      activeDateKey: json['activeDateKey']?.toString() ?? '',
      availableDates: (json['availableDates'] as List<dynamic>? ?? const [])
          .map((date) => date.toString())
          .toList(),
      date: json['date']?.toString() ?? '',
      isLiveDate: json['isLiveDate'] == true,
      sessions: (json['sessions'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ActivitySession.fromJson)
          .toList(),
    );
  }

  final String activeDateKey;
  final List<String> availableDates;
  final String date;
  final bool isLiveDate;
  final List<ActivitySession> sessions;
}

class Hackathon {
  const Hackathon({
    required this.id,
    required this.title,
    required this.organizer,
    required this.status,
    required this.deadline,
    required this.progress,
    required this.plan,
    required this.workDone,
  });

  factory Hackathon.fromJson(Map<String, dynamic> json) {
    return Hackathon(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled hackathon',
      organizer: json['organizer']?.toString() ?? '',
      status: json['status']?.toString() ?? 'watching',
      deadline: json['deadline']?.toString() ?? '',
      progress: (json['progress'] as num?)?.round() ?? 0,
      plan: json['plan']?.toString() ?? '',
      workDone: json['workDone']?.toString() ?? '',
    );
  }

  final String id;
  final String title;
  final String organizer;
  final String status;
  final String deadline;
  final int progress;
  final String plan;
  final String workDone;
}

class AgentDesktopSnapshot {
  const AgentDesktopSnapshot({
    required this.baseUrl,
    required this.connected,
    required this.desktop,
    required this.message,
    required this.wellbeingMinutes,
    required this.activeReminders,
    required this.opportunities,
    required this.hackathons,
    required this.placements,
    required this.neopat,
    required this.unreadHackathonUpdates,
    required this.unreadPlacementUpdates,
    required this.unreadNeoPatUpdates,
    required this.workers,
    required this.reminders,
    required this.planSummary,
    required this.latestOpportunityTitle,
    required this.latestActivitySummary,
    required this.dataDir,
    required this.importsDir,
    required this.updatedAt,
  });

  factory AgentDesktopSnapshot.disconnected(String message) {
    return AgentDesktopSnapshot(
      baseUrl: '',
      connected: false,
      desktop: false,
      message: message,
      wellbeingMinutes: 0,
      activeReminders: 0,
      opportunities: 0,
      hackathons: 0,
      placements: 0,
      neopat: 0,
      unreadHackathonUpdates: 0,
      unreadPlacementUpdates: 0,
      unreadNeoPatUpdates: 0,
      workers: const [],
      reminders: const [],
      planSummary: '',
      latestOpportunityTitle: '',
      latestActivitySummary: '',
      dataDir: '',
      importsDir: '',
      updatedAt: '',
    );
  }

  factory AgentDesktopSnapshot.fromJson({
    required String baseUrl,
    required Map<String, dynamic> live,
    required Map<String, dynamic> desktop,
    required Map<String, dynamic> workers,
    required Map<String, dynamic> hackathons,
    required Map<String, dynamic> placements,
    required Map<String, dynamic> neopat,
  }) {
    final stats = live['stats'] as Map<String, dynamic>? ?? const {};
    final latestActivity =
        live['latest_activity'] as Map<String, dynamic>? ?? const {};
    final latestOpportunity =
        live['latest_opportunity'] as Map<String, dynamic>? ?? const {};
    final plan = live['plan'] as Map<String, dynamic>? ?? const {};

    return AgentDesktopSnapshot(
      baseUrl: baseUrl,
      connected: true,
      desktop: desktop['desktop'] == true,
      message: 'Connected to AiOS Desktop at $baseUrl',
      wellbeingMinutes: (stats['wellbeing_minutes'] as num?)?.round() ?? 0,
      activeReminders: (stats['active_reminders'] as num?)?.round() ?? 0,
      opportunities: (stats['opportunities'] as num?)?.round() ?? 0,
      hackathons: _countList(hackathons['hackathons']),
      placements: _countList(placements['placements']),
      neopat: _countList(neopat['placements']),
      unreadHackathonUpdates:
          (hackathons['unread_updates'] as num?)?.round() ?? 0,
      unreadPlacementUpdates:
          (placements['unread_updates'] as num?)?.round() ?? 0,
      unreadNeoPatUpdates: (neopat['unread_updates'] as num?)?.round() ?? 0,
      workers: _workersFromJson(workers),
      reminders: _remindersFromJson(live['reminders']),
      planSummary: plan['summary']?.toString() ?? '',
      latestOpportunityTitle: latestOpportunity['title']?.toString() ?? '',
      latestActivitySummary: latestActivity['agent_summary']?.toString() ?? '',
      dataDir: desktop['data_dir']?.toString() ?? '',
      importsDir: desktop['imports_dir']?.toString() ?? '',
      updatedAt: live['updated_at']?.toString() ?? '',
    );
  }

  final String baseUrl;
  final bool connected;
  final bool desktop;
  final String message;
  final int wellbeingMinutes;
  final int activeReminders;
  final int opportunities;
  final int hackathons;
  final int placements;
  final int neopat;
  final int unreadHackathonUpdates;
  final int unreadPlacementUpdates;
  final int unreadNeoPatUpdates;
  final List<AgentWorker> workers;
  final List<AgentReminder> reminders;
  final String planSummary;
  final String latestOpportunityTitle;
  final String latestActivitySummary;
  final String dataDir;
  final String importsDir;
  final String updatedAt;

  int get runningWorkers => workers.where((worker) => worker.running).length;
}

class AgentWorker {
  const AgentWorker({
    required this.id,
    required this.name,
    required this.running,
    required this.managed,
    required this.lastError,
  });

  final String id;
  final String name;
  final bool running;
  final bool managed;
  final String lastError;
}

class AgentReminder {
  const AgentReminder({
    required this.id,
    required this.title,
    required this.dueAt,
  });

  final int id;
  final String title;
  final String dueAt;
}

int _countList(dynamic value) {
  if (value is List<dynamic>) return value.length;
  return 0;
}

List<AgentWorker> _workersFromJson(Map<String, dynamic> json) {
  final raw = json['items'] ?? json['value'] ?? json['workers'];
  if (raw is! List<dynamic>) return const [];
  return raw.whereType<Map<String, dynamic>>().map((item) {
    return AgentWorker(
      id: item['id']?.toString() ?? '',
      name: item['name']?.toString() ?? 'Worker',
      running: item['running'] == true,
      managed: item['managed'] == true,
      lastError: item['last_error']?.toString() ?? '',
    );
  }).toList();
}

List<AgentReminder> _remindersFromJson(dynamic raw) {
  if (raw is! List<dynamic>) return const [];
  return raw.whereType<Map<String, dynamic>>().map((item) {
    return AgentReminder(
      id: (item['id'] as num?)?.round() ?? 0,
      title: item['title']?.toString() ?? 'Reminder',
      dueAt: item['due_at']?.toString() ?? '',
    );
  }).toList();
}

class CategoryTotal {
  const CategoryTotal(this.category, this.minutes);

  final ActivityCategory category;
  final int minutes;
}

class DashboardSummary {
  const DashboardSummary({
    required this.totalMinutes,
    required this.focusMinutes,
    required this.idleMinutes,
    required this.averageConfidence,
    required this.corrections,
    required this.categoryTotals,
  });

  factory DashboardSummary.fromSessions(List<ActivitySession> sessions) {
    var total = 0;
    var focus = 0;
    var idle = 0;
    var confidence = 0;
    var corrections = 0;
    final totals = <ActivityCategory, int>{
      for (final category in ActivityCategory.values) category: 0,
    };

    for (final session in sessions) {
      total += session.durationMinutes;
      confidence += session.confidence;
      totals[session.category] =
          (totals[session.category] ?? 0) + session.durationMinutes;
      if (session.category == ActivityCategory.coding ||
          session.category == ActivityCategory.browsing) {
        focus += session.durationMinutes;
      }
      if (session.category == ActivityCategory.idle) {
        idle += session.durationMinutes;
      }
      if (session.signalSources.contains('user-correction')) corrections++;
    }

    return DashboardSummary(
      totalMinutes: total,
      focusMinutes: focus,
      idleMinutes: idle,
      averageConfidence: sessions.isEmpty
          ? 0
          : (confidence / sessions.length).round(),
      corrections: corrections,
      categoryTotals: totals.entries
          .map((entry) => CategoryTotal(entry.key, entry.value))
          .toList(),
    );
  }

  final int totalMinutes;
  final int focusMinutes;
  final int idleMinutes;
  final int averageConfidence;
  final int corrections;
  final List<CategoryTotal> categoryTotals;
}
