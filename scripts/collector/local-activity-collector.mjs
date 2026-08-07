import { createServer } from "node:http";
import { execFile } from "node:child_process";
import { randomBytes, timingSafeEqual } from "node:crypto";
import { fileURLToPath } from "node:url";
import { dirname, join, resolve } from "node:path";
import { mkdir, readFile, readdir, rename, writeFile } from "node:fs/promises";
import { homedir } from "node:os";

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectRoot = resolve(__dirname, "../..");
const snapshotScript = join(__dirname, "get-windows-activity.ps1");
const dataDir = process.env.WDYD_DATA_DIR
  ? resolve(process.env.WDYD_DATA_DIR)
  : join(projectRoot, "data");
const sessionsDir = join(dataDir, "activity-sessions");
const legacySessionStorePath = join(dataDir, "activity-sessions.json");
const aiosSyncStatePath = join(dataDir, "aios-sync-state.json");
const hackathonsStorePath = join(dataDir, "hackathons.json");
const collectorTokenPath = join(dataDir, "collector-token");
const host = "127.0.0.1";
const port = Number.parseInt(process.env.WDYD_COLLECTOR_PORT ?? "17321", 10);
const pollMs = Number.parseInt(process.env.WDYD_COLLECTOR_POLL_MS ?? "2500", 10);
const idleThresholdMs = Number.parseInt(process.env.WDYD_IDLE_THRESHOLD_MS ?? "60000", 10);
let aiosSyncEnabled = process.env.WDYD_AIOS_SYNC === "1";
let aiosBaseUrl = normalizeLoopbackBaseUrl(process.env.WDYD_AIOS_URL ?? "http://127.0.0.1:5050");
let aiosApiToken = process.env.WDYD_AIOS_API_TOKEN ?? "";
const maxSessions = 96;
const maxJsonBodyBytes = 64 * 1024;
const activityCategories = new Set(["coding", "browsing", "communication", "gaming", "watching", "idle"]);
const hackathonStatuses = new Set(["watching", "applied", "building", "submitted"]);
const allowedBrowserOrigins = [
  /^https?:\/\/(?:127\.0\.0\.1|localhost)(?::\d+)?$/i,
  /^https?:\/\/tauri\.localhost$/i,
  /^tauri:\/\/localhost$/i,
];
const collectorBootstrapOrigins = new Set([
  "http://127.0.0.1:5173",
  "http://localhost:5173",
  "http://tauri.localhost",
  "https://tauri.localhost",
  "tauri://localhost",
]);

let latestSnapshot = null;
let currentSession = null;
let sessions = [];
let activeDateKey = formatDateKey(new Date());
let lastError = null;
let aiosSyncState = {
  enabled: aiosSyncEnabled,
  lastError: null,
  lastSyncedAt: null,
  lastSyncedSessionId: null,
  sentSessionIds: [],
  totalSynced: 0,
};
let persistenceReady = false;
let collectorApiToken = "";
let captureInFlight = false;
const writeLocks = new Map();

async function bootstrapStorage() {
  await mkdir(sessionsDir, { recursive: true });
  await ensureCollectorApiToken();
  await migrateLegacyStore();
  await loadActiveDate(activeDateKey);
  await loadAiosSyncState();
  await discoverAiosRuntime();
  persistenceReady = true;
}

async function ensureCollectorApiToken() {
  collectorApiToken = String(process.env.WDYD_COLLECTOR_TOKEN ?? "").trim();
  if (!collectorApiToken) {
    try {
      collectorApiToken = (await readFile(collectorTokenPath, "utf-8")).trim();
    } catch {
      collectorApiToken = randomBytes(32).toString("hex");
      await writeFileAtomically(collectorTokenPath, `${collectorApiToken}\n`);
    }
  }

  if (collectorApiToken.length < 32) {
    throw new Error("WDYD collector token must contain at least 32 characters.");
  }
}

async function writeFileAtomically(filePath, contents) {
  const previous = writeLocks.get(filePath) ?? Promise.resolve();
  const next = previous.catch(() => {}).then(async () => {
    const temporaryPath = `${filePath}.${process.pid}.${Date.now()}.tmp`;
    await writeFile(temporaryPath, contents, "utf-8");
    await rename(temporaryPath, filePath);
  });
  writeLocks.set(filePath, next);
  try {
    await next;
  } finally {
    if (writeLocks.get(filePath) === next) writeLocks.delete(filePath);
  }
}

