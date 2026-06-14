import React, { useEffect, useMemo, useState } from "react";
import ReactDOM from "react-dom/client";
import {
  Activity,
  Bell,
  Bot,
  BriefcaseBusiness,
  CalendarDays,
  Check,
  Clock3,
  Code2,
  Database,
  EyeOff,
  Inbox,
  Gamepad2,
  Gauge,
  LayoutDashboard,
  Mail,
  MessageCircle,
  MonitorSmartphone,
  Moon,
  Pause,
  PieChart,
  Plus,
  RefreshCw,
  StickyNote,
  Search,
  Settings2,
  ShieldCheck,
  Sun,
  Trash2,
  TimerReset,
  Trophy,
  Tv,
  Zap,
} from "lucide-react";
import {
  ActivityCategory,
  ActivitySession,
  CollectorStatus,
  PrivacyPermission,
  buildDashboardSummary,
  formatMinutes,
  offsetDateKey,
  privacyPermissions,
  simulateTodayActivity,
  todayDateKey,
} from "./domain/activity";
import {
  AiosHackathon,
  Hackathon,
  HackathonDraft,
  HackathonFeed,
  HackathonStatus,
  PlacementFeed,
  emptyHackathonDraft,
} from "./domain/hackathon";
import {
  AiosLiveStatus,
  AiosStatus,
  checkAiosConnection,
  clearAiosSyncHistory,
  countPendingAiosSessions,
  getAiosBaseUrl,
  setAiosBaseUrl,
  syncActivitySessions,
} from "./services/aios";
import { correctLiveSession, fetchLiveSessions, saveSessionNote } from "./services/collector";
import {
  DesktopRuntimeStatus,
  ensureDesktopCollector,
  getDesktopRuntimeStatus,
  isDesktopApp,
  stopDesktopCollector,
} from "./services/desktop";
import {
  addHackathonTimelineEntry,
  deleteHackathon,
  fetchAiosHackathons,
  fetchAiosNeoPat,
  fetchAiosPlacements,
  fetchHackathons,
  findMatchingLocalHackathon,
  markHackathonUpdateRead,
  markPlacementUpdateRead,
  refreshAiosHackathons,
  refreshAiosPlacements,
  saveHackathon,
} from "./services/hackathons";
import "./styles.css";

const categoryMeta: Record<
  ActivityCategory,
  { label: string; icon: React.ElementType; color: string }
> = {
  coding: { label: "Coding", icon: Code2, color: "green" },
  browsing: { label: "Research", icon: Search, color: "cyan" },
  communication: { label: "Discord", icon: MessageCircle, color: "pink" },
  gaming: { label: "Gaming", icon: Gamepad2, color: "amber" },
  watching: { label: "Learning", icon: Tv, color: "blue" },
  idle: { label: "Idle", icon: Pause, color: "muted" },
};

const permissionIcons: Record<string, React.ElementType> = {
  "active-app": Activity,
  "idle-detection": Clock3,
  "browser-domain": Search,
  "discord-state": MessageCircle,
  "local-screenshot-ai": EyeOff,
};

const agentFeatures = [
  { name: "Reminders", unlockedStatus: "Ready through AI Agent", icon: Bell },
  { name: "Important memory", unlockedStatus: "Ready through AI Agent", icon: Database },
  { name: "Email insights", unlockedStatus: "Ready through AI Agent", icon: Mail },
  { name: "Job tracking", unlockedStatus: "Ready through AI Agent", icon: BriefcaseBusiness },
];

const projectAiAgent = {
  cwd: "C:\\Users\\anura\\Documents\\Ai Agent",
  localUrl: "http://127.0.0.1:5000/",
  threadId: "019e4a40-fd50-7f92-b46e-1a1548dfdd94",
  threadTitle: "Build AI agent like ChatGPT",
  threadUrl: "codex://threads/019e4a40-fd50-7f92-b46e-1a1548dfdd94",
};

const categoryOptions: ActivityCategory[] = [
  "coding",
  "browsing",
  "communication",
  "gaming",
  "watching",
  "idle",
];

const hackathonColumns: { status: HackathonStatus; label: string }[] = [
  { status: "watching", label: "Watching" },
  { status: "applied", label: "Applied" },
  { status: "building", label: "Building" },
  { status: "submitted", label: "Submitted" },
];

