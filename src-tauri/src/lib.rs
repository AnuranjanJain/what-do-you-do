use serde::Serialize;
use std::{
    net::{SocketAddr, TcpStream},
    path::PathBuf,
    process::{Child, Command, Stdio},
    str::FromStr,
    sync::Mutex,
    time::Duration,
};
use tauri::{AppHandle, Manager, State};

const COLLECTOR_URL: &str = "http://127.0.0.1:17321";
const COLLECTOR_ADDRESS: &str = "127.0.0.1:17321";

#[derive(Default)]
struct DesktopState {
    collector: Mutex<Option<Child>>,
    last_error: Mutex<Option<String>>,
    storage_path: Mutex<Option<String>>,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct DesktopRuntimeStatus {
    desktop: bool,
    collector_running: bool,
    collector_managed: bool,
    collector_pid: Option<u32>,
    collector_url: &'static str,
    storage_path: Option<String>,
    message: String,
}

#[tauri::command]
fn desktop_runtime_status(state: State<'_, DesktopState>) -> DesktopRuntimeStatus {
    runtime_status(&state)
}

#[tauri::command]
fn start_desktop_collector(
    app: AppHandle,
    state: State<'_, DesktopState>,
) -> Result<DesktopRuntimeStatus, String> {
    if collector_is_listening() {
        return Ok(runtime_status(&state));
    }

    let mut managed_child_is_running = false;
    {
        let mut child_guard = state
            .collector
            .lock()
            .map_err(|_| "Collector state is unavailable.")?;
        if let Some(child) = child_guard.as_mut() {
            match child.try_wait() {
                Ok(None) => {
                    managed_child_is_running = true;
                }
                Ok(Some(_)) => {
                    child_guard.take();
                }
                Err(error) => {
                    child_guard.take();
                    set_last_error(&state, error.to_string());
                }
            }
        }
    }

    if managed_child_is_running {
        return Ok(runtime_status(&state));
    }

    let script_path = collector_script_path()?;
    let storage_path = app
        .path()
        .app_data_dir()
        .map_err(|error| format!("Unable to resolve desktop storage: {error}"))?
        .join("data");
    std::fs::create_dir_all(&storage_path)
        .map_err(|error| format!("Unable to create desktop storage: {error}"))?;

    let child = Command::new("node")
        .arg(&script_path)
        .env("WDYD_DATA_DIR", &storage_path)
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .creation_flags(CREATE_NO_WINDOW)
        .spawn()
        .map_err(|error| {
            let message = format!(
                "Unable to start the collector. Install Node.js or start it manually: {error}"
            );
            set_last_error(&state, message.clone());
            message
        })?;

    *state
        .collector
        .lock()
        .map_err(|_| "Collector state is unavailable.")? = Some(child);
    *state
        .storage_path
        .lock()
        .map_err(|_| "Storage state is unavailable.")? =
        Some(storage_path.to_string_lossy().into_owned());
    *state
        .last_error
        .lock()
        .map_err(|_| "Collector state is unavailable.")? = None;

    Ok(runtime_status(&state))
}

#[tauri::command]
fn stop_desktop_collector(state: State<'_, DesktopState>) -> Result<DesktopRuntimeStatus, String> {
    stop_managed_collector(&state)?;
    Ok(runtime_status(&state))
}

fn collector_script_path() -> Result<PathBuf, String> {
    let project_root = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .map(PathBuf::from)
        .ok_or_else(|| "Unable to resolve the project root.".to_string())?;
    let script_path = project_root.join("scripts/collector/local-activity-collector.mjs");

    if script_path.is_file() {
        Ok(script_path)
    } else {
        Err(format!(
            "Collector script was not found at {}.",
            script_path.display()
        ))
    }
}

fn collector_is_listening() -> bool {
    let Ok(address) = SocketAddr::from_str(COLLECTOR_ADDRESS) else {
        return false;
    };
    TcpStream::connect_timeout(&address, Duration::from_millis(180)).is_ok()
}

fn runtime_status(state: &DesktopState) -> DesktopRuntimeStatus {
    let mut managed = false;
    let mut pid = None;

    if let Ok(mut child_guard) = state.collector.lock() {
        if let Some(child) = child_guard.as_mut() {
            match child.try_wait() {
                Ok(None) => {
                    managed = true;
                    pid = Some(child.id());
                }
                Ok(Some(_)) | Err(_) => {
                    child_guard.take();
                }
            }
        }
    }

    let running = collector_is_listening();
    let last_error = state.last_error.lock().ok().and_then(|error| error.clone());
    let storage_path = state.storage_path.lock().ok().and_then(|path| path.clone());

    let message = if managed && running {
        "Collector is managed by the desktop app.".to_string()
    } else if running {
        "Collector is running as an external local process.".to_string()
    } else if managed {
        "Collector is starting.".to_string()
    } else {
        last_error.unwrap_or_else(|| "Collector is not running.".to_string())
    };

    DesktopRuntimeStatus {
        desktop: true,
        collector_running: running,
        collector_managed: managed,
        collector_pid: pid,
        collector_url: COLLECTOR_URL,
        storage_path,
        message,
    }
}

fn stop_managed_collector(state: &DesktopState) -> Result<(), String> {
    let mut child_guard = state
        .collector
        .lock()
        .map_err(|_| "Collector state is unavailable.")?;

    if let Some(mut child) = child_guard.take() {
        child
            .kill()
            .map_err(|error| format!("Unable to stop the collector: {error}"))?;
        let _ = child.wait();
    }

    Ok(())
}

fn set_last_error(state: &DesktopState, message: String) {
    if let Ok(mut error) = state.last_error.lock() {
        *error = Some(message);
    }
}

#[cfg(target_os = "windows")]
const CREATE_NO_WINDOW: u32 = 0x08000000;
#[cfg(not(target_os = "windows"))]
const CREATE_NO_WINDOW: u32 = 0;

trait CommandWindowFlags {
    fn creation_flags(&mut self, flags: u32) -> &mut Self;
}

#[cfg(target_os = "windows")]
impl CommandWindowFlags for Command {
    fn creation_flags(&mut self, flags: u32) -> &mut Self {
        use std::os::windows::process::CommandExt;
        CommandExt::creation_flags(self, flags)
    }
}

#[cfg(not(target_os = "windows"))]
impl CommandWindowFlags for Command {
    fn creation_flags(&mut self, _flags: u32) -> &mut Self {
        self
    }
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .manage(DesktopState::default())
        .invoke_handler(tauri::generate_handler![
            desktop_runtime_status,
            start_desktop_collector,
            stop_desktop_collector
        ])
        .setup(|app| {
            if cfg!(debug_assertions) {
                app.handle().plugin(
                    tauri_plugin_log::Builder::default()
                        .level(log::LevelFilter::Info)
                        .build(),
                )?;
            }
            Ok(())
        })
        .on_window_event(|window, event| {
            if matches!(event, tauri::WindowEvent::Destroyed) {
                let state = window.state::<DesktopState>();
                let _ = stop_managed_collector(&state);
            }
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