async function discoverAiosRuntime() {
  if (process.env.WDYD_AIOS_URL && process.env.WDYD_AIOS_API_TOKEN) {
    aiosSyncEnabled = process.env.WDYD_AIOS_SYNC !== "0";
    return;
  }

  const candidates = process.platform === "win32"
    ? [
        join(process.env.LOCALAPPDATA ?? join(homedir(), "AppData", "Local"), "AiOS Assistant", "runtime.json"),
      ]
    : [
        join(process.env.XDG_DATA_HOME ?? join(homedir(), ".local", "share"), "aios-assistant", "runtime.json"),
      ];

  for (const runtimePath of candidates) {
    try {
      const runtime = JSON.parse(await readFile(runtimePath, "utf-8"));
      if (runtime.service !== "aios-assistant" || !runtime.base_url || !runtime.api_token) continue;
      aiosBaseUrl = normalizeLoopbackBaseUrl(runtime.base_url);
      aiosApiToken = String(runtime.api_token);
      aiosSyncEnabled = true;
      aiosSyncState.enabled = true;
      return;
    } catch {
      // AiOS may not be running yet; discovery is retried before each sync.
    }
  }

  // Pairing is an explicit user-approved flow now. Do not probe the
  // metadata endpoint looking for a bearer token.
}

async function migrateLegacyStore() {
  const todayPath = sessionPathForDate(activeDateKey);

  try {
    await readFile(todayPath, "utf-8");
    return;
  } catch {
    // No daily file yet; try the old single-file store.
  }

  try {
    const legacy = JSON.parse(await readFile(legacySessionStorePath, "utf-8"));
    if (!legacy.currentSession && !Array.isArray(legacy.sessions)) return;
    const legacyDate = legacy.date ?? legacy.currentSession?.dateKey ?? legacy.sessions?.[0]?.dateKey;

    if (legacyDate && legacyDate !== activeDateKey) {
      return;
    }

    const payload = buildPayload(
      activeDateKey,
      legacy.currentSession ? addDateKey(legacy.currentSession, activeDateKey) : null,
      Array.isArray(legacy.sessions)
        ? legacy.sessions.map((session) => addDateKey(session, activeDateKey)).slice(0, maxSessions)
        : [],
    );
    await writeFileAtomically(todayPath, `${JSON.stringify(payload, null, 2)}\n`);
  } catch {
    // Fresh machine or no legacy data. Nothing to migrate.
  }
}

async function loadActiveDate(dateKey) {
  const stored = await readSessionsForDate(dateKey);
  activeDateKey = dateKey;
  currentSession = stored.currentSession;
  sessions = stored.sessions;
}

async function readSessionsForDate(dateKey) {
  try {
    const data = JSON.parse(await readFile(sessionPathForDate(dateKey), "utf-8"));
    return {
      currentSession: data.currentSession ? addDateKey(data.currentSession, dateKey) : null,
      sessions: Array.isArray(data.sessions)
        ? data.sessions.map((session) => addDateKey(session, dateKey)).slice(0, maxSessions)
        : [],
    };
  } catch {
    return { currentSession: null, sessions: [] };
  }
}

async function correctSession(dateKey, sessionId, patch) {
  const stored = dateKey === activeDateKey
    ? { currentSession, sessions }
    : await readSessionsForDate(dateKey);

  const result = updateSessionCollection(stored, sessionId, patch);

  if (!result.updated) {
    return { ok: false, error: "Session not found" };
  }

  if (dateKey === activeDateKey) {
    currentSession = result.currentSession;
    sessions = result.sessions;
    await persistActiveDate();
  } else {
    await persistDate(dateKey, result.currentSession, result.sessions);
  }

  return { ok: true, session: result.session };
}

async function noteSession(dateKey, sessionId, patch) {
  const stored = dateKey === activeDateKey
    ? { currentSession, sessions }
    : await readSessionsForDate(dateKey);

  const result = updateSessionCollection(stored, sessionId, patch, {
    markCorrection: false,
    markNote: true,
  });

  if (!result.updated) {
    return { ok: false, error: "Session not found" };
  }

  if (dateKey === activeDateKey) {
    currentSession = result.currentSession;
    sessions = result.sessions;
    await persistActiveDate();
  } else {
    await persistDate(dateKey, result.currentSession, result.sessions);
  }

  return { ok: true, session: result.session };
}

