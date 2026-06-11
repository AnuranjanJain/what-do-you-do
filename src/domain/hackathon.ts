export type HackathonStatus = "watching" | "applied" | "building" | "submitted";

export type HackathonTimelineEntry = {
  id: string;
  date: string;
  note: string;
};

export type Hackathon = {
  id: string;
  title: string;
  organizer: string;
  url: string;
  status: HackathonStatus;
  appliedDate: string;
  deadline: string;
  progress: number;
  plan: string;
  workDone: string;
  timeline: HackathonTimelineEntry[];
  createdAt: string;
  updatedAt: string;
};

export type HackathonDraft = Pick<
  Hackathon,
  "appliedDate" | "deadline" | "organizer" | "plan" | "progress" | "status" | "title" | "url" | "workDone"
>;

export const emptyHackathonDraft: HackathonDraft = {
  title: "",
  organizer: "",
  url: "",
  status: "watching",
  appliedDate: "",
  deadline: "",
  progress: 0,
  plan: "",
  workDone: "",
};

export type HackathonSourceUpdate = {
  id: number;
  platform: string;
  source: string;
  event_type: string;
  title: string;
  summary: string;
  action_needed: string;
  deadline: string | null;
  is_read: boolean;
  occurred_at: string | null;
  created_at: string;
};

export type AiosHackathon = {
  id: number;
  title: string;
  organizer: string;
  platform: string;
  status: string;
  source: string;
  deadline: string | null;
  notes: string;
  unread_updates: number;
  updated_at: string;
  updates: HackathonSourceUpdate[];
};

export type HackathonConnectorRun = {
  id: number;
  connector_id: string;
  status: string;
  message: string;
  records_seen: number;
  records_imported: number;
  created_at: string;
};

export type HackathonFeed = {
  hackathons: AiosHackathon[];
  connectors: HackathonConnectorRun[];
  unread_updates: number;
  updated_at: string;
};
