import { createServer } from "node:http";
import { execFile } from "node:child_process";
import { fileURLToPath } from "node:url";
import { dirname, join, resolve } from "node:path";
import { mkdir, readFile, readdir, writeFile } from "node:fs/promises";

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectRoot = resolve(__dirname, "../..");
const snapshotScript = join(__dirname, "get-windows-activity.ps1");
const dataDir = join(projectRoot, "data");
const sessionsDir = join(dataDir, "activity-sessions");
const legacySessionStorePath = join(dataDir, "activity-sessions.json");
const host = "127.0.0.1";
const port = Number.parseInt(process.env.WDYD_COLLECTOR_PORT ?? "17321", 10);
const pollMs = Number.parseInt(process.env.WDYD_COLLECTOR_POLL_MS ?? "2500", 10);
const idleThresholdMs = Number.parseInt(process.env.WDYD_IDLE_THRESHOLD_MS ?? "60000", 10);
const maxSessions = 96;
const activityCategories = new Set(["coding", "browsing", "communication", "gaming", "watching", "idle"]);

let latestSnapshot = null;
let currentSession = null;
let sessions = [];
let activeDateKey = formatDateKey(new Date());
let lastError = null;
let persistenceReady = false;

async function bootstrapStorage() {
  await mkdir(sessionsDir, { recursive: true });
  await migrateLegacyStore();
  await loadActiveDate(activeDateKey);
  persistenceReady = true;
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
    await writeFile(todayPath, `${JSON.stringify(payload, null, 2)}\n`, "utf-8");
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

function updateSessionCollection(stored, sessionId, patch) {
  let updated = false;
  let correctedSession = null;

  function applyPatch(session) {
    if (!session || session.id !== sessionId) return session;

    updated = true;
    correctedSession = {
      ...session,
      ...patch,
      confidence: 100,
      correctedAt: new Date().toISOString(),
      correctionSource: "user",
      signalSources: Array.from(new Set([...(session.signalSources ?? []), "user-correction"])),
    };
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
}

async function persistDate(dateKey, currentSessionForDate, sessionsForDate) {
  await mkdir(sessionsDir, { recursive: true });
  await writeFile(
    sessionPathForDate(dateKey),
    `${JSON.stringify(buildPayload(dateKey, currentSessionForDate, sessionsForDate), null, 2)}\n`,
    "utf-8",
  );
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

function runPowerShellSnapshot() {
  execFile(
    "powershell.exe",
    ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", snapshotScript],
    { windowsHide: true, timeout: 5000 },
    async (error, stdout, stderr) => {
      if (error) {
        lastError = stderr?.trim() || error.message;
        return;
      }

      try {
        const rawSnapshot = JSON.parse(stdout.trim());
        const snapshot = normalizeSnapshot(rawSnapshot);
        latestSnapshot = snapshot;
        lastError = null;
        await updateSessions(snapshot);
        await persistActiveDate();
      } catch (parseError) {
        lastError = parseError instanceof Error ? parseError.message : "Unable to parse snapshot";
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
      durationMinutes: 1,
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

async function readJsonBody(request) {
  const chunks = [];

  for await (const chunk of request) {
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
    "Access-Control-Allow-Origin": "http://127.0.0.1:5173",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store",
  });
  response.end(JSON.stringify(body));
}

const server = createServer(async (request, response) => {
  if (request.method === "OPTIONS") {
    jsonResponse(response, 204, {});
    return;
  }

  const requestUrl = new URL(request.url ?? "/", `http://${host}:${port}`);

  if (requestUrl.pathname === "/health") {
    jsonResponse(response, 200, {
      ok: true,
      service: "what-do-you-do-local-collector",
      activeDateKey,
      latestCapturedAt: latestSnapshot?.capturedAt ?? null,
      persistenceReady,
      sessionsDir,
      lastError,
    });
    return;
  }

  if (requestUrl.pathname === "/activity") {
    jsonResponse(response, latestSnapshot ? 200 : 503, {
      ok: Boolean(latestSnapshot),
      snapshot: latestSnapshot,
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
      jsonResponse(response, 400, {
        ok: false,
        error: error instanceof Error ? error.message : "Unable to apply correction",
      });
    }
    return;
  }

  jsonResponse(response, 404, { ok: false, error: "Not found" });
});

server.listen(port, host, () => {
  console.log(`What Do You Do collector listening on http://${host}:${port}`);
  console.log("Collecting active app, window title summary, and idle state locally.");
  console.log(`Daily session files: ${sessionsDir}`);
});

await bootstrapStorage();
runPowerShellSnapshot();
setInterval(runPowerShellSnapshot, pollMs);