function updateSessionCollection(stored, sessionId, patch, options = { markCorrection: true, markNote: false }) {
  let updated = false;
  let correctedSession = null;

  function applyPatch(session) {
    if (!session || session.id !== sessionId) return session;

    updated = true;
    correctedSession = {
      ...session,
      ...patch,
    };

    if (options.markCorrection) {
      correctedSession.confidence = 100;
      correctedSession.correctedAt = new Date().toISOString();
      correctedSession.correctionSource = "user";
      correctedSession.signalSources = Array.from(new Set([...(session.signalSources ?? []), "user-correction"]));
    }

    if (options.markNote) {
      correctedSession.notedAt = new Date().toISOString();
    }

    correctedSession.fingerprint = `${correctedSession.appName}:${correctedSession.category}:${correctedSession.subcategory}`;
    return correctedSession;
  }

  const nextCurrentSession = applyPatch(stored.currentSession);
  const nextSessions = stored.sessions.map(applyPatch);

  return {
    currentSession: nextCurrentSession,
    session: correctedSession,
    sessions: nextSessions,
    updated,
  };
}

async function persistActiveDate() {
  if (!persistenceReady) return;
  await persistDate(activeDateKey, currentSession, sessions);
  await syncClosedSessionsToAios();
}

async function persistDate(dateKey, currentSessionForDate, sessionsForDate) {
  await mkdir(sessionsDir, { recursive: true });
  await writeFileAtomically(
    sessionPathForDate(dateKey),
    `${JSON.stringify(buildPayload(dateKey, currentSessionForDate, sessionsForDate), null, 2)}\n`,
  );
}

async function readHackathons() {
  try {
    const data = JSON.parse(await readFile(hackathonsStorePath, "utf-8"));
    return Array.isArray(data.hackathons) ? data.hackathons : [];
  } catch {
    return [];
  }
}

async function persistHackathons(hackathons) {
  await mkdir(dataDir, { recursive: true });
  await writeFileAtomically(
    hackathonsStorePath,
    `${JSON.stringify({ version: 1, updatedAt: new Date().toISOString(), hackathons }, null, 2)}\n`,
  );
}

async function saveHackathon(payload) {
  const sanitized = sanitizeHackathonPayload(payload);

  if (!sanitized.ok) return sanitized;

  const hackathons = await readHackathons();
  const now = new Date().toISOString();
  const existingIndex = sanitized.id
    ? hackathons.findIndex((hackathon) => hackathon.id === sanitized.id)
    : -1;
  const existing = existingIndex >= 0 ? hackathons[existingIndex] : null;
  const hackathon = {
    ...sanitized.hackathon,
    id: existing?.id ?? `hackathon-${Date.now()}`,
    timeline: Array.isArray(payload.timeline)
      ? payload.timeline.map(sanitizeTimelineEntry).filter(Boolean).slice(-50)
      : existing?.timeline ?? [],
    createdAt: existing?.createdAt ?? now,
    updatedAt: now,
  };

  if (existingIndex >= 0) {
    hackathons[existingIndex] = hackathon;
  } else {
    hackathons.unshift(hackathon);
  }

  await persistHackathons(hackathons);
  return { ok: true, hackathon };
}

async function addHackathonTimelineEntry(payload) {
  const hackathonId = String(payload?.hackathonId ?? "");
  const note = String(payload?.note ?? "").trim().slice(0, 280);

  if (!hackathonId || !note) {
    return { ok: false, error: "Hackathon and timeline note are required." };
  }

  const hackathons = await readHackathons();
  const index = hackathons.findIndex((hackathon) => hackathon.id === hackathonId);

  if (index < 0) {
    return { ok: false, error: "Hackathon not found." };
  }

  const now = new Date().toISOString();
  const entry = {
    id: `timeline-${Date.now()}`,
    date: now,
    note,
  };
  const hackathon = {
    ...hackathons[index],
    timeline: [...(hackathons[index].timeline ?? []), entry].slice(-50),
    updatedAt: now,
  };
  hackathons[index] = hackathon;
  await persistHackathons(hackathons);

  return { ok: true, hackathon };
}

async function deleteHackathon(payload) {
  const hackathonId = String(payload?.hackathonId ?? "");
  const hackathons = await readHackathons();
  const remaining = hackathons.filter((hackathon) => hackathon.id !== hackathonId);

  if (!hackathonId || remaining.length === hackathons.length) {
    return { ok: false, error: "Hackathon not found." };
  }

  await persistHackathons(remaining);
  return { ok: true };
}

