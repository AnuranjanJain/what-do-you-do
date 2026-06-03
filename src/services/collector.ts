import { ActivityCategory, ActivitySession, CollectorSession } from "../domain/activity";

const collectorBaseUrl = "http://127.0.0.1:17321";

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

export async function fetchLiveSessions(date: string): Promise<CollectorSessionsResult> {
  const searchParams = new URLSearchParams({ date });
  const response = await fetch(`${collectorBaseUrl}/sessions?${searchParams.toString()}`, {
    cache: "no-store",
  });

  if (!response.ok) {
    throw new Error(`Collector responded with ${response.status}`);
  }

  const data = (await response.json()) as CollectorSessionsResponse;

  if (!data.ok || !Array.isArray(data.sessions)) {
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
      signalSources: session.signalSources,
      rawContentStored: false,
    })),
  };
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
  const response = await fetch(`${collectorBaseUrl}/sessions/correct`, {
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
