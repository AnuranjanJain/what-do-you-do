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
    required this.intelligence,
    required this.readiness,
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
      intelligence: IntelligenceSnapshot.empty(),
      readiness: ReadinessSnapshot.empty(),
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
    final intelligence =
        live['intelligence'] as Map<String, dynamic>? ?? const {};
    final readiness = live['readiness'] as Map<String, dynamic>? ?? const {};

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
      intelligence: IntelligenceSnapshot.fromJson(intelligence),
      readiness: ReadinessSnapshot.fromJson(readiness),
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
  final IntelligenceSnapshot intelligence;
  final ReadinessSnapshot readiness;
  final String dataDir;
  final String importsDir;
  final String updatedAt;

  int get runningWorkers => workers.where((worker) => worker.running).length;
}

class ReadinessSnapshot {
  const ReadinessSnapshot({
    required this.ready,
    required this.total,
    required this.allReady,
    required this.items,
  });

  factory ReadinessSnapshot.empty() {
    return const ReadinessSnapshot(
      ready: 0,
      total: 0,
      allReady: false,
      items: [],
    );
  }

  factory ReadinessSnapshot.fromJson(Map<String, dynamic> json) {
    return ReadinessSnapshot(
      ready: (json['ready'] as num?)?.round() ?? 0,
      total: (json['total'] as num?)?.round() ?? 0,
      allReady: json['all_ready'] == true,
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ReadinessItem.fromJson)
          .toList(),
    );
  }

  final int ready;
  final int total;
  final bool allReady;
  final List<ReadinessItem> items;

  bool get hasItems => items.isNotEmpty;
}

class ReadinessItem {
  const ReadinessItem({
    required this.id,
    required this.label,
    required this.ok,
    required this.detail,
    required this.action,
  });

  factory ReadinessItem.fromJson(Map<String, dynamic> json) {
    return ReadinessItem(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? 'Setup item',
      ok: json['ok'] == true,
      detail: json['detail']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
    );
  }

  final String id;
  final String label;
  final bool ok;
  final String detail;
  final String action;
}

class IntelligenceSnapshot {
  const IntelligenceSnapshot({
    required this.accounts,
    required this.unreadEmails,
    required this.urgentEmails,
    required this.todaySummary,
    required this.todayItems,
    required this.weeklySummary,
    required this.weeklyItems,
    required this.suggestions,
    required this.deadlines,
    required this.waitingFor,
    required this.planningEvents,
    required this.planningToday,
    required this.planningWeek,
    required this.planningMonth,
    required this.questionQueue,
    required this.planToday,
    required this.planWeek,
    required this.planMonth,
    required this.briefing,
  });

  factory IntelligenceSnapshot.empty() {
    return const IntelligenceSnapshot(
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
      planningEvents: [],
      planningToday: [],
      planningWeek: [],
      planningMonth: [],
      questionQueue: [],
      planToday: [],
      planWeek: [],
      planMonth: [],
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
    );
  }