function sanitizeHackathonPayload(payload) {
  if (!payload || typeof payload !== "object") {
    return { ok: false, error: "Missing JSON payload." };
  }

  const title = String(payload.title ?? "").trim().slice(0, 120);
  const organizer = String(payload.organizer ?? "").trim().slice(0, 120);
  const url = sanitizeExternalUrl(payload.url);
  const status = String(payload.status ?? "watching");
  const appliedDate = sanitizeDateValue(payload.appliedDate);
  const deadline = sanitizeDateValue(payload.deadline);
  const progress = Math.max(0, Math.min(100, Number(payload.progress) || 0));
  const plan = String(payload.plan ?? "").trim().slice(0, 2000);
  const workDone = String(payload.workDone ?? "").trim().slice(0, 2000);

  if (!title) return { ok: false, error: "Hackathon title is required." };
  if (!hackathonStatuses.has(status)) return { ok: false, error: "Invalid hackathon status." };

  return {
    ok: true,
    id: String(payload.id ?? ""),
    hackathon: {
      title,
      organizer,
      url,
      status,
      appliedDate,
      deadline,
      progress,
      plan,
      workDone,
    },
  };
}

function sanitizeDateValue(value) {
  const date = String(value ?? "");
  return !date || isValidDateKey(date) ? date : "";
}

function sanitizeTimelineEntry(entry) {
  if (!entry || typeof entry !== "object") return null;
  const note = String(entry.note ?? "").trim().slice(0, 280);
  if (!note) return null;

  return {
    id: String(entry.id ?? `timeline-${Date.now()}`),
    date: String(entry.date ?? new Date().toISOString()),
    note,
  };
}

function buildPayload(dateKey, currentSessionForDate, sessionsForDate) {
  return {
    version: 2,
    date: dateKey,
    updatedAt: new Date().toISOString(),
    currentSession: currentSessionForDate,
    sessions: sessionsForDate.slice(0, maxSessions),
    privacy: {
      storesScreenshots: false,
      storesKeystrokes: false,
      storesPrivateMessages: false,
      storesRawWindowTitles: false,
    },
  };
}

async function loadAiosSyncState() {
  try {
    const stored = JSON.parse(await readFile(aiosSyncStatePath, "utf-8"));
    aiosSyncState = {
      ...aiosSyncState,
      ...stored,
      enabled: aiosSyncEnabled,
      sentSessionIds: Array.isArray(stored.sentSessionIds) ? stored.sentSessionIds.map(String).slice(-500) : [],
    };
  } catch {
    await persistAiosSyncState();
  }
}

async function persistAiosSyncState() {
  await mkdir(dataDir, { recursive: true });
  await writeFileAtomically(
    aiosSyncStatePath,
    `${JSON.stringify({ ...aiosSyncState, enabled: aiosSyncEnabled }, null, 2)}\n`,
  );
}

async function syncClosedSessionsToAios() {
  await discoverAiosRuntime();
  if (!aiosSyncEnabled) return;

  if (!aiosApiToken) {
    aiosSyncState.lastError = "WDYD_AIOS_API_TOKEN is required when WDYD_AIOS_SYNC=1.";
    await persistAiosSyncState();
    return;
  }

  const sentSessionIds = new Set(aiosSyncState.sentSessionIds);
  const pendingSessions = sessions
    .filter((session) => session.id && session.durationMinutes > 0 && !sentSessionIds.has(session.id))
    .slice(0, 5);

  if (pendingSessions.length === 0) return;

  for (const session of pendingSessions) {
    try {
      const response = await fetch(`${aiosBaseUrl}/api/wellbeing/activity`, {
        body: JSON.stringify(toAiosPayload(session)),
        headers: {
          "Content-Type": "application/json",
          "X-AiOS-Token": aiosApiToken,
        },
        method: "POST",
      });

      if (!response.ok) {
        aiosSyncState.lastError = `AiOS responded with ${response.status}.`;
        await persistAiosSyncState();
        return;
      }

      sentSessionIds.add(session.id);
      aiosSyncState.lastError = null;
      aiosSyncState.lastSyncedAt = new Date().toISOString();
      aiosSyncState.lastSyncedSessionId = session.id;
      aiosSyncState.totalSynced += 1;
    } catch (error) {
      aiosSyncState.lastError = error instanceof Error ? error.message : "Unable to sync with AiOS.";
      await persistAiosSyncState();
      return;
    }
  }

  aiosSyncState.sentSessionIds = Array.from(sentSessionIds).slice(-500);
  await persistAiosSyncState();
}

function toAiosPayload(session) {
  return {
    source: "what-do-you-do-collector",
    app_name: session.appName,
    category: mapCategoryForAios(session.category),
    duration_minutes: session.durationMinutes,
    planned_task: "Private activity timeline",
    actual_task: `${session.subcategory} (${session.startTime}-${session.endTime})`,
  };
}

