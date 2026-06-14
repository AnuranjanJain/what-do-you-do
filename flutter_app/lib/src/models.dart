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
