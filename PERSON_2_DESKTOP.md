# Person 2 — Desktop Integration Guide

**Role:** Flutter + Next.js Developer
**Goal:** Configure the Flutter codebase to compile natively for Windows and macOS, implement responsive layouts, and secure desktop environments.

---

## 1. Project Configuration

Your single Flutter codebase will now target 4 platforms: Android, iOS, Windows, and macOS.

### Enable Desktop Support
Ensure desktop support is enabled on your local machine:
```bash
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop
flutter create . 
```
*(This injects the `windows/` and `macos/` platform folders into the repository).*

## 2. Responsive UI (Breakpoints)

A mobile app stretched across a 27" monitor looks terrible. You must implement breakpoints.

### Navigation
- **Mobile (Width < 600px):** Use a `BottomNavigationBar`.
- **Desktop (Width >= 600px):** Switch to a `NavigationRail` or a side Drawer.

### Study & Exams Flow
- **PDF Viewer:** On desktop, allow the PDF viewer to take up the majority of the screen, with a side panel for thumbnails or chapters.
- **Exams:** Use a multi-column layout. Place the question stem on the left, options on the right, and the question palette (grid of 1-100) permanently visible on the side so users don't have to open a drawer to jump between questions.

## 3. Desktop Security

Desktop environments are inherently more open than mobile, so we must add plugins to lock them down.

### Blocking Screenshots & Screen Recording
Android has `FLAG_SECURE`, but Windows and macOS require OS-level hooks.
**Task:** Install the `window_manager` or `screen_retriever` package.
```dart
import 'package:window_manager/window_manager.dart';

void secureDesktop() async {
  await windowManager.ensureInitialized();
  // Prevents screenshots and screen recordings on Windows/macOS
  await windowManager.setPreventClose(true); 
}
```
*(Note: Always test this thoroughly on both Windows and macOS, as the underlying APIs (`SetWindowDisplayAffinity` on Win, `CGDisplayStream` on Mac) behave slightly differently).*

### Encrypted Offline Storage
Ensure `flutter_secure_storage` is correctly configured for desktop. On macOS, this uses the Keychain. On Windows, it uses the Data Protection API (DPAPI).
Downloaded PDFs must remain encrypted on the hard drive and decrypted only into memory within the app.

## 4. Hardware ID & API Communication

To support the 2-device limit (Mobile + Desktop):
1. Use `device_info_plus` to grab the hardware UUID (Windows `deviceId`, macOS `systemGUID`).
2. Pass `X-Device-Type: DESKTOP` in your Dio interceptors to Person 1’s API so the backend knows which session limit to apply.