function mapCategoryForAios(category) {
  if (category === "coding" || category === "browsing") return "deep_work";
  if (category === "watching") return "entertainment";
  if (category === "communication") return "social";
  return category;
}

function runPowerShellSnapshot() {
  if (captureInFlight) return;
  captureInFlight = true;
  execFile(
    "powershell.exe",
    ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", snapshotScript],
    { windowsHide: true, timeout: 5000 },
    async (error, stdout, stderr) => {
      try {
        if (error) {
          lastError = stderr?.trim() || error.message;
          return;
        }

        const rawSnapshot = JSON.parse(stdout.trim());
        const snapshot = normalizeSnapshot(rawSnapshot);
        latestSnapshot = snapshot;
        lastError = null;
        await updateSessions(snapshot);
        await persistActiveDate();
      } catch (parseError) {
        lastError = parseError instanceof Error ? parseError.message : "Unable to parse snapshot";
      } finally {
        captureInFlight = false;
      }
    },
  );
}

function normalizeSnapshot(rawSnapshot) {
  const processName = String(rawSnapshot.processName || "Unknown");
  const title = String(rawSnapshot.foregroundWindowTitle || "Untitled window");
  const idleMs = Number(rawSnapshot.idleMs || 0);
  const idle = idleMs >= idleThresholdMs;
  const category = idle ? "idle" : classifyCategory(processName, title);
  const capturedAtDate = new Date(rawSnapshot.capturedAt);

  return {
    capturedAt: rawSnapshot.capturedAt,
    dateKey: formatDateKey(capturedAtDate),
    platform: "windows",
    appName: idle ? "Desktop" : prettyAppName(processName),
    processName,
    windowTitle: sanitizeTitle(title),
    category,
    subcategory: describeSubcategory(category, processName, title, idle),
    confidence: category === "idle" ? 96 : estimateConfidence(category, title),
    idleMs,
    idle,
    rawContentStored: false,
    privacy: {
      screenshotsCaptured: false,
      keystrokesCaptured: false,
      privateMessagesRead: false,
      storedRawWindowTitle: false,
    },
  };
}

async function updateSessions(snapshot) {
  const now = new Date(snapshot.capturedAt);

  if (activeDateKey !== snapshot.dateKey) {
    if (currentSession) {
      currentSession.endTime = formatTime(now);
      sessions = [currentSession, ...sessions].slice(0, maxSessions);
      await persistDate(activeDateKey, null, sessions);
    }

    await loadActiveDate(snapshot.dateKey);
  }

  const fingerprint = `${snapshot.appName}:${snapshot.category}:${snapshot.subcategory}`;

  if (!currentSession || currentSession.fingerprint !== fingerprint) {
    if (currentSession) {
      currentSession.endTime = formatTime(now);
      sessions = [currentSession, ...sessions].slice(0, maxSessions);
    }

    currentSession = {
      id: `live-${now.getTime()}`,
      dateKey: snapshot.dateKey,
      fingerprint,
      startDateMs: now.getTime(),
      startTime: formatTime(now),
      endTime: formatTime(now),
      appName: snapshot.appName,
      category: snapshot.category,
      subcategory: snapshot.subcategory,
      durationMinutes: 0,
      confidence: snapshot.confidence,
      signalSources: snapshot.idle ? ["idle-detector"] : ["active-app"],
      rawContentStored: false,
    };
    return;
  }

  currentSession.endTime = formatTime(now);
  currentSession.durationMinutes = Math.max(1, Math.round((now.getTime() - currentSession.startDateMs) / 60000));
  currentSession.confidence = snapshot.confidence;
}

function classifyCategory(processName, title) {
  const text = `${processName} ${title}`.toLowerCase();

  if (matches(text, ["code", "codex", "cursor", "devenv", "pycharm", "webstorm", "intellij", "terminal", "powershell"])) {
    return "coding";
  }

  if (matches(text, ["discord", "slack", "teams", "zoom", "whatsapp", "telegram"])) {
    return "communication";
  }

  if (matches(text, ["steam", "epicgameslauncher", "riot", "minecraft", "roblox", "valorant", "leagueclient"])) {
    return "gaming";
  }

  if (matches(text, ["youtube", "netflix", "prime video", "vlc", "spotify", "twitch"])) {
    return "watching";
  }

  if (matches(text, ["chrome", "msedge", "firefox", "brave", "opera"])) {
    return "browsing";
  }

  return "browsing";
}

