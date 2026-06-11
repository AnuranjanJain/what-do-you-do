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
  received_at: string;
  occurred_at: string | null;
  created_at: string;
};

export type AiosHackathon = {
  id: number;
  title: string;
  organizer: string;
  platform: string;
  status: string;
  category: "opening" | "live" | "applied" | "previous";
  source: string;
  deadline: string | null;
  applied_at: string | null;
  received_at: string;
  notes: string;
  unread_updates: number;
  metrics: {
    total_updates: number;
    unread_updates: number;
    has_applied: boolean;
    days_since_applied: number | null;
    days_to_deadline: number | null;
  };
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

export type PlacementSourceUpdate = {
  id: number;
  source: string;
  event_type: string;
  title: string;
  summary: string;
  action_needed: string;
  deadline: string | null;
  is_read: boolean;
  received_at: string;
  occurred_at: string | null;
  created_at: string;
};

export type AiosPlacement = {
  id: number;
  title: string;
  company: string;
  status: string;
  category: string;
  source: string;
  deadline: string | null;
  applied_at: string | null;
  received_at: string;
  notes: string;
  unread_updates: number;
  metrics: {
    total_updates: number;
    unread_updates: number;
    has_applied: boolean;
    days_since_applied: number | null;
    days_to_deadline: number | null;
  };
  updated_at: string;
  updates: PlacementSourceUpdate[];
};

export type PlacementFeed = {
  placements: AiosPlacement[];
  connectors: HackathonConnectorRun[];
  unread_updates: number;
  updated_at: string;
};
