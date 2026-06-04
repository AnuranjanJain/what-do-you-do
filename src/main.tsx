import React, { useEffect, useMemo, useState } from "react";
import ReactDOM from "react-dom/client";
import {
  Activity,
  Bell,
  Bot,
  BriefcaseBusiness,
  Check,
  Clock3,
  Code2,
  Database,
  EyeOff,
  Gamepad2,
  Gauge,
  LayoutDashboard,
  LockKeyhole,
  Mail,
  MessageCircle,
  MonitorSmartphone,
  Pause,
  PieChart,
  StickyNote,
  Search,
  Settings2,
  ShieldCheck,
  TimerReset,
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
import { AiosLiveStatus, AiosStatus, checkAiosConnection, getAiosBaseUrl, syncActivitySessions } from "./services/aios";
import { correctLiveSession, fetchLiveSessions, saveSessionNote } from "./services/collector";
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

function App() {
  const [collectorStatus, setCollectorStatus] = useState<CollectorStatus>("simulator");
  const [selectedDate, setSelectedDate] = useState(() => todayDateKey());
  const [activeDateKey, setActiveDateKey] = useState(() => todayDateKey());
  const [availableDates, setAvailableDates] = useState<string[]>([]);
  const [agentStatus, setAgentStatus] = useState<AiosStatus>("not-installed");
  const [agentLive, setAgentLive] = useState<AiosLiveStatus | null>(null);
  const [agentMessage, setAgentMessage] = useState("AiOS has not been checked in this session.");
  const [agentLastSync, setAgentLastSync] = useState("");
  const [widgetMode, setWidgetMode] = useState<"desktop" | "mobile">("desktop");
  const [privacyExpanded, setPrivacyExpanded] = useState(false);
  const [trackingPaused, setTrackingPaused] = useState(false);
  const [correctionMode, setCorrectionMode] = useState(false);
  const [correctionMessage, setCorrectionMessage] = useState("");
  const [noteMode, setNoteMode] = useState(false);
  const [noteMessage, setNoteMessage] = useState("");
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

  async function refreshSelectedDate() {
    const result = await fetchLiveSessions(selectedDate);
    setSessions(result.sessions);
    setActiveDateKey(result.activeDateKey);
    setAvailableDates(result.availableDates);
    setCollectorStatus(result.isLiveDate ? "live" : "history");
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
      await syncCurrentSessions();
    } catch (error) {
      setAgentLive(null);
      setAgentStatus("not-installed");
      setAgentMessage(error instanceof Error ? error.message : "Unable to reach local AiOS Assistant.");
    }
  }

  async function syncCurrentSessions() {
    if (!hasData) {
      setAgentMessage("No activity sessions available to sync for this date.");
      return;
    }

    setAgentStatus("syncing");
    setAgentMessage("Sending high-level session summaries to AiOS.");

    try {
      const result = await syncActivitySessions(sessions);

      if (result.locked) {
        setAgentStatus("locked");
        setAgentMessage("AiOS is locked. Unlock the AiOS dashboard, then sync again.");
        return;
      }

      setAgentStatus("connected");
      setAgentLastSync(new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }));
      setAgentMessage(
        result.sent > 0
          ? `Synced ${result.sent} new session${result.sent === 1 ? "" : "s"} to AiOS.`
          : "AiOS already has the current local session summaries.",
      );
    } catch (error) {
      setAgentStatus("connected");
      setAgentMessage(error instanceof Error ? error.message : "Unable to sync sessions to AiOS.");
    }
  }

  return (
    <main className="app-shell">
      <aside className="sidebar glass-panel">
        <div className="brand">
          <div className="brand-mark">
            <Gauge size={22} />
          </div>
          <div>
            <strong>What Do You Do</strong>
            <span>Private activity intelligence</span>
          </div>
        </div>

        <nav className="nav-list" aria-label="Primary">
          <a className="active" href="#today">
            <LayoutDashboard size={18} />
            Dashboard
          </a>
          <a href="#timeline">
            <Activity size={18} />
            Timeline
          </a>
          <a href="#privacy">
            <ShieldCheck size={18} />
            Privacy
          </a>
          <a href="#agent">
            <Bot size={18} />
            AI Agent
          </a>
          <a href="#widgets">
            <MonitorSmartphone size={18} />
            Widgets
          </a>
          <a href="#settings">
            <Settings2 size={18} />
            Settings
          </a>
        </nav>

        <section className="privacy-lock">
          <LockKeyhole size={20} />
          <div>
            <strong>Local-only mode</strong>
            <p>Raw activity, screenshots, messages, and mailbox data stay on this device.</p>
          </div>
        </section>
      </aside>

      <section className="workspace">
        <header className="hero glass-panel">
          <div className="hero-copy">
            <p className="eyebrow">
              {collectorStatus === "live"
                ? "Live desktop collector"
                : collectorStatus === "history"
                  ? "Daily history"
                  : "Simulator fallback"}
            </p>
            <h1>Today&apos;s activity command center</h1>
            <p>
              {collectorStatus === "live"
                ? "The dashboard is reading live local Windows foreground app and idle signals."
                : collectorStatus === "history"
                  ? `Showing persisted local sessions for ${selectedDate}.`
                : "Start the local collector to replace simulated sessions with real desktop activity."}
            </p>
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
        </header>

        <section className="date-strip glass-panel" aria-label="Date controls">
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
                  onClick={syncCurrentSessions}
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
              <a href={getAiosBaseUrl()} target="_blank" rel="noreferrer">
                Local app
              </a>
              <span>{projectAiAgent.cwd}</span>
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
              <SettingRow label="AiOS API" value={getAiosBaseUrl()} />
              <SettingRow
                label="Wellbeing minutes"
                value={`${agentLive?.stats?.wellbeing_minutes ?? 0}`}
              />
              <SettingRow label="Last sync" value={agentLastSync || "Not synced"} />
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
            <div className="settings-list">
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

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);
