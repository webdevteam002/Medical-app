#include "flutter_window.h"

#include <optional>

#include <flutter/standard_method_codec.h>

#include "flutter/generated_plugin_registrant.h"

#ifndef WDA_EXCLUDEFROMCAPTURE
#define WDA_EXCLUDEFROMCAPTURE 0x00000011
#endif

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::SetCaptureProtection(bool enabled) {
  HWND hwnd = GetHandle();
  if (!hwnd) {
    return false;
  }

  if (!enabled) {
    return SetWindowDisplayAffinity(hwnd, WDA_NONE) == TRUE;
  }

  // Prefer exclude-from-capture (Win10 2004+); fall back to monitor affinity.
  if (SetWindowDisplayAffinity(hwnd, WDA_EXCLUDEFROMCAPTURE) == TRUE) {
    return true;
  }
  return SetWindowDisplayAffinity(hwnd, WDA_MONITOR) == TRUE;
}

void FlutterWindow::RegisterSecurityChannel() {
  if (!flutter_controller_ || !flutter_controller_->engine()) {
    return;
  }

  security_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "com.medstudy/security",
          &flutter::StandardMethodCodec::GetInstance());

  security_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        if (call.method_name() == "enableSecureScreen") {
          result->Success(flutter::EncodableValue(SetCaptureProtection(true)));
          return;
        }
        if (call.method_name() == "disableSecureScreen") {
          result->Success(flutter::EncodableValue(SetCaptureProtection(false)));
          return;
        }
        result->NotImplemented();
      });
}

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
  RegisterSecurityChannel();
  // Block screenshots / screen recording of the app window by default.
  SetCaptureProtection(true);
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  security_channel_ = nullptr;
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
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