function App() {
  const [theme, setTheme] = useState<"light" | "dark">(
    () => (window.localStorage.getItem("wdyd.theme") as "light" | "dark" | null) ?? "light",
  );
  const [collectorStatus, setCollectorStatus] = useState<CollectorStatus>("simulator");
  const [selectedDate, setSelectedDate] = useState(() => todayDateKey());
  const [activeDateKey, setActiveDateKey] = useState(() => todayDateKey());
  const [availableDates, setAvailableDates] = useState<string[]>([]);
  const [agentStatus, setAgentStatus] = useState<AiosStatus>("not-installed");
  const [agentLive, setAgentLive] = useState<AiosLiveStatus | null>(null);
  const [agentMessage, setAgentMessage] = useState("AiOS has not been checked in this session.");
  const [agentLastSync, setAgentLastSync] = useState("");
  const [agentAutoSync, setAgentAutoSync] = useState(
    () => window.localStorage.getItem("wdyd.aios.autoSync") === "true",
  );
  const [agentBaseUrl, setAgentBaseUrlState] = useState(() => getAiosBaseUrl());
  const [agentPendingCount, setAgentPendingCount] = useState(0);
  const [widgetMode, setWidgetMode] = useState<"desktop" | "mobile">("desktop");
  const [privacyExpanded, setPrivacyExpanded] = useState(false);
  const [trackingPaused, setTrackingPaused] = useState(false);
  const [desktopRuntime, setDesktopRuntime] = useState<DesktopRuntimeStatus | null>(null);
  const [desktopRuntimeBusy, setDesktopRuntimeBusy] = useState(false);
  const [correctionMode, setCorrectionMode] = useState(false);
  const [correctionMessage, setCorrectionMessage] = useState("");
  const [noteMode, setNoteMode] = useState(false);
  const [noteMessage, setNoteMessage] = useState("");
  const [hackathons, setHackathons] = useState<Hackathon[]>([]);
  const [hackathonFeed, setHackathonFeed] = useState<HackathonFeed | null>(null);
  const [placementFeed, setPlacementFeed] = useState<PlacementFeed | null>(null);
  const [neopatFeed, setNeopatFeed] = useState<PlacementFeed | null>(null);
  const [hackathonMessage, setHackathonMessage] = useState("Loading local hackathon tracker.");
  const [hackathonSourceMessage, setHackathonSourceMessage] = useState("Connecting to AiOS sources.");
  const [placementSourceMessage, setPlacementSourceMessage] = useState("Connecting to placement sources.");
  const [neopatSourceMessage, setNeopatSourceMessage] = useState("Connecting to NeoPat folder.");
  const [hackathonRefreshing, setHackathonRefreshing] = useState(false);
  const [placementRefreshing, setPlacementRefreshing] = useState(false);
  const [hackathonFormOpen, setHackathonFormOpen] = useState(false);
  const [editingHackathon, setEditingHackathon] = useState<Hackathon | null>(null);
  const [sessions, setSessions] = useState<ActivitySession[]>(() => simulateTodayActivity());

  useEffect(() => {
    let cancelled = false;

    async function refreshLiveSessions() {
      if (trackingPaused) {
        return;
      }

      try {
        const result = await fetchLiveSessions(selectedDate);
        if (!cancelled) {
          setSessions(result.sessions);
          setActiveDateKey(result.activeDateKey);
          setAvailableDates(result.availableDates);
          setCollectorStatus(result.isLiveDate ? "live" : "history");
        }
      } catch {
        if (!cancelled) {
          setSessions(simulateTodayActivity());
          setActiveDateKey(todayDateKey());
          setAvailableDates([]);
          setCollectorStatus("simulator");
        }
      }
    }

    refreshLiveSessions();
    const intervalId = window.setInterval(refreshLiveSessions, 3000);

    return () => {
      cancelled = true;
      window.clearInterval(intervalId);
    };
  }, [selectedDate, trackingPaused]);

  useEffect(() => {
    document.documentElement.dataset.theme = theme;
    window.localStorage.setItem("wdyd.theme", theme);
  }, [theme]);

  useEffect(() => {
    let cancelled = false;

    async function initializeDesktopRuntime() {
      try {
        const status = isDesktopApp()
          ? await ensureDesktopCollector()
          : await getDesktopRuntimeStatus();
        if (!cancelled) setDesktopRuntime(status);
      } catch (error) {
        if (!cancelled) {
          setDesktopRuntime({
            collectorManaged: false,
            collectorPid: null,
            collectorRunning: false,
            collectorUrl: "http://127.0.0.1:17321",
            desktop: isDesktopApp(),
            message: error instanceof Error ? error.message : "Unable to initialize desktop runtime.",
            storagePath: null,
          });
        }
      }
    }

    initializeDesktopRuntime();
    const refreshTimer = window.setInterval(async () => {
      try {
        const status = await getDesktopRuntimeStatus();
        if (!cancelled) setDesktopRuntime(status);
      } catch {
        // Keep the last known native status while the desktop runtime recovers.
      }
    }, 5000);

    return () => {
      cancelled = true;
      window.clearInterval(refreshTimer);
    };
  }, []);

  useEffect(() => {
    refreshHackathons();
    refreshHackathonFeed();
    refreshPlacementFeed();
    refreshNeoPatFeed();
    const intervalId = window.setInterval(() => {
      refreshHackathonFeed();
      refreshPlacementFeed();
      refreshNeoPatFeed();
    }, 30000);
    return () => window.clearInterval(intervalId);
  }, []);

  const summary = useMemo(
    () => buildDashboardSummary(sessions, privacyPermissions),
    [sessions],
  );
  const current = summary.currentSession;
  const currentMeta = categoryMeta[current.category];
  const hasData = sessions.length > 0;
  const isFutureDate = selectedDate > activeDateKey;
  const isToday = selectedDate === activeDateKey;
  const visibleTimeline = sessions.slice(0, 15);
  const logEntries = sessions.slice(15);

  useEffect(() => {
    setAgentPendingCount(countPendingAiosSessions(sessions));
  }, [sessions, agentLastSync]);

  useEffect(() => {
    window.localStorage.setItem("wdyd.aios.autoSync", String(agentAutoSync));
  }, [agentAutoSync]);

  useEffect(() => {
    if (!agentAutoSync || !hasData || trackingPaused || selectedDate !== activeDateKey) {
      return;
    }

    const intervalId = window.setInterval(() => {
      if (countPendingAiosSessions(sessions) > 0) {
        syncCurrentSessions("auto");
      }
    }, 15000);

    return () => window.clearInterval(intervalId);
  }, [activeDateKey, agentAutoSync, hasData, selectedDate, sessions, trackingPaused]);

  async function refreshSelectedDate() {
    const result = await fetchLiveSessions(selectedDate);
    setSessions(result.sessions);
    setActiveDateKey(result.activeDateKey);
    setAvailableDates(result.availableDates);
    setCollectorStatus(result.isLiveDate ? "live" : "history");
  }

  async function refreshHackathons() {
    try {
      const savedHackathons = await fetchHackathons();
      setHackathons(savedHackathons);
      setHackathonMessage(
        savedHackathons.length > 0
          ? `${savedHackathons.length} hackathon${savedHackathons.length === 1 ? "" : "s"} tracked locally.`
          : "No hackathons tracked yet.",
      );
    } catch (error) {
      setHackathonMessage(
        error instanceof Error ? error.message : "Start the local collector to use hackathon tracking.",
      );
    }
  }

  async function refreshHackathonFeed() {
    try {
      const feed = await fetchAiosHackathons();
      setHackathonFeed(feed);
      setHackathonSourceMessage(
        feed.unread_updates > 0
          ? `${feed.unread_updates} unread source update${feed.unread_updates === 1 ? "" : "s"}.`
          : "Mail and platform sources are up to date.",
      );
    } catch (error) {
      setHackathonSourceMessage(
        error instanceof Error ? error.message : "Unable to read hackathon sources from AiOS.",
      );
    }
  }

  async function refreshPlacementFeed() {
    try {
      const feed = await fetchAiosPlacements();
      setPlacementFeed(feed);
      setPlacementSourceMessage(
        feed.unread_updates > 0
          ? `${feed.unread_updates} unread placement update${feed.unread_updates === 1 ? "" : "s"}.`
          : "Placement mail sources are up to date.",
      );
    } catch (error) {
      setPlacementSourceMessage(
        error instanceof Error ? error.message : "Unable to read placement sources from AiOS.",
      );
    }
  }

  async function refreshNeoPatFeed() {
    try {
      const feed = await fetchAiosNeoPat();
      setNeopatFeed(feed);
      setNeopatSourceMessage(
        feed.unread_updates > 0
          ? `${feed.unread_updates} unread NeoPat update${feed.unread_updates === 1 ? "" : "s"}.`
          : "NeoPat practice-test mails are up to date.",
      );
    } catch (error) {
      setNeopatSourceMessage(error instanceof Error ? error.message : "Unable to read NeoPat sources from AiOS.");
    }
  }

  async function handleRefreshHackathonSources() {
    setHackathonRefreshing(true);
    setHackathonSourceMessage("Scanning Gmail and platform sources.");
    try {
      await refreshAiosHackathons();
      await refreshHackathonFeed();
    } catch (error) {
      setHackathonSourceMessage(error instanceof Error ? error.message : "Hackathon source scan failed.");
    } finally {
      setHackathonRefreshing(false);
    }
  }

  async function handleRefreshPlacementSources() {
    setPlacementRefreshing(true);
    setPlacementSourceMessage("Scanning Gmail and job portal sources.");
    try {
      await refreshAiosPlacements();
      await refreshPlacementFeed();
    } catch (error) {
      setPlacementSourceMessage(error instanceof Error ? error.message : "Placement source scan failed.");
    } finally {
      setPlacementRefreshing(false);
    }
  }

  async function handleMarkHackathonUpdateRead(updateId: number) {
    await markHackathonUpdateRead(updateId);
    await refreshHackathonFeed();
  }

  async function handleMarkPlacementUpdateRead(updateId: number) {
    await markPlacementUpdateRead(updateId);
    await refreshPlacementFeed();
    await refreshNeoPatFeed();
  }

  async function handleAddSourceHackathon(sourceHackathon: AiosHackathon) {
    const existing = findMatchingLocalHackathon(sourceHackathon, hackathons);
    if (existing) {
      setEditingHackathon(existing);
      setHackathonFormOpen(true);
      setHackathonMessage("This source is already on your board. Review and update its plan.");
      return;
    }

    await saveHackathon({
      title: sourceHackathon.title,
      organizer: sourceHackathon.organizer,
      url: "",
      status: mapSourceHackathonStatus(sourceHackathon.status),
      appliedDate: sourceHackathon.status === "Applied" ? todayDateKey() : "",
      deadline: sourceHackathon.deadline?.slice(0, 10) ?? "",
      progress: sourceHackathon.status === "Submitted" ? 100 : 0,
      plan: sourceHackathon.updates[0]?.action_needed || sourceHackathon.notes,
      workDone: sourceHackathon.updates[0]?.summary || "",
      timeline: sourceHackathon.updates.slice(0, 8).map((update) => ({
        id: `aios-${update.id}`,
        date: update.occurred_at || update.created_at,
        note: `${update.platform}: ${update.title}`,
      })),
    });
    await refreshHackathons();
    setHackathonMessage(`${sourceHackathon.title} added from AiOS sources.`);
  }

  async function handleSaveHackathon(draft: HackathonDraft) {
    await saveHackathon({
      ...draft,
      id: editingHackathon?.id,
      timeline: editingHackathon?.timeline,
    });
    setEditingHackathon(null);
    setHackathonFormOpen(false);
    await refreshHackathons();
    setHackathonMessage("Hackathon saved locally.");
  }

  async function handleHackathonTimeline(hackathonId: string, note: string) {
    await addHackathonTimelineEntry(hackathonId, note);
    await refreshHackathons();
    setHackathonMessage("Timeline update saved locally.");
  }

  async function handleDeleteHackathon(hackathonId: string) {
    await deleteHackathon(hackathonId);
    await refreshHackathons();
    setHackathonMessage("Hackathon removed.");
  }

  async function handleCorrection(sessionId: string, category: ActivityCategory, subcategory: string) {
    try {
      await correctLiveSession({
        category,
        date: selectedDate,
        sessionId,
        subcategory,
      });
      await refreshSelectedDate();
      setCorrectionMessage("Label saved locally.");
    } catch (error) {
      setCorrectionMessage(error instanceof Error ? error.message : "Unable to save correction.");
    }
  }

  async function handleNote(sessionId: string, note: string) {
    try {
      await saveSessionNote({
        date: selectedDate,
        note,
        sessionId,
      });
      await refreshSelectedDate();
      setNoteMessage(note.trim() ? "Note saved locally." : "Note cleared locally.");
    } catch (error) {
      setNoteMessage(error instanceof Error ? error.message : "Unable to save note.");
    }
  }

  async function checkProjectAiAgent() {
    setAgentStatus("checking");
    setAgentMessage("Checking the local AiOS Assistant API.");

    try {
      const liveStatus = await checkAiosConnection();
      setAgentLive(liveStatus);

      if (liveStatus.locked) {
        setAgentStatus("locked");
        setAgentMessage("AiOS is running, but it is locked. Open AiOS and enter the local PIN.");
        return;
      }

      setAgentStatus("connected");
      setAgentMessage("AiOS is connected. You can sync privacy-safe activity sessions.");
      await syncCurrentSessions("manual");
    } catch (error) {
      setAgentLive(null);
      setAgentStatus("not-installed");
      setAgentMessage(error instanceof Error ? error.message : "Unable to reach local AiOS Assistant.");
    }
  }

  async function syncCurrentSessions(mode: "manual" | "auto" = "manual") {
    if (!hasData) {
      setAgentMessage("No activity sessions available to sync for this date.");
      return;
    }

    setAgentStatus("syncing");
    setAgentMessage(
      mode === "auto"
        ? "Auto-sync is sending new high-level session summaries to AiOS."
        : "Sending high-level session summaries to AiOS.",
    );

    try {
      const result = await syncActivitySessions(sessions);

      if (result.locked) {
        setAgentStatus("locked");
        setAgentMessage("AiOS is locked. Unlock the AiOS dashboard, then sync again.");
        return;
      }

      setAgentStatus("connected");
      setAgentLastSync(new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }));
      setAgentPendingCount(countPendingAiosSessions(sessions));
      setAgentMessage(
        result.sent > 0
          ? `${mode === "auto" ? "Auto-synced" : "Synced"} ${result.sent} new session${result.sent === 1 ? "" : "s"} to AiOS.`
          : "AiOS already has the current local session summaries.",
      );
    } catch (error) {
      setAgentStatus("connected");
      setAgentMessage(error instanceof Error ? error.message : "Unable to sync sessions to AiOS.");
    }
  }

  function handleAgentBaseUrlChange(value: string) {
    try {
      const normalized = setAiosBaseUrl(value);
      setAgentBaseUrlState(normalized);
      setAgentLive(null);
      setAgentStatus("not-installed");
      setAgentMessage(`AiOS API set to ${normalized}. Press Connect to verify it.`);
    } catch (error) {
      const fallback = getAiosBaseUrl();
      setAgentBaseUrlState(fallback);
      setAgentLive(null);
      setAgentStatus("not-installed");
      setAgentMessage(error instanceof Error ? error.message : "AiOS API must stay on this device.");
    }
  }

  function resetAiosSyncHistory() {
    clearAiosSyncHistory();
    setAgentPendingCount(countPendingAiosSessions(sessions));
    setAgentMessage("AiOS sync history cleared. Current sessions can be sent again.");
  }

  async function handleDesktopCollector(action: "start" | "stop") {
    setDesktopRuntimeBusy(true);

    try {
      const status = action === "start"
        ? await ensureDesktopCollector()
        : await stopDesktopCollector();
      setDesktopRuntime(status);

      if (action === "start") {
        window.setTimeout(() => refreshSelectedDate(), 900);
      }
    } catch (error) {
      setDesktopRuntime((current) => ({
        collectorManaged: false,
        collectorPid: null,
        collectorRunning: false,
        collectorUrl: "http://127.0.0.1:17321",
        desktop: isDesktopApp(),
        message: error instanceof Error ? error.message : "Unable to control the desktop collector.",
        storagePath: current?.storagePath ?? null,
      }));
    } finally {
      setDesktopRuntimeBusy(false);
    }
  }

  return (
    <main className="app-shell">
      <header className="topbar">
        <div className="brand">
          <div className="brand-mark">
            <Gauge size={22} />
          </div>
          <div>
            <strong>What Do You Do</strong>
            <span>Private activity OS</span>
          </div>
        </div>

        <nav className="nav-list" aria-label="Primary">
          <a className="active" href="#today">
            <LayoutDashboard size={15} />
            Dashboard
          </a>
          <a href="#timeline">
            <Activity size={15} />
            Timeline
          </a>
          <a href="#hackathons">
            <Trophy size={15} />
            Hackathons
          </a>
          <a href="#privacy">
            <ShieldCheck size={15} />
            Privacy
          </a>
          <a href="#agent">
            <Bot size={15} />
            AI Agent
          </a>
          <a href="#widgets">
            <MonitorSmartphone size={15} />
            Widgets
          </a>
        </nav>

        <div className="topbar-actions">
          <a className="topbar-settings" href="#settings">
            <Settings2 size={16} />
            <span>Settings</span>
          </a>
          <button
            className="theme-toggle"
            aria-label={`Switch to ${theme === "light" ? "dark" : "light"} mode`}
            title={`Switch to ${theme === "light" ? "dark" : "light"} mode`}
            onClick={() => setTheme((value) => (value === "light" ? "dark" : "light"))}
          >
            {theme === "light" ? <Moon size={17} /> : <Sun size={17} />}
          </button>
          <span className={`collector-dot ${collectorStatus}`} title={`Collector: ${collectorStatus}`} />
        </div>
      </header>

      <section className="workspace">
        <header className="hero">
          <div className="hero-copy">
            <p className="eyebrow">
              {collectorStatus === "live"
                ? "Live desktop collector"
                : collectorStatus === "history"
                  ? "Daily history"
                  : "Simulator fallback"}
            </p>
            <h1>Welcome back.</h1>
            <p>
              {collectorStatus === "live"
                ? "Your day is classified locally, in real time."
                : collectorStatus === "history"
                  ? `Showing persisted local sessions for ${selectedDate}.`
                  : "Start the collector to replace simulated sessions."}
            </p>
            <div className="hero-progress-strip" aria-label="Daily activity summary">
              <span className="dark">{formatMinutes(summary.totalMinutes)}</span>
              <span className="gold">{formatMinutes(summary.focusMinutes)}</span>
              <span>{formatMinutes(summary.idleMinutes)}</span>
              <span className="rail" aria-hidden="true" />
            </div>
          </div>
          <div className="hero-side">
            <div className="hero-stats" aria-label="Dashboard totals">
              <div>
                <strong>{sessions.length}</strong>
                <span>Sessions</span>
              </div>
              <div>
                <strong>{summary.insights.correctedCount}</strong>
                <span>Corrections</span>
              </div>
              <div>
                <strong>{summary.privacyScore}</strong>
                <span>Privacy</span>
              </div>
            </div>
            <div className="hero-card">
              <span>{hasData ? "Current session" : "No data"}</span>
              <strong>
                {hasData ? `${currentMeta.label}: ${current.subcategory}` : selectedDate}
              </strong>
              <small>
                {hasData
                  ? `${current.appName} - ${formatMinutes(current.durationMinutes)} focused, ${current.confidence}% confidence`
                  : "No activity sessions were recorded for this day."}
              </small>
              <div className="session-meter" aria-hidden="true">
                <span style={{ width: `${current.confidence}%` }} />
              </div>
            </div>
          </div>
        </header>

        <section className="date-strip" aria-label="Date controls">
          <div>
            <span>Viewing date</span>
            <strong>{selectedDate}</strong>
          </div>
          <div className="date-actions">
            <button className={isToday ? "active" : ""} onClick={() => setSelectedDate(activeDateKey)}>
              Today
            </button>
            <button onClick={() => setSelectedDate(offsetDateKey(activeDateKey, -1))}>Yesterday</button>
            <button onClick={() => setSelectedDate(offsetDateKey(activeDateKey, -2))}>2 days ago</button>
            <button onClick={() => setSelectedDate(offsetDateKey(selectedDate, -1))}>Previous day</button>
            <button
              disabled={selectedDate >= activeDateKey}
              onClick={() => setSelectedDate(offsetDateKey(selectedDate, 1))}
            >
              Next day
            </button>
            <input
              aria-label="Pick activity date"
              max={activeDateKey}
              type="date"
              value={selectedDate}
              onChange={(event) => setSelectedDate(event.target.value)}
            />
          </div>
          <small>
            {isFutureDate
              ? "Future dates are disabled."
              : availableDates.length > 0
              ? `Saved days: ${availableDates.slice(0, 4).join(", ")}`
              : "No saved daily files yet"}
          </small>
        </section>

        <section className="metrics-grid" id="today">
          <MetricCard
            icon={TimerReset}
            label="Tracked time"
            value={formatMinutes(summary.totalMinutes)}
            subtext={`${sessions.length} sessions on ${selectedDate}`}
            tone="violet"
          />
          <MetricCard
            icon={Zap}
            label="Focused work"
            value={formatMinutes(summary.focusMinutes)}
            subtext="coding + research"
            tone="green"
          />
          <MetricCard
            icon={Pause}
            label="Idle / AFK"
            value={formatMinutes(summary.idleMinutes)}
            subtext="detected locally"
            tone="amber"
          />
          <MetricCard
            icon={ShieldCheck}
            label="Privacy score"
            value={`${summary.privacyScore}%`}
            subtext="local-only processing"
            tone="cyan"
          />
        </section>

        <div className="dashboard-grid">
          <section className="panel glass-panel chart-panel">
            <div className="panel-heading">
              <div>
                <p className="eyebrow">Focus graph</p>
                <h2>Energy across the day</h2>
              </div>
              <button className="icon-button" aria-label="Pause tracking" title="Pause tracking">
                <Pause size={18} />
              </button>
            </div>
            <FocusGraph bars={summary.focusBars} />
          </section>

          <section className="panel glass-panel split-panel">
            <div className="panel-heading">
              <div>
                <p className="eyebrow">Activity mix</p>
                <h2>Where time went</h2>
              </div>
              <PieChart size={20} />
            </div>
            <ActivityMix summary={summary.categorySummaries} totalMinutes={summary.totalMinutes} />
          </section>

          <section className="panel glass-panel insights-panel">
            <div className="panel-heading">
              <div>
                <p className="eyebrow">Daily insights</p>
                <h2>What stands out</h2>
              </div>
              <Zap size={20} />
            </div>
            <DailyInsightsPanel summary={summary} />
          </section>

          <section className="panel glass-panel mobile-dashboard-panel">
            <div className="panel-heading">
              <div>
                <p className="eyebrow">Mobile dashboard</p>
                <h2>Phone glance view</h2>
              </div>
              <MonitorSmartphone size={20} />
            </div>
            <MobileDashboard
              current={current}
              focusMinutes={summary.focusMinutes}
              idleMinutes={summary.idleMinutes}
              sessions={sessions}
              totalMinutes={summary.totalMinutes}
            />
          </section>

          <section className="panel glass-panel timeline-panel" id="timeline">
            <div className="panel-heading">
              <div>
                <p className="eyebrow">Activity timeline</p>
                <h2>Detected context</h2>
                <span className="section-note">
                  Showing top {Math.min(visibleTimeline.length, 15)} of {sessions.length} entries
                </span>
              </div>
              <button className="text-button" onClick={() => setCorrectionMode((value) => !value)}>
                {correctionMode ? "Done" : "Correct labels"}
              </button>
              <button className="text-button" onClick={() => setNoteMode((value) => !value)}>
                <StickyNote size={16} />
                {noteMode ? "Done" : "Notes"}
              </button>
            </div>
            {correctionMessage && <div className="inline-status">{correctionMessage}</div>}
            {noteMessage && <div className="inline-status note-status">{noteMessage}</div>}

            {hasData ? (
              <div className="timeline">
                {visibleTimeline.map((item) => (
                  <TimelineRow
                    correctionMode={correctionMode}
                    item={item}
                    key={item.id}
                    onCorrect={handleCorrection}
                    noteMode={noteMode}
                    onSaveNote={handleNote}
                  />
                ))}
              </div>
            ) : (
              <NoDataState selectedDate={selectedDate} />
            )}
          </section>

          <section className="panel glass-panel logs-panel">
            <div className="panel-heading">
              <div>
                <p className="eyebrow">Activity logs</p>
                <h2>Older entries</h2>
                <span className="section-note">
                  {logEntries.length > 0
                    ? `${logEntries.length} entries after the top 15`
                    : "No extra entries beyond the timeline"}
                </span>
              </div>
            </div>

            {logEntries.length > 0 ? (
              <div className="log-list">
                {logEntries.map((item) => (
                  <LogRow key={`log-${item.id}`} item={item} />
                ))}
              </div>
            ) : (
              <div className="compact-empty-state">
                <strong>No logs yet</strong>
                <span>Older activity will appear here once the day has more than 15 entries.</span>
              </div>
            )}
          </section>

          <section className="panel glass-panel hackathon-panel" id="hackathons">
            <div className="panel-heading">
              <div>
                <p className="eyebrow">Hackathon tracker</p>
                <h2>Applications and build plans</h2>
                <span className="section-note">{hackathonMessage}</span>
              </div>
              <button
                className="text-button primary"
                onClick={() => {
                  setEditingHackathon(null);
                  setHackathonFormOpen((value) => !value);
                }}
              >
                <Plus size={16} />
                Add hackathon
              </button>
            </div>

            {hackathonFormOpen && (
              <HackathonForm
                hackathon={editingHackathon}
                onCancel={() => {
                  setEditingHackathon(null);
                  setHackathonFormOpen(false);
                }}
                onSave={handleSaveHackathon}
              />
            )}

            <HackathonSourceFeed
              feed={hackathonFeed}
              localHackathons={hackathons}
              message={hackathonSourceMessage}
              onAdd={handleAddSourceHackathon}
              onMarkRead={handleMarkHackathonUpdateRead}
              onRefresh={handleRefreshHackathonSources}
              refreshing={hackathonRefreshing}
            />

            <PlacementSourceFeed
              feed={placementFeed}
              folderName="Placement inbox"
              emptyMessage="Run the Gmail connector from AiOS to pull openings, applications, OAs, interviews, offers, and rejections."
              message={placementSourceMessage}
              onMarkRead={handleMarkPlacementUpdateRead}
              onRefresh={handleRefreshPlacementSources}
              refreshing={placementRefreshing}
              scanLabel="Scan jobs"
            />

            <PlacementSourceFeed
              feed={neopatFeed}
              folderName="NeoPat"
              emptyMessage="NeoPat practice-test and training assessment mails will stay here, outside hackathons and placements."
              message={neopatSourceMessage}
              onMarkRead={handleMarkPlacementUpdateRead}
              onRefresh={refreshNeoPatFeed}
              refreshing={false}
              scanLabel="Refresh"
              variant="neopat"
            />

            <HackathonBoard
              hackathons={hackathons}
              onDelete={handleDeleteHackathon}
              onEdit={(hackathon) => {
                setEditingHackathon(hackathon);
                setHackathonFormOpen(true);
              }}
              onTimeline={handleHackathonTimeline}
            />
          </section>

          <section className="panel glass-panel" id="privacy">
            <div className="panel-heading">
              <div>
                <p className="eyebrow">Privacy controls</p>
                <h2>Allowed signals</h2>
              </div>
              <button className="text-button" onClick={() => setPrivacyExpanded((value) => !value)}>
                {privacyExpanded ? "Hide" : "Review"}
              </button>
            </div>

            <div className="permission-list">
              {privacyPermissions.map((permission) => (
                <PermissionRow key={permission.id} permission={permission} />
              ))}
            </div>
            {privacyExpanded && (
              <div className="detail-box">
                <strong>Privacy rule</strong>
                <p>
                  This collector stores sessions only: app name, category, subcategory,
                  duration, confidence, and signal source. Screenshots, keystrokes,
                  messages, files, and raw page content stay out of the pipeline.
                </p>
              </div>
            )}
          </section>

          <section className="panel glass-panel" id="agent">
            <div className="panel-heading">
              <div>
                <p className="eyebrow">Companion layer</p>
                <h2>Project AI Agent</h2>
              </div>
              <div className="panel-actions">
                <button
                  className="text-button"
                  disabled={agentStatus === "checking" || agentStatus === "syncing"}
                  onClick={checkProjectAiAgent}
                >
                  {agentStatus === "checking" ? "Checking" : "Connect"}
                </button>
                <button
                  className="text-button primary"
                  disabled={agentStatus === "checking" || agentStatus === "syncing" || !hasData}
                  onClick={() => syncCurrentSessions("manual")}
                >
                  {agentStatus === "syncing" ? "Syncing" : "Sync"}
                </button>
              </div>
            </div>
            <p className="panel-copy">
              This app sends only approved activity summaries to the local AiOS Assistant. Raw titles,
              screenshots, messages, keystrokes, and private files stay out of the bridge.
            </p>

            <div className="agent-identity">
              <div>
                <span>Trusted thread</span>
                <strong>{projectAiAgent.threadId}</strong>
                <small>{projectAiAgent.threadTitle}</small>
              </div>
              <a href={projectAiAgent.threadUrl}>Open thread</a>
            </div>

            <div className="agent-links">
              <a href={agentBaseUrl} target="_blank" rel="noreferrer">
                Local app
              </a>
              <span>{projectAiAgent.cwd}</span>
            </div>

            <div className="agent-bridge-controls">
              <label>
                <span>AiOS API</span>
                <input
                  value={agentBaseUrl}
                  onBlur={(event) => handleAgentBaseUrlChange(event.target.value)}
                  onChange={(event) => setAgentBaseUrlState(event.target.value)}
                />
              </label>
              <label className="toggle-row">
                <input
                  checked={agentAutoSync}
                  type="checkbox"
                  onChange={(event) => setAgentAutoSync(event.target.checked)}
                />
                <span>Auto-sync approved summaries</span>
              </label>
              <button className="text-button" onClick={resetAiosSyncHistory}>
                Reset sent list
              </button>
            </div>

            <div className={`agent-status ${agentStatus}`}>
              <span />
              <div>
                <strong>
                  {agentStatus === "connected"
                    ? "Project AI Agent connected"
                    : agentStatus === "locked"
                      ? "Project AI Agent locked"
                    : agentStatus === "syncing"
                      ? "Syncing with Project AI Agent"
                    : agentStatus === "checking"
                      ? "Searching local machine"
                      : "Project AI Agent not installed"}
                </strong>
                <small>
                  {agentStatus === "connected"
                    ? "Reminders, memory, email, jobs, and wellbeing context are available."
                    : agentStatus === "locked"
                      ? "Unlock AiOS in the browser before API sync can write events."
                    : agentStatus === "syncing"
                      ? "Sending new local session summaries."
                    : agentStatus === "checking"
                      ? "Looking for a trusted local companion app."
                      : "Install Project AI Agent to unlock assistant features."}
                </small>
              </div>
            </div>

            <div className="agent-sync-grid">
              <SettingRow label="AiOS API" value={agentBaseUrl} />
              <SettingRow
                label="Wellbeing minutes"
                value={`${agentLive?.stats?.wellbeing_minutes ?? 0}`}
              />
              <SettingRow label="Last sync" value={agentLastSync || "Not synced"} />
              <SettingRow label="Pending sync" value={`${agentPendingCount}`} />
              <SettingRow label="Auto-sync" value={agentAutoSync ? "Enabled" : "Manual"} />
            </div>

            <div className="inline-status agent-message">{agentMessage}</div>

            <div className="agent-feature-list">
              {agentFeatures.map((feature) => {
                const Icon = feature.icon;
                return (
                  <div className="agent-feature" key={feature.name}>
                    <Icon size={19} />
                    <div>
                      <strong>{feature.name}</strong>
                      <span>
                        {agentStatus === "connected" ? feature.unlockedStatus : "Locked until connected"}
                      </span>
                    </div>
                  </div>
                );
              })}
            </div>
          </section>

          <section className="panel glass-panel widgets-panel" id="widgets">
            <div className="panel-heading">
              <div>
                <p className="eyebrow">Widgets</p>
                <h2>Desktop and mobile glance</h2>
              </div>
              <div className="segmented-control" aria-label="Widget preview mode">
                <button
                  className={widgetMode === "desktop" ? "active" : ""}
                  onClick={() => setWidgetMode("desktop")}
                >
                  Desktop
                </button>
                <button
                  className={widgetMode === "mobile" ? "active" : ""}
                  onClick={() => setWidgetMode("mobile")}
                >
                  Mobile
                </button>
              </div>
            </div>

            <div className="widget-stack">
              {widgetMode === "desktop" ? (
                <>
                  <div className="widget-preview desktop-widget">
                    <span>Desktop widget</span>
                    <strong>
                      {currentMeta.label}: {current.subcategory}
                    </strong>
                    <small>
                      {current.appName} - {formatMinutes(current.durationMinutes)} local session
                    </small>
                  </div>
                  <div className="widget-preview compact">
                    <span>Data source</span>
                    <strong>{collectorStatus === "live" ? "Live collector" : "Simulator connected"}</strong>
                    <small>
                      {collectorStatus === "live"
                        ? "Windows app and idle signals"
                        : "Run npm run collector:dev"}
                    </small>
                  </div>
                </>
              ) : (
                <div className="widget-preview mobile-widget-card">
                  <span>Mobile widget</span>
                  <strong>{formatMinutes(summary.totalMinutes)} tracked today</strong>
                  <small>
                    Focus {formatMinutes(summary.focusMinutes)} - Idle {formatMinutes(summary.idleMinutes)}
                  </small>
                </div>
              )}
            </div>
          </section>

          <section className="panel glass-panel settings-panel" id="settings">
            <div className="panel-heading">
              <div>
                <p className="eyebrow">Settings</p>
                <h2>Runtime controls</h2>
              </div>
              <button
                className={`text-button ${trackingPaused ? "" : "primary"}`}
                onClick={() => setTrackingPaused((value) => !value)}
              >
                {trackingPaused ? "Resume" : "Pause"}
              </button>
            </div>
            <div className={`desktop-runtime ${desktopRuntime?.desktop ? "native" : "browser"}`}>
              <div>
                <span>{desktopRuntime?.desktop ? "Desktop runtime" : "Browser runtime"}</span>
                <strong>
                  {desktopRuntime?.collectorRunning
                    ? desktopRuntime.collectorManaged
                      ? "Collector managed"
                      : "Collector detected"
                    : "Collector stopped"}
                </strong>
                <small>{desktopRuntime?.message ?? "Checking runtime..."}</small>
                {desktopRuntime?.storagePath && <code>{desktopRuntime.storagePath}</code>}
              </div>
              <div className="desktop-runtime-actions">
                <button
                  className="text-button primary"
                  disabled={!desktopRuntime?.desktop || desktopRuntimeBusy || desktopRuntime?.collectorRunning}
                  onClick={() => handleDesktopCollector("start")}
                >
                  {desktopRuntimeBusy ? "Working" : "Start collector"}
                </button>
                <button
                  className="text-button"
                  disabled={
                    !desktopRuntime?.desktop
                    || desktopRuntimeBusy
                    || !desktopRuntime?.collectorManaged
                  }
                  onClick={() => handleDesktopCollector("stop")}
                >
                  Stop
                </button>
              </div>
            </div>
            <div className="settings-list">
              <SettingRow label="Runtime" value={desktopRuntime?.desktop ? "Tauri desktop" : "Web browser"} />
              <SettingRow
                label="Data mode"
                value={
                  collectorStatus === "live"
                    ? "Live collector"
                    : collectorStatus === "history"
                      ? "Daily history"
                      : "Simulator fallback"
                }
              />
              <SettingRow label="Selected date" value={selectedDate} />
              <SettingRow label="Active date" value={activeDateKey} />
              <SettingRow label="Collector API" value="127.0.0.1:17321" />
              <SettingRow
                label="Collector process"
                value={
                  desktopRuntime?.collectorManaged
                    ? `Managed${desktopRuntime.collectorPid ? ` (PID ${desktopRuntime.collectorPid})` : ""}`
                    : desktopRuntime?.collectorRunning
                      ? "External"
                      : "Stopped"
                }
              />
              <SettingRow label="AiOS API" value={agentBaseUrl} />
              <SettingRow label="AiOS auto-sync" value={agentAutoSync ? "Enabled" : "Manual"} />
              <SettingRow label="Refresh interval" value="3 seconds" />
              <SettingRow label="Storage" value="Daily JSON files" />
            </div>
          </section>
        </div>
      </section>
    </main>
  );
}

