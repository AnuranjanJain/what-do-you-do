export type ActivityCategory =
  | "coding"
  | "browsing"
  | "communication"
  | "gaming"
  | "watching"
  | "idle";

export type SignalSource =
  | "active-app"
  | "browser-domain"
  | "app-state"
  | "idle-detector"
  | "user-correction";

export type PermissionState = "enabled" | "optional" | "disabled";

export type ActivitySession = {
  id: string;
  startTime: string;
  endTime: string;
  appName: string;
  category: ActivityCategory;
  subcategory: string;
  durationMinutes: number;
  confidence: number;
  signalSources: SignalSource[];
  rawContentStored: false;
  correctedAt?: string;
  correctionSource?: "user";
};

export type CollectorStatus = "live" | "history" | "simulator";

export type CollectorSession = ActivitySession & {
  fingerprint?: string;
  startDateMs?: number;
};

export type PrivacyPermission = {
  id: string;
  name: string;
  state: PermissionState;
  localOnly: boolean;
};

export type CategorySummary = {
  category: ActivityCategory;
  minutes: number;
  percent: number;
};

export type DashboardSummary = {
  totalMinutes: number;
  focusMinutes: number;
  idleMinutes: number;
  privacyScore: number;
  categorySummaries: CategorySummary[];
  focusBars: number[];
  currentSession: ActivitySession;
  insights: DailyInsights;
};

export type AppSummary = {
  appName: string;
  minutes: number;
  sessions: number;
};

export type DailyInsights = {
  correctedCount: number;
  dataQuality: number;
  lowConfidenceCount: number;
  strongestCategory: ActivityCategory | "none";
  topApps: AppSummary[];
};

const todaySessions: ActivitySession[] = [
  {
    id: "session-001",
    startTime: "09:10",
    endTime: "09:52",
    appName: "VS Code",
    category: "coding",
    subcategory: "Debugging activity classifier",
    durationMinutes: 42,
    confidence: 84,
    signalSources: ["active-app", "user-correction"],
    rawContentStored: false,
  },
  {
    id: "session-002",
    startTime: "09:55",
    endTime: "10:26",
    appName: "Chrome",
    category: "browsing",
    subcategory: "Researching local AI models",
    durationMinutes: 31,
    confidence: 78,
    signalSources: ["active-app", "browser-domain"],
    rawContentStored: false,
  },
  {
    id: "session-003",
    startTime: "10:32",
    endTime: "10:50",
    appName: "Discord",
    category: "communication",
    subcategory: "Voice call, active discussion",
    durationMinutes: 18,
    confidence: 81,
    signalSources: ["active-app", "app-state"],
    rawContentStored: false,
  },
  {
    id: "session-004",
    startTime: "11:04",
    endTime: "11:30",
    appName: "Steam",
    category: "gaming",
    subcategory: "Strategy game, active planning",
    durationMinutes: 26,
    confidence: 73,
    signalSources: ["active-app"],
    rawContentStored: false,
  },
  {
    id: "session-005",
    startTime: "11:38",
    endTime: "12:02",
    appName: "YouTube",
    category: "watching",
    subcategory: "Learning video, passive notes",
    durationMinutes: 24,
    confidence: 69,
    signalSources: ["active-app", "browser-domain"],
    rawContentStored: false,
  },
  {
    id: "session-006",
    startTime: "12:05",
    endTime: "12:19",
    appName: "Desktop",
    category: "idle",
    subcategory: "Away from keyboard",
    durationMinutes: 14,
    confidence: 96,
    signalSources: ["idle-detector"],
    rawContentStored: false,
  },
];

export const privacyPermissions: PrivacyPermission[] = [
  {
    id: "active-app",
    name: "Active app detection",
    state: "enabled",
    localOnly: true,
  },
  {
    id: "idle-detection",
    name: "Idle detection",
    state: "enabled",
    localOnly: true,
  },
  {
    id: "browser-domain",
    name: "Browser domain detection",
    state: "optional",
    localOnly: true,
  },
  {
    id: "discord-state",
    name: "Discord state detection",
    state: "optional",
    localOnly: true,
  },
  {
    id: "local-screenshot-ai",
    name: "Local screenshot AI",
    state: "disabled",
    localOnly: true,
  },
];

export function simulateTodayActivity(): ActivitySession[] {
  return todaySessions;
}

export function todayDateKey(): string {
  return formatDateKey(new Date());
}

export function offsetDateKey(dateKey: string, offsetDays: number): string {
  const date = new Date(`${dateKey}T12:00:00`);
  date.setDate(date.getDate() + offsetDays);
  return formatDateKey(date);
}

