import { ActivitySession, CollectorSession } from "../domain/activity";

const collectorBaseUrl = "http://127.0.0.1:17321";

type CollectorSessionsResponse = {
  ok: boolean;
  currentSession: CollectorSession | null;
  sessions: CollectorSession[];
};

export async function fetchLiveSessions(): Promise<ActivitySession[]> {
  const response = await fetch(`${collectorBaseUrl}/sessions`, {
    cache: "no-store",
  });

  if (!response.ok) {
    throw new Error(`Collector responded with ${response.status}`);
  }

  const data = (await response.json()) as CollectorSessionsResponse;

  if (!data.ok || !Array.isArray(data.sessions) || data.sessions.length === 0) {
    throw new Error("Collector has no sessions yet");
  }

  return data.sessions.map((session) => ({
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
  }));
}