function MobileDashboard({
  current,
  focusMinutes,
  idleMinutes,
  sessions,
  totalMinutes,
}: {
  current: ActivitySession;
  focusMinutes: number;
  idleMinutes: number;
  sessions: ActivitySession[];
  totalMinutes: number;
}) {
  const currentMeta = categoryMeta[current.category];
  const CurrentIcon = currentMeta.icon;
  const compactSessions = sessions.slice(0, 3);
  const hasData = sessions.length > 0;

  return (
    <div className="phone-shell" aria-label="Mobile dashboard preview">
      <div className="phone-status">
        <span>9:41</span>
        <strong>Local</strong>
      </div>
      <div className="phone-hero">
        <div className={`phone-now-icon ${currentMeta.color}`}>
          <CurrentIcon size={20} />
        </div>
        <span>{hasData ? "Right now" : "No data"}</span>
        <strong>{hasData ? currentMeta.label : "Empty day"}</strong>
        <small>{hasData ? current.subcategory : "No sessions recorded"}</small>
      </div>
      <div className="phone-stats">
        <div>
          <span>Total</span>
          <strong>{formatMinutes(totalMinutes)}</strong>
        </div>
        <div>
          <span>Focus</span>
          <strong>{formatMinutes(focusMinutes)}</strong>
        </div>
        <div>
          <span>Idle</span>
          <strong>{formatMinutes(idleMinutes)}</strong>
        </div>
      </div>
      <div className="phone-list">
        {compactSessions.length > 0 ? compactSessions.map((session) => {
          const meta = categoryMeta[session.category];

          return (
            <div className="phone-list-row" key={`mobile-${session.id}`}>
              <span className={meta.color} />
              <div>
                <strong>{meta.label}</strong>
                <small>{session.appName}</small>
              </div>
              <time>{formatMinutes(session.durationMinutes)}</time>
            </div>
          );
        }) : (
          <div className="phone-list-row empty">
            <span className="muted" />
            <div>
              <strong>No timeline</strong>
              <small>Pick another date or keep collector running.</small>
            </div>
          </div>
        )}
      </div>
      <div className="phone-bottom-nav" aria-hidden="true">
        <span className="active" />
        <span />
        <span />
        <span />
      </div>
    </div>
  );
}