function describeSubcategory(category, processName, title, idle) {
  const text = `${processName} ${title}`.toLowerCase();

  if (idle) return "Away from keyboard";
  if (category === "coding" && matches(text, ["debug", "error", "terminal", "powershell"])) return "Debugging or terminal work";
  if (category === "coding") return "Building or editing code";
  if (category === "communication" && matches(text, ["voice", "call", "meeting"])) return "Call or meeting activity";
  if (category === "communication") return "Chat or community activity";
  if (category === "gaming") return "Game session activity";
  if (category === "watching") return "Watching or listening";
  if (category === "browsing" && matches(text, ["docs", "documentation", "github", "stackoverflow"])) return "Research or documentation";
  return "Browsing or app activity";
}

function prettyAppName(processName) {
  const names = {
    code: "VS Code",
    codex: "Codex",
    cursor: "Cursor",
    chrome: "Chrome",
    msedge: "Edge",
    firefox: "Firefox",
    discord: "Discord",
    powershell: "PowerShell",
  };
  const key = processName.toLowerCase();
  return names[key] ?? processName;
}

function estimateConfidence(category, title) {
  if (category === "coding" || category === "communication") return 82;
  if (category === "gaming") return 76;
  if (category === "watching") return 74;
  return title.length > 4 ? 70 : 62;
}

function sanitizeTitle(title) {
  return title.replace(/\s+/g, " ").trim().slice(0, 120);
}

function matches(text, needles) {
  return needles.some((needle) => text.includes(needle));
}

function formatTime(date) {
  return new Intl.DateTimeFormat("en-IN", {
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  }).format(date);
}