export function buildDashboardSummary(
  sessions: ActivitySession[],
  permissions: PrivacyPermission[],
): DashboardSummary {
  const totalMinutes = sessions.reduce((sum, session) => sum + session.durationMinutes, 0);
  const idleMinutes = sumByCategory(sessions, "idle");
  const focusMinutes = sessions
    .filter((session) => session.category === "coding" || session.category === "browsing")
    .reduce((sum, session) => sum + session.durationMinutes, 0);
  const categories: ActivityCategory[] = [
    "coding",
    "browsing",
    "communication",
    "gaming",
    "watching",
    "idle",
  ];

  const categorySummaries = categories.map((category) => {
    const minutes = sumByCategory(sessions, category);

    return {
      category,
      minutes,
      percent: totalMinutes > 0 ? Math.round((minutes / totalMinutes) * 100) : 0,
    };
  });

  const enabledPermissions = permissions.filter((permission) => permission.state === "enabled");
  const riskyPermissions = permissions.filter(
    (permission) => permission.id === "local-screenshot-ai" && permission.state === "enabled",
  );
  const privacyScore = Math.max(
    72,
    Math.round(100 - riskyPermissions.length * 16 - enabledPermissions.length * 1.5),
  );

  return {
    totalMinutes,
    focusMinutes,
    idleMinutes,
    privacyScore,
    categorySummaries,
    focusBars: buildFocusBars(sessions),
    currentSession: sessions[0] ?? createEmptySession(),
    insights: buildDailyInsights(sessions, categorySummaries),
  };
}

export function formatMinutes(minutes: number): string {
  const hours = Math.floor(minutes / 60);
  const remaining = minutes % 60;

  if (hours === 0) {
    return `${remaining}m`;
  }

  return `${hours}h ${remaining}m`;
}

function sumByCategory(sessions: ActivitySession[], category: ActivityCategory): number {
  return sessions
    .filter((session) => session.category === category)
    .reduce((sum, session) => sum + session.durationMinutes, 0);
}

function buildFocusBars(sessions: ActivitySession[]): number[] {
  if (sessions.length === 0) {
    return Array.from({ length: 12 }, () => 0);
  }

  const bars = Array.from({ length: 12 }, (_, index) => {
    const session = sessions[index % sessions.length];
    const activityWeight = session.category === "idle" ? 18 : session.category === "gaming" ? 48 : 68;
    const confidenceBoost = Math.round(session.confidence / 4);

    return Math.min(96, activityWeight + confidenceBoost + index * 2);
  });

  return bars;
}

function buildDailyInsights(
  sessions: ActivitySession[],
  categorySummaries: CategorySummary[],
): DailyInsights {
  const correctedCount = sessions.filter((session) =>
    session.signalSources.includes("user-correction") || session.correctionSource === "user",
  ).length;
  const lowConfidenceCount = sessions.filter((session) => session.confidence < 75).length;
  const averageConfidence = sessions.length === 0
    ? 0
    : Math.round(sessions.reduce((sum, session) => sum + session.confidence, 0) / sessions.length);
  const strongestCategory = categorySummaries.reduce<CategorySummary | null>((best, current) => {
    if (!best || current.minutes > best.minutes) return current;
    return best;
  }, null);

  return {
    correctedCount,
    dataQuality: averageConfidence,
    lowConfidenceCount,
    strongestCategory: strongestCategory && strongestCategory.minutes > 0 ? strongestCategory.category : "none",
    topApps: buildTopApps(sessions),
  };
}

function buildTopApps(sessions: ActivitySession[]): AppSummary[] {
  const appMap = new Map<string, AppSummary>();

  sessions.forEach((session) => {
    const existing = appMap.get(session.appName) ?? {
      appName: session.appName,
      minutes: 0,
      sessions: 0,
    };
    existing.minutes += session.durationMinutes;
    existing.sessions += 1;
    appMap.set(session.appName, existing);
  });

  return Array.from(appMap.values())
    .sort((left, right) => right.minutes - left.minutes)
    .slice(0, 5);
}

function formatDateKey(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function createEmptySession(): ActivitySession {
  return {
    id: "empty-session",
    startTime: "--:--",
    endTime: "--:--",
    appName: "No activity",
    category: "idle",
    subcategory: "No sessions recorded for this date",
    durationMinutes: 0,
    confidence: 0,
    signalSources: ["idle-detector"],
    rawContentStored: false,
  };
}