function NoDataState({ selectedDate }: { selectedDate: string }) {
  return (
    <div className="empty-state">
      <Clock3 size={28} />
      <strong>No data for {selectedDate}</strong>
      <p>
        The collector has no saved activity sessions for this date yet. Choose a saved day,
        keep the collector running, or return to Today.
      </p>
    </div>
  );
}

function MetricCard({
  icon: Icon,
  label,
  value,
  subtext,
  tone,
}: {
  icon: React.ElementType;
  label: string;
  value: string;
  subtext: string;
  tone: string;
}) {
  return (
    <article className={`metric-card glass-panel ${tone}`}>
      <div className="metric-icon">
        <Icon size={20} />
      </div>
      <span>{label}</span>
      <strong>{value}</strong>
      <small>{subtext}</small>
    </article>
  );
}

function SettingRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="setting-row">
      <span>{label}</span>
      <strong>{value}</strong>
    </div>
  );
}

function FocusGraph({ bars }: { bars: number[] }) {
  return (
    <div className="focus-graph" aria-label="Focus graph">
      {bars.map((value, index) => (
        <div className="bar-column" key={`${value}-${index}`}>
          <span style={{ height: `${value}%` }} />
        </div>
      ))}
    </div>
  );
}

function ActivityMix({
  summary,
  totalMinutes,
}: {
  summary: { category: ActivityCategory; minutes: number; percent: number }[];
  totalMinutes: number;
}) {
  return (
    <div className="activity-mix">
      <div className="donut-chart" aria-hidden="true">
        <span className="donut-hole">
          <strong>{formatMinutes(totalMinutes).split(" ")[0]}</strong>
          <small>{formatMinutes(totalMinutes).split(" ").slice(1).join(" ") || "tracked"}</small>
        </span>
      </div>
      <div className="mix-list">
        {summary.map((item) => {
          const meta = categoryMeta[item.category];
          const Icon = meta.icon;

          return (
            <div className="mix-row" key={item.category}>
              <span className={`mix-dot ${meta.color}`}>
                <Icon size={14} />
              </span>
              <strong>{meta.label}</strong>
              <small>
                {item.percent}% - {formatMinutes(item.minutes)}
              </small>
            </div>
          );
        })}
      </div>
    </div>
  );
}

