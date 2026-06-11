import { AiosHackathon, Hackathon, HackathonDraft, HackathonFeed, PlacementFeed } from "../domain/hackathon";
import { getAiosBaseUrl } from "./aios";

const collectorBaseUrl = "http://127.0.0.1:17321";

type HackathonsResponse = {
  ok: boolean;
  hackathons: Hackathon[];
};

export async function fetchHackathons(): Promise<Hackathon[]> {
  const response = await fetch(`${collectorBaseUrl}/hackathons`, {
    cache: "no-store",
  });

  if (!response.ok) {
    throw new Error(`Hackathon store responded with ${response.status}`);
  }

  const data = (await response.json()) as HackathonsResponse;
  return Array.isArray(data.hackathons) ? data.hackathons : [];
}

export async function saveHackathon(
  hackathon: HackathonDraft & { id?: string; timeline?: Hackathon["timeline"] },
): Promise<Hackathon> {
  const response = await fetch(`${collectorBaseUrl}/hackathons/save`, {
    body: JSON.stringify(hackathon),
    cache: "no-store",
    headers: {
      "Content-Type": "application/json",
    },
    method: "POST",
  });

  const data = await response.json().catch(() => ({}));

  if (!response.ok) {
    throw new Error(data.error ?? "Unable to save hackathon");
  }

  return data.hackathon as Hackathon;
}

export async function addHackathonTimelineEntry(
  hackathonId: string,
  note: string,
): Promise<Hackathon> {
  const response = await fetch(`${collectorBaseUrl}/hackathons/timeline`, {
    body: JSON.stringify({ hackathonId, note }),
    cache: "no-store",
    headers: {
      "Content-Type": "application/json",
    },
    method: "POST",
  });

  const data = await response.json().catch(() => ({}));

  if (!response.ok) {
    throw new Error(data.error ?? "Unable to add timeline update");
  }

  return data.hackathon as Hackathon;
}

export async function deleteHackathon(hackathonId: string): Promise<void> {
  const response = await fetch(`${collectorBaseUrl}/hackathons/delete`, {
    body: JSON.stringify({ hackathonId }),
    cache: "no-store",
    headers: {
      "Content-Type": "application/json",
    },
    method: "POST",
  });

  if (!response.ok) {
    const data = await response.json().catch(() => ({}));
    throw new Error(data.error ?? "Unable to delete hackathon");
  }
}

export async function fetchAiosHackathons(): Promise<HackathonFeed> {
  const response = await fetchAiosSource("/api/hackathons", {
    cache: "no-store",
    credentials: "include",
  });

  if (response.status === 401) {
    throw new Error("AiOS is locked. Unlock it to receive hackathon updates.");
  }
  if (!response.ok) {
    throw new Error(`AiOS hackathon feed responded with ${response.status}`);
  }

  return response.json() as Promise<HackathonFeed>;
}

export async function refreshAiosHackathons(): Promise<void> {
  const response = await fetchAiosSource("/api/hackathons/refresh", {
    cache: "no-store",
    credentials: "include",
    method: "POST",
  });

  if (response.status === 401) {
    throw new Error("AiOS is locked. Unlock it before scanning sources.");
  }
  if (!response.ok) {
    const data = await response.json().catch(() => ({}));
    throw new Error(data.error ?? `Hackathon scan failed with ${response.status}`);
  }
}

export async function markHackathonUpdateRead(updateId: number): Promise<void> {
  const response = await fetchAiosSource(`/api/hackathon-updates/${updateId}/read`, {
    cache: "no-store",
    credentials: "include",
    method: "POST",
  });

  if (!response.ok) {
    throw new Error(`Unable to mark update as read: ${response.status}`);
  }
}

export async function fetchAiosPlacements(): Promise<PlacementFeed> {
  const response = await fetchAiosSource("/api/placements", {
    cache: "no-store",
    credentials: "include",
  });

  if (response.status === 401) {
    throw new Error("AiOS is locked. Unlock it to receive placement updates.");
  }
  if (!response.ok) {
    throw new Error(`AiOS placement feed responded with ${response.status}`);
  }

  return response.json() as Promise<PlacementFeed>;
}

export async function fetchAiosNeoPat(): Promise<PlacementFeed> {
  const response = await fetchAiosSource("/api/neopat", {
    cache: "no-store",
    credentials: "include",
  });

  if (response.status === 401) {
    throw new Error("AiOS is locked. Unlock it to receive NeoPat updates.");
  }
  if (!response.ok) {
    throw new Error(`AiOS NeoPat feed responded with ${response.status}`);
  }

  return response.json() as Promise<PlacementFeed>;
}

export async function refreshAiosPlacements(): Promise<void> {
  const response = await fetchAiosSource("/api/placements/refresh", {
    cache: "no-store",
    credentials: "include",
    method: "POST",
  });

  if (response.status === 401) {
    throw new Error("AiOS is locked. Unlock it before scanning placement sources.");
  }
  if (!response.ok) {
    const data = await response.json().catch(() => ({}));
    throw new Error(data.error ?? `Placement scan failed with ${response.status}`);
  }
}

export async function markPlacementUpdateRead(updateId: number): Promise<void> {
  const response = await fetchAiosSource(`/api/placement-updates/${updateId}/read`, {
    cache: "no-store",
    credentials: "include",
    method: "POST",
  });

  if (!response.ok) {
    throw new Error(`Unable to mark placement update as read: ${response.status}`);
  }
}

export function findMatchingLocalHackathon(
  sourceHackathon: AiosHackathon,
  localHackathons: Hackathon[],
): Hackathon | undefined {
  const normalizedTitle = normalizeTitle(sourceHackathon.title);
  return localHackathons.find((hackathon) => {
    const candidate = normalizeTitle(hackathon.title);
    return candidate === normalizedTitle || candidate.includes(normalizedTitle) || normalizedTitle.includes(candidate);
  });
}

function normalizeTitle(value: string): string {
  return value.toLowerCase().replace(/[^a-z0-9]+/g, " ").trim();
}

async function fetchAiosSource(path: string, init: RequestInit): Promise<Response> {
  const urls = Array.from(new Set([getAiosBaseUrl(), "http://127.0.0.1:5000"]));
  let lastError: unknown = null;

  for (const baseUrl of urls) {
    try {
      const response = await fetch(`${baseUrl}${path}`, init);
      if (response.ok || response.status === 401) {
        return response;
      }
      lastError = new Error(`AiOS source responded with ${response.status}`);
    } catch (error) {
      lastError = error;
    }
  }

  throw lastError instanceof Error ? lastError : new Error("Unable to reach AiOS source feed.");
}