function formatDateKey(date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function isValidDateKey(dateKey) {
  return /^\d{4}-\d{2}-\d{2}$/.test(dateKey);
}

function sessionPathForDate(dateKey) {
  return join(sessionsDir, `${dateKey}.json`);
}

function addDateKey(session, dateKey) {
  return { ...session, dateKey: session.dateKey ?? dateKey };
}

function sanitizeCorrectionPayload(payload) {
  if (!payload || typeof payload !== "object") {
    return { ok: false, error: "Missing JSON payload" };
  }

  const date = String(payload.date ?? "");
  const sessionId = String(payload.sessionId ?? "");
  const category = String(payload.category ?? "");
  const subcategory = String(payload.subcategory ?? "").trim().slice(0, 90);

  if (!isValidDateKey(date)) {
    return { ok: false, error: "Invalid date. Use YYYY-MM-DD." };
  }

  if (!sessionId) {
    return { ok: false, error: "Missing sessionId" };
  }

  if (!activityCategories.has(category)) {
    return { ok: false, error: "Invalid activity category" };
  }

  if (!subcategory) {
    return { ok: false, error: "Subcategory is required" };
  }

  return {
    ok: true,
    date,
    sessionId,
    patch: {
      category,
      subcategory,
    },
  };
}

function sanitizeNotePayload(payload) {
  if (!payload || typeof payload !== "object") {
    return { ok: false, error: "Missing JSON payload" };
  }

  const date = String(payload.date ?? "");
  const sessionId = String(payload.sessionId ?? "");
  const note = String(payload.note ?? "").trim().slice(0, 280);

  if (!isValidDateKey(date)) {
    return { ok: false, error: "Invalid date. Use YYYY-MM-DD." };
  }

  if (!sessionId) {
    return { ok: false, error: "Missing sessionId" };
  }

  return {
    ok: true,
    date,
    sessionId,
    patch: {
      note,
    },
  };
}

async function readJsonBody(request) {
  const contentType = String(request.headers["content-type"] ?? "").toLowerCase();
  if (!contentType.startsWith("application/json")) {
    throw createHttpError(415, "Content-Type must be application/json.");
  }

  const declaredLength = Number.parseInt(String(request.headers["content-length"] ?? "0"), 10);
  if (Number.isFinite(declaredLength) && declaredLength > maxJsonBodyBytes) {
    throw createHttpError(413, "Request body is too large.");
  }

  const chunks = [];
  let totalBytes = 0;

  for await (const chunk of request) {
    totalBytes += chunk.length;
    if (totalBytes > maxJsonBodyBytes) {
      throw createHttpError(413, "Request body is too large.");
    }
    chunks.push(chunk);
  }

  const text = Buffer.concat(chunks).toString("utf-8");
  return text ? JSON.parse(text) : {};
}

async function listAvailableDates() {
  try {
    const files = await readdir(sessionsDir);
    return files
      .filter((file) => /^\d{4}-\d{2}-\d{2}\.json$/.test(file))
      .map((file) => file.replace(".json", ""))
      .sort()
      .reverse();
  } catch {
    return [];
  }
}

function jsonResponse(response, statusCode, body) {
  response.writeHead(statusCode, {
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization, X-WDYD-Token",
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store",
    "X-Content-Type-Options": "nosniff",
  });
  response.end(JSON.stringify(body));
}

const server = createServer(async (request, response) => {
  const requestOrigin = String(request.headers.origin ?? "");
  const allowedOrigin = getAllowedBrowserOrigin(requestOrigin);

  if (requestOrigin && !allowedOrigin) {
    jsonResponse(response, 403, { ok: false, error: "Origin is not allowed." });
    return;
  }

  if (allowedOrigin) {
    response.setHeader("Access-Control-Allow-Origin", allowedOrigin);
    response.setHeader("Vary", "Origin");
  }

  const requestUrl = new URL(request.url ?? "/", `http://${host}:${port}`);

  if (request.method === "OPTIONS") {
    jsonResponse(response, 204, {});
    return;
  }

  if (requestUrl.pathname === "/auth/token" && request.method === "GET") {
    if (!allowedOrigin || !isCollectorBootstrapOrigin(requestOrigin)) {
      jsonResponse(response, 403, { ok: false, error: "A trusted browser origin is required." });
      return;
    }
    jsonResponse(response, 200, { ok: true, token: collectorApiToken });
    return;
  }

  if (!hasValidCollectorToken(request)) {
    jsonResponse(response, 401, {
      ok: false,
      error: "Collector authentication is required. Refresh the local dashboard to pair it.",
    });
    return;
  }

  if (requestUrl.pathname === "/health") {
    jsonResponse(response, 200, {
      ok: Boolean(latestSnapshot) && !lastError,
      service: "what-do-you-do-local-collector",
      activeDateKey,
      latestCapturedAt: latestSnapshot?.capturedAt ?? null,
      persistenceReady,
      storage: "local-daily-json",
      lastError,
      collectorOnline: Boolean(latestSnapshot) && !lastError,
      aiosSync: {
        enabled: aiosSyncEnabled,
        lastError: aiosSyncState.lastError,
        lastSyncedAt: aiosSyncState.lastSyncedAt,
        totalSynced: aiosSyncState.totalSynced,
      },
    });
    return;
  }

  if (requestUrl.pathname === "/activity") {
    jsonResponse(response, latestSnapshot ? 200 : 503, {
      ok: Boolean(latestSnapshot),
      snapshot: latestSnapshot ? toPublicSnapshot(latestSnapshot) : null,
      currentSession,
      activeDateKey,
      lastError,
    });
    return;
  }

  if (requestUrl.pathname === "/dates") {
    jsonResponse(response, 200, {
      ok: true,
      activeDateKey,
      dates: await listAvailableDates(),
    });
    return;
  }

  if (requestUrl.pathname === "/sessions") {
    const requestedDate = requestUrl.searchParams.get("date") ?? activeDateKey;

    if (!isValidDateKey(requestedDate)) {
      jsonResponse(response, 400, { ok: false, error: "Invalid date. Use YYYY-MM-DD." });
      return;
    }

    const stored = requestedDate === activeDateKey
      ? { currentSession, sessions }
      : await readSessionsForDate(requestedDate);
    const allSessions = [stored.currentSession, ...stored.sessions].filter(Boolean);

    jsonResponse(response, 200, {
      ok: true,
      date: requestedDate,
      activeDateKey,
      isLiveDate: requestedDate === activeDateKey,
      currentSession: stored.currentSession,
      sessions: allSessions,
      availableDates: await listAvailableDates(),
    });
    return;
  }

  if (requestUrl.pathname === "/sessions/correct" && request.method === "POST") {
    try {
      const payload = sanitizeCorrectionPayload(await readJsonBody(request));

      if (!payload.ok) {
        jsonResponse(response, 400, payload);
        return;
      }

      const result = await correctSession(payload.date, payload.sessionId, payload.patch);
      jsonResponse(response, result.ok ? 200 : 404, result);
    } catch (error) {
      jsonResponse(response, getHttpStatus(error), {
        ok: false,
        error: error instanceof Error ? error.message : "Unable to apply correction",
      });
    }
    return;
  }

  if (requestUrl.pathname === "/sessions/note" && request.method === "POST") {
    try {
      const payload = sanitizeNotePayload(await readJsonBody(request));

      if (!payload.ok) {
        jsonResponse(response, 400, payload);
        return;
      }

      const result = await noteSession(payload.date, payload.sessionId, payload.patch);
      jsonResponse(response, result.ok ? 200 : 404, result);
    } catch (error) {
      jsonResponse(response, getHttpStatus(error), {
        ok: false,
        error: error instanceof Error ? error.message : "Unable to save note",
      });
    }
    return;
  }

  if (requestUrl.pathname === "/hackathons" && request.method === "GET") {
    jsonResponse(response, 200, {
      ok: true,
      hackathons: await readHackathons(),
    });
    return;
  }

  if (requestUrl.pathname === "/hackathons/save" && request.method === "POST") {
    try {
      const result = await saveHackathon(await readJsonBody(request));
      jsonResponse(response, result.ok ? 200 : 400, result);
    } catch (error) {
      jsonResponse(response, getHttpStatus(error), {
        ok: false,
        error: error instanceof Error ? error.message : "Unable to save hackathon.",
      });
    }
    return;
  }

  if (requestUrl.pathname === "/hackathons/timeline" && request.method === "POST") {
    try {
      const result = await addHackathonTimelineEntry(await readJsonBody(request));
      jsonResponse(response, result.ok ? 200 : 404, result);
    } catch (error) {
      jsonResponse(response, getHttpStatus(error), {
        ok: false,
        error: error instanceof Error ? error.message : "Unable to add timeline entry.",
      });
    }
    return;
  }

  if (requestUrl.pathname === "/hackathons/delete" && request.method === "POST") {
    try {
      const result = await deleteHackathon(await readJsonBody(request));
      jsonResponse(response, result.ok ? 200 : 404, result);
    } catch (error) {
      jsonResponse(response, getHttpStatus(error), {
        ok: false,
        error: error instanceof Error ? error.message : "Unable to delete hackathon.",
      });
    }
    return;
  }

  jsonResponse(response, 404, { ok: false, error: "Not found" });
});

server.requestTimeout = 10_000;
server.headersTimeout = 12_000;
server.maxHeadersCount = 64;

await bootstrapStorage();
server.listen(port, host, () => {
  console.log(`What Do You Do collector listening on http://${host}:${port}`);
  console.log("Collecting active app, window title summary, and idle state locally.");
  console.log(`Daily session files: ${sessionsDir}`);
});
runPowerShellSnapshot();
setInterval(runPowerShellSnapshot, pollMs);

function getAllowedBrowserOrigin(origin) {
  if (!origin) return "";
  return allowedBrowserOrigins.some((pattern) => pattern.test(origin)) ? origin : "";
}

function isCollectorBootstrapOrigin(origin) {
  const configuredOrigin = String(process.env.WDYD_WEB_ORIGIN ?? "").trim().replace(/\/$/, "");
  return collectorBootstrapOrigins.has(origin) || (configuredOrigin && configuredOrigin === origin);
}

function hasValidCollectorToken(request) {
  const authorization = String(request.headers.authorization ?? "");
  const supplied = authorization.startsWith("Bearer ")
    ? authorization.slice("Bearer ".length).trim()
    : String(request.headers["x-wdyd-token"] ?? "").trim();
  if (!supplied || supplied.length !== collectorApiToken.length) return false;
  return timingSafeEqual(Buffer.from(supplied), Buffer.from(collectorApiToken));
}

function normalizeLoopbackBaseUrl(value) {
  const candidate = /^https?:\/\//i.test(value) ? value : `http://${value}`;
  const parsed = new URL(candidate);
  const isLoopback = parsed.hostname === "127.0.0.1"
    || parsed.hostname === "localhost"
    || parsed.hostname === "::1"
    || parsed.hostname === "[::1]";

  if (!isLoopback || !["http:", "https:"].includes(parsed.protocol)) {
    throw new Error("WDYD_AIOS_URL must use localhost or a loopback address.");
  }

  parsed.username = "";
  parsed.password = "";
  parsed.hash = "";
  parsed.search = "";
  return parsed.toString().replace(/\/+$/, "");
}

function sanitizeExternalUrl(value) {
  const raw = String(value ?? "").trim().slice(0, 500);
  if (!raw) return "";

  try {
    const parsed = new URL(raw);
    return ["http:", "https:"].includes(parsed.protocol) ? parsed.toString() : "";
  } catch {
    return "";
  }
}

function toPublicSnapshot(snapshot) {
  return {
    capturedAt: snapshot.capturedAt,
    idleMs: snapshot.idleMs,
    platform: snapshot.platform,
    processName: snapshot.processName,
    rawContentStored: false,
  };
}

function createHttpError(statusCode, message) {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
}

function getHttpStatus(error) {
  return Number.isInteger(error?.statusCode) ? error.statusCode : 400;
}