function DailyInsightsPanel({ summary }: { summary: ReturnType<typeof buildDashboardSummary> }) {
  const strongestLabel = summary.insights.strongestCategory === "none"
    ? "No data"
    : categoryMeta[summary.insights.strongestCategory].label;

  return (
    <div className="insights-stack">
      <div className="insight-summary-grid">
        <div>
          <span>Data quality</span>
          <strong>{summary.insights.dataQuality}%</strong>
        </div>
        <div>
          <span>Corrections</span>
          <strong>{summary.insights.correctedCount}</strong>
        </div>
        <div>
          <span>Low confidence</span>
          <strong>{summary.insights.lowConfidenceCount}</strong>
        </div>
        <div>
          <span>Strongest mode</span>
          <strong>{strongestLabel}</strong>
        </div>
      </div>

      <div className="top-app-list">
        <span className="section-note">Top apps by tracked time</span>
        {summary.insights.topApps.length > 0 ? (
          summary.insights.topApps.map((app) => (
            <div className="top-app-row" key={app.appName}>
              <strong>{app.appName}</strong>
              <span>{app.sessions} sessions</span>
              <em>{formatMinutes(app.minutes)}</em>
            </div>
          ))
        ) : (
          <div className="compact-empty-state">
            <strong>No app insights yet</strong>
            <span>Keep the collector running to build a useful daily summary.</span>
          </div>
        )}
      </div>
    </div>
  );
}

