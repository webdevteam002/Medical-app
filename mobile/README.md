# Mobile App (Flutter)

Student app for Android and iOS.

## Planned features

- Auth + single-device session
- Browse materials by year/subject
- Secure PDF viewer + watermark
- Android screenshot block (`FLAG_SECURE`)
- Encrypted in-app downloads
- Timed MCQ exams + instant results
- RevenueCat subscriptions

## Key packages (Phase 1+)

- `go_router` — navigation
- `flutter_secure_storage` — tokens
- `device_info_plus` — device fingerprint
- `pdfx` — PDF viewer
- `flutter_windowmanager` — Android FLAG_SECURE
- `purchases_flutter` — RevenueCat

## Setup (Phase 1)

```bash
flutter pub get
flutter run
```

See [../docs/ROADMAP.md](../docs/ROADMAP.md) Phase 1.
