import { ActivityCategory, ActivitySession, CollectorSession } from "../domain/activity";

const collectorBaseUrl = "http://127.0.0.1:17321";
const collectorTokenStorageKey = "wdyd.collector.token.v1";

type CollectorSessionsResponse = {
  ok: boolean;
  date: string;
  activeDateKey: string;
  isLiveDate: boolean;
  currentSession: CollectorSession | null;
  sessions: CollectorSession[];
  availableDates: string[];
};

export type CollectorSessionsResult = {
  activeDateKey: string;
  availableDates: string[];
  date: string;
  isLiveDate: boolean;
  sessions: ActivitySession[];
};

async function getCollectorToken(forceRefresh = false): Promise<string> {
  const stored = forceRefresh ? null : window.localStorage.getItem(collectorTokenStorageKey);
  if (stored) return stored;

  const response = await fetch(`${collectorBaseUrl}/auth/token`, {
    cache: "no-store",
  });
  const data = (await response.json().catch(() => ({}))) as { token?: string; error?: string };
  if (!response.ok || !data.token) {
    throw new Error(data.error ?? "The local collector is not ready. Start it and try again.");
  }

  window.localStorage.setItem(collectorTokenStorageKey, data.token);
  return data.token;
}

export async function collectorFetch(path: string, init: RequestInit = {}): Promise<Response> {
  const token = await getCollectorToken();
  const headers = new Headers(init.headers);
  headers.set("Authorization", `Bearer ${token}`);
  const response = await fetch(`${collectorBaseUrl}${path}`, { ...init, headers });
  if (response.status !== 401) return response;

  window.localStorage.removeItem(collectorTokenStorageKey);
  const refreshedToken = await getCollectorToken(true);
  headers.set("Authorization", `Bearer ${refreshedToken}`);
  return fetch(`${collectorBaseUrl}${path}`, { ...init, headers });
}

export async function fetchLiveSessions(date: string): Promise<CollectorSessionsResult> {
  const searchParams = new URLSearchParams({ date });
  const response = await collectorFetch(`/sessions?${searchParams.toString()}`, {
    cache: "no-store",
  });

  if (!response.ok) {
    throw new Error(`Collector responded with ${response.status}`);
  }

  const data: unknown = await response.json();

  if (!isCollectorSessionsResponse(data) || !data.ok) {
    throw new Error("Collector has no sessions yet");
  }

  return {
    activeDateKey: data.activeDateKey,
    availableDates: data.availableDates,
    date: data.date,
    isLiveDate: data.isLiveDate,
    sessions: data.sessions.map((session) => ({
      id: session.id,
      startTime: session.startTime,
      endTime: session.endTime,
      appName: session.appName,
      category: session.category,
      subcategory: session.subcategory,
      durationMinutes: session.durationMinutes,
      confidence: session.confidence,
      correctedAt: session.correctedAt,
      correctionSource: session.correctionSource,
      note: session.note,
      notedAt: session.notedAt,
      signalSources: session.signalSources,
      rawContentStored: false,
    })),
  };
}

function isCollectorSessionsResponse(value: unknown): value is CollectorSessionsResponse {
  if (!value || typeof value !== "object") return false;
  const data = value as Partial<CollectorSessionsResponse>;
  if (
    typeof data.ok !== "boolean" ||
    typeof data.date !== "string" ||
    typeof data.activeDateKey !== "string" ||
    typeof data.isLiveDate !== "boolean" ||
    !Array.isArray(data.availableDates) ||
    !Array.isArray(data.sessions)
  ) {
    return false;
  }

  return data.availableDates.every((date) => typeof date === "string") && data.sessions.every((session) => (
    Boolean(session) &&
    typeof session.id === "string" &&
    typeof session.startTime === "string" &&
    typeof session.endTime === "string" &&
    typeof session.appName === "string" &&
    typeof session.subcategory === "string" &&
    typeof session.durationMinutes === "number" &&
    typeof session.confidence === "number" &&
    Array.isArray(session.signalSources)
  ));
}

export async function correctLiveSession({
  category,
  date,
  sessionId,
  subcategory,
}: {
  category: ActivityCategory;
  date: string;
  sessionId: string;
  subcategory: string;
}): Promise<void> {
  const response = await collectorFetch("/sessions/correct", {
    body: JSON.stringify({ category, date, sessionId, subcategory }),
    cache: "no-store",
    headers: {
      "Content-Type": "application/json",
    },
    method: "POST",
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ error: `Collector responded with ${response.status}` }));
    throw new Error(error.error ?? "Unable to correct session");
  }
}

export async function saveSessionNote({
  date,
  note,
  sessionId,
}: {
  date: string;
  note: string;
  sessionId: string;
}): Promise<void> {
  const response = await collectorFetch("/sessions/note", {
    body: JSON.stringify({ date, note, sessionId }),
    cache: "no-store",
    headers: {
      "Content-Type": "application/json",
    },
    method: "POST",
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ error: `Collector responded with ${response.status}` }));
    throw new Error(error.error ?? "Unable to save note");
  }
}