function HackathonSourceFeed({
  feed,
  localHackathons,
  message,
  onAdd,
  onMarkRead,
  onRefresh,
  refreshing,
}: {
  feed: HackathonFeed | null;
  localHackathons: Hackathon[];
  message: string;
  onAdd: (hackathon: AiosHackathon) => Promise<void>;
  onMarkRead: (updateId: number) => Promise<void>;
  onRefresh: () => Promise<void>;
  refreshing: boolean;
}) {
  const [categoryFilter, setCategoryFilter] = useState<"all" | AiosHackathon["category"]>("all");
  const [sortMode, setSortMode] = useState<"newest" | "oldest" | "deadline" | "unread">("newest");
  const filteredHackathons = (feed?.hackathons ?? []).filter(
    (hackathon) => categoryFilter === "all" || hackathon.category === categoryFilter,
  );
  const sourceUpdates = filteredHackathons
    .flatMap((hackathon) => hackathon.updates.map((update) => ({ hackathon, update })))
    .sort((left, right) => sortHackathonUpdates(left, right, sortMode))
    .slice(0, 12);
  const categoryCounts = countHackathonCategories(feed?.hackathons ?? []);

  return (
    <section className="hackathon-source-feed">
      <div className="hackathon-source-heading">
        <div>
          <span className="source-icon"><Inbox size={18} /></span>
          <div>
            <strong>Live source inbox</strong>
            <small>{message}</small>
          </div>
        </div>
        <button className="text-button" disabled={refreshing} onClick={onRefresh}>
          <RefreshCw className={refreshing ? "spin" : ""} size={16} />
          {refreshing ? "Scanning" : "Scan now"}
        </button>
      </div>

      <div className="source-health-row">
        {categoryCounts.map(({ label, value }) => (
          <span className="source-health" key={label}>{label}: {value}</span>
        ))}
        {(feed?.connectors ?? []).slice(0, 4).map((connector) => (
          <span className={`source-health ${connector.status}`} key={connector.id}>
            {formatConnectorName(connector.connector_id)}: {connector.records_imported} new
          </span>
        ))}
        {!feed?.connectors.length && <span className="source-health">No source scan recorded yet</span>}
      </div>

      <div className="source-sort-controls">
        <label>
          <span>Category</span>
          <select
            aria-label="Filter hackathons by category"
            value={categoryFilter}
            onChange={(event) => setCategoryFilter(event.target.value as typeof categoryFilter)}
          >
            <option value="all">All categories</option>
            <option value="applied">Applied</option>
            <option value="opening">Openings</option>
            <option value="live">Live</option>
            <option value="previous">Previous</option>
          </select>
        </label>
        <label>
          <span>Sort</span>
          <select
            aria-label="Sort hackathons"
            value={sortMode}
            onChange={(event) => setSortMode(event.target.value as typeof sortMode)}
          >
            <option value="newest">Newest received</option>
            <option value="oldest">Oldest received</option>
            <option value="deadline">Due soon</option>
            <option value="unread">Unread first</option>
          </select>
        </label>
        <span className="source-sort-count">
          {filteredHackathons.length} item{filteredHackathons.length === 1 ? "" : "s"}
        </span>
      </div>

      {sourceUpdates.length > 0 ? (
        <div className="hackathon-update-list">
          {sourceUpdates.map(({ hackathon, update }) => {
            const onBoard = Boolean(findMatchingLocalHackathon(hackathon, localHackathons));
            return (
              <article className={`hackathon-update-row ${update.is_read ? "" : "unread"}`} key={update.id}>
                <span className={`platform-badge hackathon-${hackathon.category}`}>{hackathon.status}</span>
                <div>
                  <strong>{hackathon.title}</strong>
                  <span>{update.title}</span>
                  <div className="placement-metrics">
                    <span>{formatHackathonCategory(hackathon.category)}</span>
                    <span>{formatConnectorName(update.platform)}</span>
                    <span>Received {formatDateTime(update.received_at)}</span>
                    {hackathon.applied_at && <span>Applied {formatDateTime(hackathon.applied_at)}</span>}
                    {hackathon.deadline && <span>Due {formatDeadline(hackathon.deadline).text}</span>}
                    <span>{hackathon.metrics.total_updates} update{hackathon.metrics.total_updates === 1 ? "" : "s"}</span>
                    {hackathon.metrics.unread_updates > 0 && <span>{hackathon.metrics.unread_updates} unread</span>}
                  </div>
                  <small>{update.action_needed || update.summary || "Review this platform update."}</small>
                </div>
                <div className="hackathon-update-actions">
                  {!onBoard && (
                    <button className="text-button" onClick={() => onAdd(hackathon)}>
                      Add to board
                    </button>
                  )}
                  {!update.is_read && (
                    <button className="icon-button" title="Mark as read" onClick={() => onMarkRead(update.id)}>
                      <Check size={16} />
                    </button>
                  )}
                </div>
              </article>
            );
          })}
        </div>
      ) : filteredHackathons.length ? (
        <div className="hackathon-update-list">
          {[...filteredHackathons]
            .sort((left, right) => sortHackathons(left, right, sortMode))
            .slice(0, 12)
            .map((hackathon) => {
            const onBoard = Boolean(findMatchingLocalHackathon(hackathon, localHackathons));

            return (
              <article className="hackathon-update-row" key={`source-${hackathon.id}`}>
                <span className={`platform-badge hackathon-${hackathon.category}`}>{hackathon.status}</span>
                <div>
                  <strong>{hackathon.title}</strong>
                  <span>{formatHackathonCategory(hackathon.category)}</span>
                  <div className="placement-metrics">
                    <span>{formatConnectorName(hackathon.platform)}</span>
                    <span>Received {formatDateTime(hackathon.received_at)}</span>
                    {hackathon.applied_at && <span>Applied {formatDateTime(hackathon.applied_at)}</span>}
                    {hackathon.deadline && <span>Due {formatDeadline(hackathon.deadline).text}</span>}
                    <span>{hackathon.metrics.total_updates} update{hackathon.metrics.total_updates === 1 ? "" : "s"}</span>
                  </div>
                  <small>{hackathon.notes || "Detected by AiOS hackathon sources."}</small>
                </div>
                <div className="hackathon-update-actions">
                  {!onBoard ? (
                    <button className="text-button" onClick={() => onAdd(hackathon)}>
                      Add to board
                    </button>
                  ) : (
                    <span className="source-health ok">On board</span>
                  )}
                </div>
              </article>
            );
          })}
        </div>
      ) : (
        <div className="compact-empty-state">
          <strong>No hackathons in this category</strong>
          <span>Choose another category or run the Gmail and Hackathon Platforms connectors.</span>
        </div>
      )}
    </section>
  );
}

