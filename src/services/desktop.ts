import { invoke } from "@tauri-apps/api/core";

export type DesktopRuntimeStatus = {
  collectorManaged: boolean;
  collectorPid: number | null;
  collectorRunning: boolean;
  collectorUrl: string;
  desktop: boolean;
  message: string;
  storagePath: string | null;
};

const browserStatus: DesktopRuntimeStatus = {
  collectorManaged: false,
  collectorPid: null,
  collectorRunning: false,
  collectorUrl: "http://127.0.0.1:17321",
  desktop: false,
  message: "Native runtime controls are available in the desktop app.",
  storagePath: null,
};

export function isDesktopApp(): boolean {
  return "__TAURI_INTERNALS__" in window;
}

export async function getDesktopRuntimeStatus(): Promise<DesktopRuntimeStatus> {
  if (!isDesktopApp()) return browserStatus;
  return invoke<DesktopRuntimeStatus>("desktop_runtime_status");
}

export async function ensureDesktopCollector(): Promise<DesktopRuntimeStatus> {
  if (!isDesktopApp()) return browserStatus;
  return invoke<DesktopRuntimeStatus>("start_desktop_collector");
}

export async function stopDesktopCollector(): Promise<DesktopRuntimeStatus> {
  if (!isDesktopApp()) return browserStatus;
  return invoke<DesktopRuntimeStatus>("stop_desktop_collector");
}
