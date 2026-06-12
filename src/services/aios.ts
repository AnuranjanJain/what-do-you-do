import { ActivitySession } from "../domain/activity";

const defaultAiosBaseUrl = "http://127.0.0.1:5000";
const sentSessionStorageKey = "wdyd.aios.sentSessions.v1";
const aiosBaseUrlStorageKey = "wdyd.aios.baseUrl";

export type AiosStatus = "not-installed" | "checking" | "connected" | "locked" | "syncing";

export type AiosLiveStatus = {
  ok: boolean;
  locked: boolean;
  stats?: {
    wellbeing_minutes?: number;
    reminders_due?: number;
    opportunities?: number;
  };
  updatedAt?: string;
};

export type AiosSyncResult = {
  pendingBeforeSync: number;
  sent: number;
  skipped: number;
  locked: boolean;
};

export function getAiosBaseUrl(): string {
  const saved = window.localStorage.getItem(aiosBaseUrlStorageKey);

  if (!saved) {
    return defaultAiosBaseUrl;
  }

  try {
    return normalizeBaseUrl(saved);
  } catch {
    window.localStorage.removeItem(aiosBaseUrlStorageKey);
    return defaultAiosBaseUrl;
  }
}

export function setAiosBaseUrl(baseUrl: string): string {
  const normalized = normalizeBaseUrl(baseUrl);
  window.localStorage.setItem(aiosBaseUrlStorageKey, normalized);
  return normalized;
}

export function countPendingAiosSessions(sessions: ActivitySession[]): number {
  const sentSessionIds = readSentSessionIds();
  return getSyncableSessions(sessions, sentSessionIds, Number.POSITIVE_INFINITY).length;
}

export function clearAiosSyncHistory(): void {
  window.localStorage.removeItem(sentSessionStorageKey);
}

export async function checkAiosConnection(): Promise<AiosLiveStatus> {
  const response = await fetch(`${getAiosBaseUrl()}/api/live`, {
    cache: "no-store",
    credentials: "include",
  });

  if (response.status === 401) {
    return { ok: false, locked: true };
  }

  if (!response.ok) {
    throw new Error(`AiOS responded with ${response.status}`);
  }

  const data = await response.json();

  return {
    ok: true,
    locked: false,
    stats: data.stats,
    updatedAt: data.updated_at,
  };
}

export async function syncActivitySessions(sessions: ActivitySession[]): Promise<AiosSyncResult> {
  const sentSessionIds = readSentSessionIds();
  const pendingBeforeSync = getSyncableSessions(sessions, sentSessionIds, Number.POSITIVE_INFINITY).length;
  const syncableSessions = getSyncableSessions(sessions, sentSessionIds, 5);

  let sent = 0;

  for (const session of syncableSessions) {
    const response = await fetch(`${getAiosBaseUrl()}/api/wellbeing/activity`, {
      body: JSON.stringify(toAiosPayload(session)),
      cache: "no-store",
      credentials: "include",
      headers: {
        "Content-Type": "application/json",
      },
      method: "POST",
    });

    if (response.status === 401) {
      return {
        pendingBeforeSync,
        sent,
        skipped: pendingBeforeSync - sent,
        locked: true,
      };
    }

    if (!response.ok) {
      throw new Error(`AiOS sync failed with ${response.status}`);
    }

    sentSessionIds.add(session.id);
    sent += 1;
  }

  writeSentSessionIds(sentSessionIds);

  return {
    pendingBeforeSync,
    sent,
    skipped: pendingBeforeSync - sent,
    locked: false,
  };
}

function getSyncableSessions(
  sessions: ActivitySession[],
  sentSessionIds: Set<string>,
  limit: number,
): ActivitySession[] {
  return sessions
    .filter((session) => session.id !== "empty-session" && session.durationMinutes > 0)
    .filter((session) => !sentSessionIds.has(session.id))
    .slice(0, limit);
}

function toAiosPayload(session: ActivitySession) {
  return {
    source: "what-do-you-do",
    app_name: session.appName,
    category: mapCategoryForAios(session.category),
    duration_minutes: session.durationMinutes,
    planned_task: "Private activity timeline",
    actual_task: `${session.subcategory} (${session.startTime}-${session.endTime})`,
  };
}

function mapCategoryForAios(category: ActivitySession["category"]): string {
  if (category === "coding" || category === "browsing") return "deep_work";
  if (category === "watching") return "entertainment";
  if (category === "communication") return "social";
  return category;
}

function readSentSessionIds(): Set<string> {
  try {
    const saved = JSON.parse(window.localStorage.getItem(sentSessionStorageKey) || "[]");
    return new Set(Array.isArray(saved) ? saved.map(String) : []);
  } catch {
    return new Set();
  }
}

function writeSentSessionIds(sessionIds: Set<string>) {
  const compactIds = Array.from(sessionIds).slice(-500);
  window.localStorage.setItem(sentSessionStorageKey, JSON.stringify(compactIds));
}

function normalizeBaseUrl(baseUrl: string): string {
  const trimmed = baseUrl.trim().replace(/\/+$/, "");

  if (!trimmed) {
    return defaultAiosBaseUrl;
  }

  const candidate = /^https?:\/\//i.test(trimmed) ? trimmed : `http://${trimmed}`;
  const parsed = new URL(candidate);
  const isLoopback = parsed.hostname === "127.0.0.1"
    || parsed.hostname === "localhost"
    || parsed.hostname === "::1"
    || parsed.hostname === "[::1]";

  if (!isLoopback || !["http:", "https:"].includes(parsed.protocol)) {
    throw new Error("AiOS API must use localhost or a loopback address.");
  }

  parsed.username = "";
  parsed.password = "";
  parsed.hash = "";
  parsed.search = "";
  return parsed.toString().replace(/\/+$/, "");
}