function PlacementSourceFeed({
  emptyMessage,
  feed,
  folderName,
  message,
  onMarkRead,
  onRefresh,
  refreshing,
  scanLabel,
  variant = "placement",
}: {
  emptyMessage: string;
  feed: PlacementFeed | null;
  folderName: string;
  message: string;
  onMarkRead: (updateId: number) => Promise<void>;
  onRefresh: () => Promise<void>;
  refreshing: boolean;
  scanLabel: string;
  variant?: "placement" | "neopat";
}) {
  const sourceUpdates = (feed?.placements ?? [])
    .flatMap((placement) => placement.updates.map((update) => ({ placement, update })))
    .sort((left, right) => {
      const leftDate = left.update.occurred_at || left.update.created_at;
      const rightDate = right.update.occurred_at || right.update.created_at;
      return rightDate.localeCompare(leftDate);
    })
    .slice(0, 8);

  return (
    <section className={`hackathon-source-feed placement-source-feed ${variant}`}>
      <div className="hackathon-source-heading">
        <div>
          <span className={`source-icon ${variant}`}><BriefcaseBusiness size={18} /></span>
          <div>
            <strong>{folderName}</strong>
            <small>{message}</small>
          </div>
        </div>
        <button className="text-button" disabled={refreshing} onClick={onRefresh}>
          <RefreshCw className={refreshing ? "spin" : ""} size={16} />
          {refreshing ? "Scanning" : scanLabel}
        </button>
      </div>

      <div className="source-health-row">
        {(feed?.connectors ?? []).slice(0, 4).map((connector) => (
          <span className={`source-health ${connector.status}`} key={connector.id}>
            {formatConnectorName(connector.connector_id)}: {connector.records_imported} new
          </span>
        ))}
        {!feed?.connectors.length && <span className="source-health">No placement scan recorded yet</span>}
      </div>

      {sourceUpdates.length > 0 ? (
        <div className="hackathon-update-list">
          {sourceUpdates.map(({ placement, update }) => (
            <article className={`hackathon-update-row ${update.is_read ? "" : "unread"}`} key={update.id}>
              <span className={`platform-badge ${variant}`}>{placement.status}</span>
              <div>
                <strong>{placement.company || placement.title}</strong>
                <span>{update.title}</span>
                <div className="placement-metrics">
                  <span>{variant === "neopat" ? "Practice" : placement.metrics.has_applied ? "Applied" : "Opening"}</span>
                  <span>Received {formatDateTime(update.received_at)}</span>
                  {variant !== "neopat" && placement.applied_at && <span>Applied {formatDateTime(placement.applied_at)}</span>}
                  {placement.deadline && <span>Due {formatDeadline(placement.deadline).text}</span>}
                  <span>{placement.metrics.total_updates} update{placement.metrics.total_updates === 1 ? "" : "s"}</span>
                  {placement.metrics.unread_updates > 0 && <span>{placement.metrics.unread_updates} unread</span>}
                </div>
                <small>{update.action_needed || update.summary || "Review this placement update."}</small>
              </div>
              <div className="hackathon-update-actions">
                {!update.is_read && (
                  <button className="icon-button" title="Mark as read" onClick={() => onMarkRead(update.id)}>
                    <Check size={16} />
                  </button>
                )}
              </div>
            </article>
          ))}
        </div>
      ) : feed?.placements.length ? (
        <div className="hackathon-update-list">
          {feed.placements.slice(0, 8).map((placement) => (
            <article className="hackathon-update-row" key={`placement-${placement.id}`}>
              <span className={`platform-badge ${variant}`}>{placement.status}</span>
              <div>
                <strong>{placement.company || placement.title}</strong>
                <span>{placement.title}</span>
                <div className="placement-metrics">
                  <span>{variant === "neopat" ? "Practice" : placement.metrics.has_applied ? "Applied" : "Opening"}</span>
                  <span>Received {formatDateTime(placement.received_at)}</span>
                  {variant !== "neopat" && placement.applied_at && <span>Applied {formatDateTime(placement.applied_at)}</span>}
                  {placement.deadline && <span>Due {formatDeadline(placement.deadline).text}</span>}
                  <span>{placement.metrics.total_updates} update{placement.metrics.total_updates === 1 ? "" : "s"}</span>
                </div>
                <small>{placement.notes || "Detected by AiOS placement sources."}</small>
              </div>
              <div className="hackathon-update-actions">
                <span className="source-health ok">Tracked</span>
              </div>
            </article>
          ))}
        </div>
      ) : (
        <div className="compact-empty-state">
          <strong>No {folderName.toLowerCase()} updates yet</strong>
          <span>{emptyMessage}</span>
        </div>
      )}
    </section>
  );
}

function HackathonForm({
  hackathon,
  onCancel,
  onSave,
}: {
  hackathon: Hackathon | null;
  onCancel: () => void;
  onSave: (draft: HackathonDraft) => Promise<void>;
}) {
  const [draft, setDraft] = useState<HackathonDraft>(() =>
    hackathon ? toHackathonDraft(hackathon) : emptyHackathonDraft,
  );
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    setDraft(hackathon ? toHackathonDraft(hackathon) : emptyHackathonDraft);
    setError("");
  }, [hackathon]);

  function updateDraft<Key extends keyof HackathonDraft>(key: Key, value: HackathonDraft[Key]) {
    setDraft((current) => ({ ...current, [key]: value }));
  }

  async function submit(event: React.FormEvent) {
    event.preventDefault();
    setSaving(true);
    setError("");

    try {
      await onSave(draft);
    } catch (submitError) {
      setError(submitError instanceof Error ? submitError.message : "Unable to save hackathon.");
    } finally {
      setSaving(false);
    }
  }

  return (
    <form className="hackathon-form" onSubmit={submit}>
      <div className="hackathon-form-grid">
        <label>
          <span>Name</span>
          <input
            required
            value={draft.title}
            onChange={(event) => updateDraft("title", event.target.value)}
          />
        </label>
        <label>
          <span>Organizer</span>
          <input
            value={draft.organizer}
            onChange={(event) => updateDraft("organizer", event.target.value)}
          />
        </label>
        <label>
          <span>Status</span>
          <select
            value={draft.status}
            onChange={(event) => updateDraft("status", event.target.value as HackathonStatus)}
          >
            {hackathonColumns.map((column) => (
              <option key={column.status} value={column.status}>
                {column.label}
              </option>
            ))}
          </select>
        </label>
        <label>
          <span>Applied date</span>
          <input
            type="date"
            value={draft.appliedDate}
            onChange={(event) => updateDraft("appliedDate", event.target.value)}
          />
        </label>
        <label>
          <span>Deadline</span>
          <input
            type="date"
            value={draft.deadline}
            onChange={(event) => updateDraft("deadline", event.target.value)}
          />
        </label>
        <label>
          <span>Progress: {draft.progress}%</span>
          <input
            max="100"
            min="0"
            type="range"
            value={draft.progress}
            onChange={(event) => updateDraft("progress", Number(event.target.value))}
          />
        </label>
        <label className="wide">
          <span>Link</span>
          <input
            placeholder="https://..."
            type="url"
            value={draft.url}
            onChange={(event) => updateDraft("url", event.target.value)}
          />
        </label>
        <label className="wide">
          <span>Plan</span>
          <textarea
            placeholder="Problem, milestones, teammates, submission plan..."
            value={draft.plan}
            onChange={(event) => updateDraft("plan", event.target.value)}
          />
        </label>
        <label className="wide">
          <span>Work done</span>
          <textarea
            placeholder="Research, prototype, backend, pitch deck..."
            value={draft.workDone}
            onChange={(event) => updateDraft("workDone", event.target.value)}
          />
        </label>
      </div>
      {error && <div className="inline-status">{error}</div>}
      <div className="form-actions">
        <button className="text-button" type="button" onClick={onCancel}>
          Cancel
        </button>
        <button className="text-button primary" disabled={saving || !draft.title.trim()} type="submit">
          {saving ? "Saving" : hackathon ? "Update" : "Create"}
        </button>
      </div>
    </form>
  );
}

function HackathonBoard({
  hackathons,
  onDelete,
  onEdit,
  onTimeline,
}: {
  hackathons: Hackathon[];
  onDelete: (hackathonId: string) => Promise<void>;
  onEdit: (hackathon: Hackathon) => void;
  onTimeline: (hackathonId: string, note: string) => Promise<void>;
}) {
  return (
    <div className="hackathon-board">
      {hackathonColumns.map((column) => {
        const items = hackathons.filter((hackathon) => hackathon.status === column.status);

        return (
          <section className={`hackathon-column ${column.status}`} key={column.status}>
            <header>
              <strong>{column.label}</strong>
              <span>{items.length}</span>
            </header>
            <div className="hackathon-column-list">
              {items.length > 0 ? (
                items.map((hackathon) => (
                  <HackathonCard
                    hackathon={hackathon}
                    key={hackathon.id}
                    onDelete={onDelete}
                    onEdit={onEdit}
                    onTimeline={onTimeline}
                  />
                ))
              ) : (
                <div className="hackathon-column-empty">No entries</div>
              )}
            </div>
          </section>
        );
      })}
    </div>
  );
}

function HackathonCard({
  hackathon,
  onDelete,
  onEdit,
  onTimeline,
}: {
  hackathon: Hackathon;
  onDelete: (hackathonId: string) => Promise<void>;
  onEdit: (hackathon: Hackathon) => void;
  onTimeline: (hackathonId: string, note: string) => Promise<void>;
}) {
  const [timelineNote, setTimelineNote] = useState("");
  const [savingTimeline, setSavingTimeline] = useState(false);
  const deadlineLabel = formatDeadline(hackathon.deadline);
  const externalUrl = safeExternalUrl(hackathon.url);

  async function saveTimeline() {
    if (!timelineNote.trim()) return;
    setSavingTimeline(true);

    try {
      await onTimeline(hackathon.id, timelineNote);
      setTimelineNote("");
    } finally {
      setSavingTimeline(false);
    }
  }

  return (
    <article className="hackathon-card">
      <div className="hackathon-card-heading">
        <div>
          <strong>{hackathon.title}</strong>
          <span>{hackathon.organizer || "Independent team"}</span>
        </div>
        <div className="hackathon-card-actions">
          <button aria-label={`Edit ${hackathon.title}`} onClick={() => onEdit(hackathon)}>
            <Settings2 size={15} />
          </button>
          <button aria-label={`Delete ${hackathon.title}`} onClick={() => onDelete(hackathon.id)}>
            <Trash2 size={15} />
          </button>
        </div>
      </div>

      <div className="hackathon-dates">
        <span>
          <CalendarDays size={14} />
          Applied {hackathon.appliedDate || "not yet"}
        </span>
        <strong className={deadlineLabel.tone}>{deadlineLabel.text}</strong>
      </div>

      <div className="hackathon-progress">
        <div>
          <span>Progress</span>
          <strong>{hackathon.progress}%</strong>
        </div>
        <div aria-hidden="true">
          <span style={{ width: `${hackathon.progress}%` }} />
        </div>
      </div>

      <div className="hackathon-copy">
        <span>Plan</span>
        <p>{hackathon.plan || "No plan written yet."}</p>
      </div>
      <div className="hackathon-copy">
        <span>Work done</span>
        <p>{hackathon.workDone || "No work logged yet."}</p>
      </div>

      {externalUrl && (
        <a className="hackathon-link" href={externalUrl} target="_blank" rel="noreferrer">
          Open hackathon page
        </a>
      )}

      <div className="hackathon-timeline">
        <span>Timeline</span>
        {hackathon.timeline.slice(-3).reverse().map((entry) => (
          <div key={entry.id}>
            <time>{formatTimelineDate(entry.date)}</time>
            <p>{entry.note}</p>
          </div>
        ))}
        <div className="timeline-entry-form">
          <input
            maxLength={280}
            placeholder="Add progress update"
            value={timelineNote}
            onChange={(event) => setTimelineNote(event.target.value)}
          />
          <button disabled={savingTimeline || !timelineNote.trim()} onClick={saveTimeline}>
            <Plus size={15} />
          </button>
        </div>
      </div>
    </article>
  );
}