  factory IntelligenceSnapshot.fromJson(Map<String, dynamic> json) {
    final today = json['today'] as Map<String, dynamic>? ?? const {};
    final weekly = json['weekly'] as Map<String, dynamic>? ?? const {};
    final planning =
        json['planning_events'] as Map<String, dynamic>? ?? const {};
    return IntelligenceSnapshot(
      accounts: (json['accounts'] as num?)?.round() ?? 0,
      unreadEmails: (json['unread_emails'] as num?)?.round() ?? 0,
      urgentEmails: (json['urgent_emails'] as num?)?.round() ?? 0,
      todaySummary: today['summary']?.toString() ?? '',
      todayItems: _stringListFromPlanItems(today['items'], 'title'),
      weeklySummary: weekly['summary']?.toString() ?? '',
      weeklyItems: _stringListFromPlanItems(weekly['items'], 'focus'),
      suggestions: _stringListFromPlanItems(json['suggestions'], 'title'),
      deadlines: _stringListFromPlanItems(json['deadlines'], 'summary'),
      waitingFor: _stringListFromPlanItems(json['waiting_for'], 'summary'),
      planningEvents: (planning['events'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(PlanningEventSummary.fromJson)
          .toList(),
      planningToday: _planningAgendaList(planning, 'today'),
      planningWeek: _planningAgendaList(planning, 'week'),
      planningMonth: _planningAgendaList(planning, 'month'),
      questionQueue: (planning['question_queue'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(PlanningQuestion.fromJson)
          .toList(),
      planToday: _planningBlockList(planning, 'today'),
      planWeek: _planningBlockList(planning, 'week'),
      planMonth: _planningBlockList(planning, 'month'),
      briefing: PlannerBriefing.fromJson(
        planning['briefing'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  final int accounts;
  final int unreadEmails;
  final int urgentEmails;
  final String todaySummary;
  final List<String> todayItems;
  final String weeklySummary;
  final List<String> weeklyItems;
  final List<String> suggestions;
  final List<String> deadlines;
  final List<String> waitingFor;
  final List<PlanningEventSummary> planningEvents;
  final List<PlanningEventSummary> planningToday;
  final List<PlanningEventSummary> planningWeek;
  final List<PlanningEventSummary> planningMonth;
  final List<PlanningQuestion> questionQueue;
  final List<PlanningBlock> planToday;
  final List<PlanningBlock> planWeek;
  final List<PlanningBlock> planMonth;
  final PlannerBriefing briefing;

  bool get hasSignals =>
      accounts > 0 ||
      unreadEmails > 0 ||
      urgentEmails > 0 ||
      todayItems.isNotEmpty ||
      suggestions.isNotEmpty ||
      questionQueue.isNotEmpty ||
      briefing.hasSignals ||
      planToday.isNotEmpty ||
      planningEvents.isNotEmpty;
}

class PlannerBriefing {
  const PlannerBriefing({
    required this.headline,
    required this.todayCount,
    required this.weekCount,
    required this.monthCount,
    required this.needsAnswerCount,
    required this.blockedCount,
    required this.focus,
    required this.dueSoon,
    required this.askNext,
  });

  factory PlannerBriefing.empty() {
    return const PlannerBriefing(
      headline: '',
      todayCount: 0,
      weekCount: 0,
      monthCount: 0,
      needsAnswerCount: 0,
      blockedCount: 0,
      focus: [],
      dueSoon: [],
      askNext: [],
    );
  }

  factory PlannerBriefing.fromJson(Map<String, dynamic> json) {
    return PlannerBriefing(
      headline: json['headline']?.toString() ?? '',
      todayCount: (json['today_count'] as num?)?.round() ?? 0,
      weekCount: (json['week_count'] as num?)?.round() ?? 0,
      monthCount: (json['month_count'] as num?)?.round() ?? 0,
      needsAnswerCount: (json['needs_answer_count'] as num?)?.round() ?? 0,
      blockedCount: (json['blocked_count'] as num?)?.round() ?? 0,
      focus: _stringList(json['focus']),
      dueSoon: _stringList(json['due_soon']),
      askNext: _stringList(json['ask_next']),
    );
  }

  final String headline;
  final int todayCount;
  final int weekCount;
  final int monthCount;
  final int needsAnswerCount;
  final int blockedCount;
  final List<String> focus;
  final List<String> dueSoon;
  final List<String> askNext;

  bool get hasSignals =>
      headline.isNotEmpty ||
      todayCount > 0 ||
      weekCount > 0 ||
      needsAnswerCount > 0 ||
      focus.isNotEmpty;
}

List<PlanningEventSummary> _planningAgendaList(
  Map<String, dynamic> planning,
  String key,
) {
  final agenda = planning['agenda'] as Map<String, dynamic>? ?? const {};
  return (agenda[key] as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map(PlanningEventSummary.fromJson)
      .toList();
}

List<PlanningBlock> _planningBlockList(
  Map<String, dynamic> planning,
  String key,
) {
  final blocks = planning['plan_blocks'] as Map<String, dynamic>? ?? const {};
  return (blocks[key] as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map(PlanningBlock.fromJson)
      .toList();
}

class PlanningBlock {
  const PlanningBlock({
    required this.eventId,
    required this.title,
    required this.project,
    required this.eventType,
    required this.start,
    required this.durationMinutes,
    required this.deadline,
    required this.nextAction,
    required this.status,
  });

  factory PlanningBlock.fromJson(Map<String, dynamic> json) {
    return PlanningBlock(
      eventId: (json['event_id'] as num?)?.round() ?? 0,
      title: json['title']?.toString() ?? 'Untitled event',
      project: json['project']?.toString() ?? '',
      eventType: json['event_type']?.toString() ?? 'task',
      start: json['start']?.toString() ?? '',
      durationMinutes: (json['duration_minutes'] as num?)?.round() ?? 45,
      deadline: json['deadline']?.toString() ?? '',
      nextAction: json['next_action']?.toString() ?? '',
      status: json['status']?.toString() ?? 'planned',
    );
  }

  final int eventId;
  final String title;
  final String project;
  final String eventType;
  final String start;
  final int durationMinutes;
  final String deadline;
  final String nextAction;
  final String status;
}

class PlanningEventSummary {
  const PlanningEventSummary({
    required this.id,
    required this.eventType,
    required this.source,
    required this.title,
    required this.project,
    required this.idea,
    required this.deadline,
    required this.plannedStart,
    required this.plannedMinutes,
    required this.status,
    required this.workDone,
    required this.workLeft,
    required this.repoUrl,
    required this.repoLatestActivity,
    required this.nextQuestion,
    required this.lastProgressNote,
    required this.progressLog,
  });

  factory PlanningEventSummary.fromJson(Map<String, dynamic> json) {
    return PlanningEventSummary(
      id: (json['id'] as num?)?.round() ?? 0,
      eventType: json['event_type']?.toString() ?? 'task',
      source: json['source']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled event',
      project: json['project']?.toString() ?? '',
      idea: json['idea']?.toString() ?? '',
      deadline: json['deadline']?.toString() ?? '',
      plannedStart: json['planned_start']?.toString() ?? '',
      plannedMinutes: (json['planned_minutes'] as num?)?.round() ?? 45,
      status: json['status']?.toString() ?? 'planned',
      workDone: json['work_done']?.toString() ?? '',
      workLeft: json['work_left']?.toString() ?? '',
      repoUrl: json['repo_url']?.toString() ?? '',
      repoLatestActivity: json['repo_latest_activity']?.toString() ?? '',
      nextQuestion: json['next_question']?.toString() ?? '',
      lastProgressNote: json['last_progress_note']?.toString() ?? '',
      progressLog: _progressLogFromJson(json['metadata']),
    );
  }

  final int id;
  final String eventType;
  final String source;
  final String title;
  final String project;
  final String idea;
  final String deadline;
  final String plannedStart;
  final int plannedMinutes;
  final String status;
  final String workDone;
  final String workLeft;
  final String repoUrl;
  final String repoLatestActivity;
  final String nextQuestion;
  final String lastProgressNote;
  final List<ProgressLogEntry> progressLog;
}

class ProgressLogEntry {
  const ProgressLogEntry({
    required this.at,
    required this.note,
    required this.question,
  });

  factory ProgressLogEntry.fromJson(Map<String, dynamic> json) {
    return ProgressLogEntry(
      at: json['at']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
    );
  }

  final String at;
  final String note;
  final String question;
}

List<ProgressLogEntry> _progressLogFromJson(dynamic metadata) {
  if (metadata is! Map<String, dynamic>) return const [];
  final raw = metadata['progress_log'];
  if (raw is! List<dynamic>) return const [];
  return raw
      .whereType<Map<String, dynamic>>()
      .map(ProgressLogEntry.fromJson)
      .where((entry) => entry.note.trim().isNotEmpty)
      .toList(growable: false);
}

class PlanningQuestion {
  const PlanningQuestion({
    required this.eventId,
    required this.question,
    required this.title,
    required this.project,
    required this.eventType,
    required this.status,
    required this.deadline,
    required this.lastProgressNote,
  });

  factory PlanningQuestion.fromJson(Map<String, dynamic> json) {
    return PlanningQuestion(
      eventId: (json['event_id'] as num?)?.round() ?? 0,
      question: json['question']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled event',
      project: json['project']?.toString() ?? '',
      eventType: json['event_type']?.toString() ?? 'task',
      status: json['status']?.toString() ?? 'planned',
      deadline: json['deadline']?.toString() ?? '',
      lastProgressNote: json['last_progress_note']?.toString() ?? '',
    );
  }

  final int eventId;
  final String question;
  final String title;
  final String project;
  final String eventType;
  final String status;
  final String deadline;
  final String lastProgressNote;
}

class PlanningProgressUpdate {
  const PlanningProgressUpdate({
    required this.progressNote,
    required this.workDone,
    required this.workLeft,
    required this.status,
  });

  final String progressNote;
  final String workDone;
  final String workLeft;
  final String status;

  bool get isEmpty =>
      progressNote.trim().isEmpty &&
      workDone.trim().isEmpty &&
      workLeft.trim().isEmpty &&
      status.trim().isEmpty;

  Map<String, dynamic> toJson() {
    return {
      if (progressNote.trim().isNotEmpty) 'progress_note': progressNote.trim(),
      if (workDone.trim().isNotEmpty) 'work_done': workDone.trim(),
      if (workLeft.trim().isNotEmpty) 'work_left': workLeft.trim(),
      if (status.trim().isNotEmpty) 'status': status.trim(),
    };
  }
}

class IntelligenceSyncResult {
  const IntelligenceSyncResult({
    required this.accounts,
    required this.seen,
    required this.imported,
    required this.analyzed,
    required this.suggestions,
    required this.plannerRows,
    required this.plannerQuestions,
    required this.hadErrors,
  });

  factory IntelligenceSyncResult.fromJson(Map<String, dynamic> json) {
    final sync = json['sync'] as List<dynamic>? ?? const [];
    final accountResults = sync.whereType<Map<String, dynamic>>().toList();
    final analysis = json['analysis'] as Map<String, dynamic>? ?? const {};
    final suggestions = json['suggestions'];
    final planning = json['planning'] as Map<String, dynamic>? ?? const {};
    return IntelligenceSyncResult(
      accounts: accountResults.length,
      seen: accountResults.fold<int>(
        0,
        (total, item) => total + ((item['seen'] as num?)?.round() ?? 0),
      ),
      imported: accountResults.fold<int>(
        0,
        (total, item) => total + ((item['imported'] as num?)?.round() ?? 0),
      ),
      analyzed: (analysis['analyzed'] as num?)?.round() ?? 0,
      suggestions: suggestions is Map<String, dynamic>
          ? (suggestions['created'] as num?)?.round() ?? 0
          : (suggestions as num?)?.round() ?? 0,
      plannerRows: (planning['rows'] as num?)?.round() ?? 0,
      plannerQuestions: (planning['questions'] as num?)?.round() ?? 0,
      hadErrors: accountResults.any((item) => item['ok'] == false),
    );
  }

  final int accounts;
  final int seen;
  final int imported;
  final int analyzed;
  final int suggestions;
  final int plannerRows;
  final int plannerQuestions;
  final bool hadErrors;

  String get summary {
    if (accounts == 0) {
      return 'No Gmail accounts are enabled yet.';
    }
    final status = hadErrors ? 'Sync needs attention' : 'Sync finished';
    return '$status: $imported new of $seen seen, $analyzed analyzed, $plannerRows rows, $plannerQuestions questions.';
  }
}

class PlanningEventDraft {
  const PlanningEventDraft({
    required this.eventType,
    required this.title,
    required this.project,
    required this.idea,
    required this.deadline,
    required this.plannedStart,
    required this.plannedMinutes,
    required this.workDone,
    required this.workLeft,
    required this.repoUrl,
  });

  final String eventType;
  final String title;
  final String project;
  final String idea;
  final String deadline;
  final String plannedStart;
  final int plannedMinutes;
  final String workDone;
  final String workLeft;
  final String repoUrl;

  Map<String, dynamic> toJson() {
    return {
      'event_type': eventType,
      'title': title,
      'project': project,
      'idea': idea,
      'deadline': deadline,
      'planned_start': plannedStart,
      'planned_minutes': plannedMinutes,
      'work_done': workDone,
      'work_left': workLeft,
      'repo_url': repoUrl,
      'status': 'planned',
    };
  }
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

List<String> _stringListFromPlanItems(dynamic raw, String field) {
  if (raw is! List<dynamic>) return const [];
  return raw
      .map((item) {
        if (item is Map<String, dynamic>) {
          return item[field]?.toString() ?? item['title']?.toString() ?? '';
        }
        return item.toString();
      })
      .where((item) => item.trim().isNotEmpty)
      .take(8)
      .toList();
}

List<String> _stringList(dynamic raw) {
  if (raw is! List<dynamic>) return const [];
  return raw
      .map((item) => item.toString())
      .where((item) => item.trim().isNotEmpty)
      .toList();
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
