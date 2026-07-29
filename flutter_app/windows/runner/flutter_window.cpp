#include "flutter_window.h"

#include <optional>
#include <shellapi.h>
#include <vector>

#include "flutter/generated_plugin_registrant.h"
#include "resource.h"
#include "utils.h"

namespace {
constexpr UINT kTrayIconId = 1;
constexpr UINT kTrayMessage = WM_APP + 1;

flutter::EncodableValue GetActivitySnapshot() {
  HWND foreground = GetForegroundWindow();
  const int title_length = GetWindowTextLengthW(foreground);
  std::vector<wchar_t> title(static_cast<size_t>(title_length) + 1, L'\0');
  GetWindowTextW(foreground, title.data(), static_cast<int>(title.size()));

  DWORD process_id = 0;
  GetWindowThreadProcessId(foreground, &process_id);
  std::wstring process_name = L"Unknown";
  HANDLE process = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE,
                               process_id);
  if (process != nullptr) {
    std::vector<wchar_t> process_path(32768, L'\0');
    DWORD process_path_size = static_cast<DWORD>(process_path.size());
    if (QueryFullProcessImageNameW(process, 0, process_path.data(),
                                   &process_path_size)) {
      std::wstring path(process_path.data(), process_path_size);
      const size_t separator = path.find_last_of(L"\\/");
      process_name = separator == std::wstring::npos
                         ? path
                         : path.substr(separator + 1);
      const size_t extension = process_name.rfind(L'.');
      if (extension != std::wstring::npos) {
        process_name = process_name.substr(0, extension);
      }
    }
    CloseHandle(process);
  }

  LASTINPUTINFO last_input{};
  last_input.cbSize = sizeof(LASTINPUTINFO);
  GetLastInputInfo(&last_input);
  const ULONGLONG idle_ms = GetTickCount64() - last_input.dwTime;

  flutter::EncodableMap result;
  result[flutter::EncodableValue("foregroundWindowTitle")] =
      flutter::EncodableValue(Utf8FromUtf16(title.data()));
  result[flutter::EncodableValue("processName")] =
      flutter::EncodableValue(Utf8FromUtf16(process_name.c_str()));
  result[flutter::EncodableValue("processId")] =
      flutter::EncodableValue(static_cast<int64_t>(process_id));
  result[flutter::EncodableValue("idleMs")] =
      flutter::EncodableValue(static_cast<int64_t>(idle_ms));
  return flutter::EncodableValue(result);
}
}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project,
                             bool start_hidden)
    : project_(project), start_hidden_(start_hidden) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  RegisterLifecycleChannel();
  SetChildContent(flutter_controller_->view()->GetNativeWindow());
  AddTrayIcon();

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    if (!start_hidden_) {
      this->Show();
    }
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  RemoveTrayIcon();
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  switch (message) {
    case WM_CLOSE:
      if (!exiting_) {
        HideToTray();
        return 0;
      }
      break;
    case WM_SYSCOMMAND:
      if ((wparam & 0xFFF0) == SC_MINIMIZE) {
        HideToTray();
        return 0;
      }
      break;
    case kTrayMessage:
      if (lparam == WM_LBUTTONUP || lparam == WM_LBUTTONDBLCLK) {
        ShowFromTray();
        return 0;
      }
      break;
  }

  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

void FlutterWindow::AddTrayIcon() {
  if (tray_icon_added_) {
    return;
  }

  notify_icon_data_ = {};
  notify_icon_data_.cbSize = sizeof(NOTIFYICONDATA);
  notify_icon_data_.hWnd = GetHandle();
  notify_icon_data_.uID = kTrayIconId;
  notify_icon_data_.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP;
  notify_icon_data_.uCallbackMessage = kTrayMessage;
  notify_icon_data_.hIcon =
      LoadIcon(GetModuleHandle(nullptr), MAKEINTRESOURCE(IDI_APP_ICON));
  wcscpy_s(notify_icon_data_.szTip, L"What Do You Do");

  tray_icon_added_ = Shell_NotifyIcon(NIM_ADD, &notify_icon_data_) == TRUE;
}

void FlutterWindow::RemoveTrayIcon() {
  if (!tray_icon_added_) {
    return;
  }

  Shell_NotifyIcon(NIM_DELETE, &notify_icon_data_);
  tray_icon_added_ = false;
}

void FlutterWindow::HideToTray() {
  ShowCommand(SW_HIDE);
}

void FlutterWindow::ShowFromTray() {
  ShowCommand(SW_RESTORE);
  SetForegroundWindow(GetHandle());
}

void FlutterWindow::ExitApplication() {
  exiting_ = true;
  Destroy();
}

void FlutterWindow::RegisterLifecycleChannel() {
  lifecycle_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "wdyd/window_lifecycle",
          &flutter::StandardMethodCodec::GetInstance());

  lifecycle_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        const std::string& method = call.method_name();
        if (method == "show") {
          ShowFromTray();
          result->Success();
          return;
        }
        if (method == "hideToTray") {
          HideToTray();
          result->Success();
          return;
        }
        if (method == "exit") {
          result->Success();
          ExitApplication();
          return;
        }

        result->NotImplemented();
      });

  activity_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "wdyd/native_activity",
          &flutter::StandardMethodCodec::GetInstance());
  activity_channel_->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
             result) {
        if (call.method_name() == "getActivitySnapshot") {
          result->Success(GetActivitySnapshot());
          return;
        }
        result->NotImplemented();
      });
}