function toHackathonDraft(hackathon: Hackathon): HackathonDraft {
  return {
    title: hackathon.title,
    organizer: hackathon.organizer,
    url: hackathon.url,
    status: hackathon.status,
    appliedDate: hackathon.appliedDate,
    deadline: hackathon.deadline,
    progress: hackathon.progress,
    plan: hackathon.plan,
    workDone: hackathon.workDone,
  };
}

function formatDeadline(deadline: string): { text: string; tone: string } {
  if (!deadline) return { text: "No deadline", tone: "muted" };
  const days = Math.ceil((new Date(`${deadline}T23:59:59`).getTime() - Date.now()) / 86400000);

  if (days < 0) return { text: `${Math.abs(days)}d overdue`, tone: "danger" };
  if (days === 0) return { text: "Due today", tone: "danger" };
  if (days <= 7) return { text: `${days}d left`, tone: "warning" };
  return { text: `${days}d left`, tone: "good" };
}

function formatTimelineDate(date: string): string {
  const parsed = new Date(date);
  return Number.isNaN(parsed.getTime())
    ? date
    : parsed.toLocaleDateString([], { day: "2-digit", month: "short" });
}

function formatDateTime(date: string): string {
  const parsed = new Date(date);
  return Number.isNaN(parsed.getTime())
    ? date
    : parsed.toLocaleString([], {
        day: "2-digit",
        hour: "2-digit",
        minute: "2-digit",
        month: "short",
      });
}

function countHackathonCategories(hackathons: AiosHackathon[]): { label: string; value: number }[] {
  const counts = hackathons.reduce(
    (accumulator, hackathon) => {
      accumulator[hackathon.category] += 1;
      return accumulator;
    },
    { applied: 0, live: 0, opening: 0, previous: 0 },
  );
  return [
    { label: "Applied", value: counts.applied },
    { label: "Open", value: counts.opening + counts.live },
    { label: "Previous", value: counts.previous },
  ].filter((item) => item.value > 0);
}

function sortHackathonUpdates(
  left: { hackathon: AiosHackathon; update: AiosHackathon["updates"][number] },
  right: { hackathon: AiosHackathon; update: AiosHackathon["updates"][number] },
  mode: "newest" | "oldest" | "deadline" | "unread",
): number {
  if (mode === "deadline") {
    return compareOptionalDates(left.hackathon.deadline, right.hackathon.deadline);
  }
  if (mode === "unread") {
    const unreadDifference = Number(left.update.is_read) - Number(right.update.is_read);
    if (unreadDifference !== 0) return unreadDifference;
  }

  const leftDate = left.update.received_at || left.update.occurred_at || left.update.created_at;
  const rightDate = right.update.received_at || right.update.occurred_at || right.update.created_at;
  return mode === "oldest"
    ? leftDate.localeCompare(rightDate)
    : rightDate.localeCompare(leftDate);
}

function sortHackathons(
  left: AiosHackathon,
  right: AiosHackathon,
  mode: "newest" | "oldest" | "deadline" | "unread",
): number {
  if (mode === "deadline") {
    return compareOptionalDates(left.deadline, right.deadline);
  }
  if (mode === "unread") {
    const unreadDifference = right.unread_updates - left.unread_updates;
    if (unreadDifference !== 0) return unreadDifference;
  }
  return mode === "oldest"
    ? left.received_at.localeCompare(right.received_at)
    : right.received_at.localeCompare(left.received_at);
}

function compareOptionalDates(left: string | null, right: string | null): number {
  if (!left && !right) return 0;
  if (!left) return 1;
  if (!right) return -1;
  return left.localeCompare(right);
}

function formatHackathonCategory(category: AiosHackathon["category"]): string {
  if (category === "applied") return "Applied";
  if (category === "live") return "Live";
  if (category === "previous") return "Previous";
  return "Opening";
}

function mapSourceHackathonStatus(status: string): HackathonStatus {
  const lowered = status.toLowerCase();
  if (lowered.includes("submit") || lowered.includes("result") || lowered.includes("closed")) return "submitted";
  if (lowered.includes("deadline") || lowered.includes("shortlist") || lowered.includes("team")) return "building";
  if (lowered.includes("applied") || lowered.includes("registration")) return "applied";
  return "watching";
}

function formatConnectorName(value: string): string {
  if (value === "hack2skill") return "Hack2Skill";
  if (value === "hackerearth") return "HackerEarth";
  if (value === "devfolio") return "Devfolio";
  if (value === "devpost") return "Devpost";
  if (value === "gmail") return "Gmail";
  if (value === "hackathon_platforms") return "Platforms";
  if (value === "unstop") return "Unstop";
  return value.replace(/_/g, " ").replace(/\b\w/g, (letter) => letter.toUpperCase());
}

function PermissionRow({ permission }: { permission: PrivacyPermission }) {
  const Icon = permissionIcons[permission.id] ?? ShieldCheck;
  const label = permission.state === "enabled"
    ? "Enabled"
    : permission.state === "optional"
      ? "Optional"
      : "Off";

  return (
    <div className="permission-row">
      <span>
        <Icon size={18} />
        {permission.name}
      </span>
      <strong>{label}</strong>
    </div>
  );
}

function TimelineRow({
  correctionMode,
  item,
  noteMode,
  onCorrect,
  onSaveNote,
}: {
  correctionMode: boolean;
  item: ActivitySession;
  noteMode: boolean;
  onCorrect: (sessionId: string, category: ActivityCategory, subcategory: string) => Promise<void>;
  onSaveNote: (sessionId: string, note: string) => Promise<void>;
}) {
  const meta = categoryMeta[item.category];
  const Icon = meta.icon;
  const [category, setCategory] = useState<ActivityCategory>(item.category);
  const [subcategory, setSubcategory] = useState(item.subcategory);
  const [note, setNote] = useState(item.note ?? "");
  const [saving, setSaving] = useState(false);
  const [savingNote, setSavingNote] = useState(false);

  useEffect(() => {
    setCategory(item.category);
    setSubcategory(item.subcategory);
    setNote(item.note ?? "");
  }, [item.category, item.note, item.subcategory]);

  async function saveCorrection() {
    setSaving(true);
    await onCorrect(item.id, category, subcategory);
    setSaving(false);
  }

  async function saveNote() {
    setSavingNote(true);
    await onSaveNote(item.id, note);
    setSavingNote(false);
  }

  return (
    <article className="timeline-row">
      <time>{item.startTime}</time>
      <div className={`category-icon ${meta.color}`}>
        <Icon size={18} />
      </div>
      <div className="timeline-detail">
        <div>
          <strong>{item.subcategory}</strong>
          <span>
            {item.appName} - {meta.label} - {item.signalSources.join(", ")}
          </span>
        </div>
        <div className="timeline-stats">
          <span>{formatMinutes(item.durationMinutes)}</span>
          <small>{item.confidence}%</small>
        </div>
      </div>
      {correctionMode && (
        <div className="correction-form">
          <select
            aria-label={`Category for ${item.appName}`}
            value={category}
            onChange={(event) => setCategory(event.target.value as ActivityCategory)}
          >
            {categoryOptions.map((option) => (
              <option key={option} value={option}>
                {categoryMeta[option].label}
              </option>
            ))}
          </select>
          <input
            aria-label={`Subcategory for ${item.appName}`}
            value={subcategory}
            onChange={(event) => setSubcategory(event.target.value)}
          />
          <button disabled={saving || !subcategory.trim()} onClick={saveCorrection}>
            {saving ? "Saving" : "Save"}
          </button>
        </div>
      )}
      {item.note && !noteMode && (
        <div className="session-note-card">
          <StickyNote size={15} />
          <span>{item.note}</span>
        </div>
      )}
      {noteMode && (
        <div className="note-form">
          <textarea
            aria-label={`Private note for ${item.appName}`}
            maxLength={280}
            placeholder="Add a private note for this session"
            value={note}
            onChange={(event) => setNote(event.target.value)}
          />
          <div>
            <span>{note.trim().length}/280</span>
            <button disabled={savingNote || note === (item.note ?? "")} onClick={saveNote}>
              {savingNote ? "Saving" : note.trim() ? "Save note" : "Clear note"}
            </button>
          </div>
        </div>
      )}
    </article>
  );
}

function LogRow({ item }: { item: ActivitySession }) {
  const meta = categoryMeta[item.category];

  return (
    <article className="log-row">
      <time>{item.startTime}</time>
      <strong>{item.appName}</strong>
      <span>{meta.label}</span>
      <small>{item.subcategory}</small>
      <em>{formatMinutes(item.durationMinutes)}</em>
      {item.note && (
        <div className="log-note">
          <StickyNote size={14} />
          <span>{item.note}</span>
        </div>
      )}
    </article>
  );
}

function safeExternalUrl(value: string): string {
  try {
    const parsed = new URL(value);
    return ["http:", "https:"].includes(parsed.protocol) ? parsed.toString() : "";
  } catch {
    return "";
  }
}

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);
