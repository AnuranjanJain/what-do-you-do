import { createServer } from "node:http";
import { execFile } from "node:child_process";
import { fileURLToPath } from "node:url";
import { dirname, join, resolve } from "node:path";
import { mkdir, readFile, writeFile } from "node:fs/promises";

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectRoot = resolve(__dirname, "../..");
const snapshotScript = join(__dirname, "get-windows-activity.ps1");
const dataDir = join(projectRoot, "data");
const sessionStorePath = join(dataDir, "activity-sessions.json");
const host = "127.0.0.1";
const port = Number.parseInt(process.env.WDYD_COLLECTOR_PORT ?? "17321", 10);
const pollMs = Number.parseInt(process.env.WDYD_COLLECTOR_POLL_MS ?? "2500", 10);
const idleThresholdMs = Number.parseInt(process.env.WDYD_IDLE_THRESHOLD_MS ?? "60000", 10);
const maxSessions = 48;

let latestSnapshot = null;
let currentSession = null;
let sessions = [];
let lastError = null;
let persistenceReady = false;

async function loadStoredSessions() {
  await mkdir(dataDir, { recursive: true });

  try {
    const data = JSON.parse(await readFile(sessionStorePath, "utf-8"));
    currentSession = data.currentSession ?? null;
    sessions = Array.isArray(data.sessions) ? data.sessions.slice(0, maxSessions) : [];
  } catch {
    currentSession = null;
    sessions = [];
  }

  persistenceReady = true;
}

async function persistSessions() {
  if (!persistenceReady) return;

  const payload = {
    version: 1,
    updatedAt: new Date().toISOString(),
    currentSession,
    sessions: sessions.slice(0, maxSessions),
    privacy: {
      storesScreenshots: false,
      storesKeystrokes: false,
      storesPrivateMessages: false,
      storesRawWindowTitles: false,
    },
  };

  await writeFile(sessionStorePath, `${JSON.stringify(payload, null, 2)}\n`, "utf-8");
}

function runPowerShellSnapshot() {
  execFile(
    "powershell.exe",
    ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", snapshotScript],
    { windowsHide: true, timeout: 5000 },
    (error, stdout, stderr) => {
      if (error) {
        lastError = stderr?.trim() || error.message;
        return;
      }

      try {
        const rawSnapshot = JSON.parse(stdout.trim());
        const snapshot = normalizeSnapshot(rawSnapshot);
        latestSnapshot = snapshot;
        lastError = null;
        updateSessions(snapshot);
        persistSessions().catch((persistError) => {
          lastError = persistError instanceof Error ? persistError.message : "Unable to persist sessions";
        });
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

  return {
    capturedAt: rawSnapshot.capturedAt,
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

function updateSessions(snapshot) {
  const now = new Date(snapshot.capturedAt);
  const fingerprint = `${snapshot.appName}:${snapshot.category}:${snapshot.subcategory}`;

  if (!currentSession || currentSession.fingerprint !== fingerprint) {
    if (currentSession) {
      currentSession.endTime = formatTime(now);
      sessions = [currentSession, ...sessions].slice(0, maxSessions);
    }

    currentSession = {
      id: `live-${now.getTime()}`,
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
    persistSessions().catch(() => {});
    return;
  }

  currentSession.endTime = formatTime(now);
  currentSession.durationMinutes = Math.max(1, Math.round((now.getTime() - currentSession.startDateMs) / 60000));
  currentSession.confidence = snapshot.confidence;
}

function classifyCategory(processName, title) {
  const text = `${processName} ${title}`.toLowerCase();

  if (matches(text, ["code", "cursor", "devenv", "pycharm", "webstorm", "intellij", "terminal", "powershell"])) {
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

function jsonResponse(response, statusCode, body) {
  response.writeHead(statusCode, {
    "Access-Control-Allow-Origin": "http://127.0.0.1:5173",
    "Access-Control-Allow-Methods": "GET, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store",
  });
  response.end(JSON.stringify(body));
}

const server = createServer((request, response) => {
  if (request.method === "OPTIONS") {
    jsonResponse(response, 204, {});
    return;
  }

  if (request.url === "/health") {
    jsonResponse(response, 200, {
      ok: true,
      service: "what-do-you-do-local-collector",
      latestCapturedAt: latestSnapshot?.capturedAt ?? null,
      persistenceReady,
      sessionStorePath,
      lastError,
    });
    return;
  }

  if (request.url === "/activity") {
    jsonResponse(response, latestSnapshot ? 200 : 503, {
      ok: Boolean(latestSnapshot),
      snapshot: latestSnapshot,
      currentSession,
      lastError,
    });
    return;
  }

  if (request.url === "/sessions") {
    jsonResponse(response, 200, {
      ok: true,
      currentSession,
      sessions: [currentSession, ...sessions].filter(Boolean),
    });
    return;
  }

  jsonResponse(response, 404, { ok: false, error: "Not found" });
});

server.listen(port, host, () => {
  console.log(`What Do You Do collector listening on http://${host}:${port}`);
  console.log("Collecting active app, window title summary, and idle state locally.");
});

await loadStoredSessions();
runPowerShellSnapshot();
setInterval(runPowerShellSnapshot, pollMs);
