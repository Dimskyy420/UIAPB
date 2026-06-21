# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**TASURU** (`pubspec.yaml` name: `tasuru_app`) is a Flutter app: a marketplace where students post task requests ("permintaan") and other students bid ("penawaran") to help complete them. The repo root is the active Flutter project; backend is entirely Firebase (no custom server).

UI text, code comments, and Firestore status values are in **Indonesian** — match that convention when adding to existing flows.

## Commands

```bash
flutter pub get              # install dependencies (run after editing pubspec.yaml)
flutter run                  # run on connected device/emulator
flutter analyze              # lint / static analysis (flutter_lints, see analysis_options.yaml)
flutter test                 # run all tests
flutter test test/widget_test.dart   # run a single test file
flutter build apk            # Android release build
```

There is no separate lint command — `flutter analyze` is the linter.

## Architecture

Layered MVC under `lib/`. Controllers hold all business logic and are the only layer that touches Firestore directly; views build UI and call controllers.

- **`lib/controller/`** — business logic, one controller per domain (`auth`, `request`, `bid`, `chat`, `review`, `profile`, `home`, `riwayat`). Controllers are plain classes instantiated directly in views (`final c = BidController()`); **no state-management package** is used. Reactivity comes from `StreamBuilder`/`FutureBuilder` over Firestore snapshots plus `setState`.
- **`lib/models/`** — data classes with `fromMap(id, data)` / `toMap()` for Firestore (de)serialization. Exception: `picked_location.dart` (`{ point: LatLng, address: String }`) is a transient result type returned by the map picker, not Firestore-backed.
- **`lib/views/`** — full screens, including the multi-step request creation wizard (`step1_kategori` → `step2_detail_screen` → `step3_waktu_lokasi_screen`).
- **`lib/widgets/`** — reusable UI (cards, custom nav, dialogs, profile avatar, and `location_picker_screen.dart` + `location_summary_card.dart` for the OSM map pinpoint feature, see below).
- **`lib/services/`** — cross-cutting concerns: push/local notifications, in-app notifications, OTP, EmailJS, and `location_service.dart` (device location + Nominatim reverse geocoding).
- **`lib/main.dart`** — entry point. Inits Firebase, shows `SplashScreen`, then routes to `AuthScreen`, `OtpScreen`, or `HomePage` based on auth + `emailVerified`.
- **`lib/firebase_options.dart`** — generated FlutterFire config.

### Firestore data model

Collections (see grep of `collection('...')` across `lib/`):

- `users/{uid}` — profile, `fcmToken`, `emailVerified` flag.
- `requests/{id}` — task posts (`userId`, `title`, `status`, budget, `location` (resolved address string, display-only), `lokasiLat`/`lokasiLng` (doubles, the canonical pin dropped via the map picker), etc.).
  - `requests/{id}/penawaran/{bidId}` — **bids** ("penawaran") as a subcollection (`helperUid`, `status`).
- `notifications/{id}` — in-app notifications (`toUid`, `isRead`, `type`).
- `reviews/{id}` — ratings/reviews after task completion.
- `chatRooms/{id}` + `chatRooms/{id}/messages/{id}` — 1:1 chat.
- `otp_sessions/{uid}` — transient OTP codes for 2FA.

Request lifecycle status values: `menunggu` → `berjalan` (and bid statuses `menunggu`/`diterima`/`ditolak`). When a creator accepts a bid (`BidController.terimaPenawaran`), it uses a batch to set the bid to `diterima` and the request to `berjalan`, **auto-rejects all other bids**, and sends in-app notifications to every affected helper. Bid streams over all of a user's bids use a Firestore **collectionGroup** query on `penawaran` (`streamMyBids`), which requires a composite index.

`lokasiLat`/`lokasiLng` are flat `double` fields, not a `GeoPoint`, to stay symmetric with `RequestModel`'s existing flat-field pattern. If "Layanan near me" proximity search becomes a requirement, migrate to `GeoPoint` + geohash, Firestore can't do native radius queries on two separate scalar fields.

### Authentication & 2FA

Two sign-in paths in `AuthController`: Google Sign-In (auto-trusted, `emailVerified: true`) and email/password. Email/password registration sets `emailVerified: false`; login then triggers a **custom OTP flow** (not Firebase's built-in email verification):

1. `OtpService.generateAndSave` writes a 6-digit code to `otp_sessions/{uid}` (5-min expiry, 5 attempts max).
2. `EmailJsService.sendOtp` emails it via the EmailJS REST API (credentials are hardcoded in `lib/services/emailjs_service.dart`).
3. `OtpScreen` verifies; on success `emailVerified` is set true and the session doc is deleted.

The `emailVerified` field on the user doc is the source of truth for routing in both `main.dart` and `AuthController`.

### Notifications

Two parallel systems:
- **`NotificationService`** — Firebase Cloud Messaging (FCM) + `flutter_local_notifications`. Stores `fcmToken` on the user doc; clears it on logout. Background handler is a top-level `@pragma('vm:entry-point')` function.
- **`InAppNotificationService`** — Firestore-backed notification feed (`notifications` collection), driven by controller actions (e.g. bid received/accepted/rejected).

### Location picker (OSM)

`step3_waktu_lokasi_screen` embeds `LocationSummaryCard` under "Lokasi Pertemuan": an always-visible "Pilih lokasi di peta" tile, plus a second tile showing the resolved address once one's been picked. Tapping it pushes `LocationPickerScreen` and awaits a `PickedLocation`.

`LocationPickerScreen` renders an OSM tile layer via `flutter_map`/`latlong2`. It opens centered on the previous selection, or `LocationService.telkomUniversity` (`LatLng(-6.973970, 107.629799)`, the campus centroid, not a specific building) if there is none. Tapping the map moves the pin and calls `LocationService.reverseGeocode` against OSM's free Nominatim `/reverse` endpoint to resolve a display address; this is best-effort and falls back to a placeholder string on failure, since the coordinate pair, not the address text, is the value actually persisted. A "locate me" FAB calls `LocationService.getCurrentPosition()` via `geolocator`, separate from the initial-center fallback above. Confirming pops `PickedLocation(point, address)`, which step-3 writes into `lokasiLat`/`lokasiLng` and `location` on submit.

Constraints to watch: Nominatim is rate-limited to 1 req/sec and requires a real `User-Agent` (the placeholder in `location_service.dart` needs a real contact before release, not a generic one, or requests risk getting blocked); the OSM tile server's usage policy disallows heavy production traffic on the free endpoint and requires the `RichAttributionWidget` already in the screen, don't remove it; `geolocator` needs `ACCESS_FINE_LOCATION` (Android) / `NSLocationWhenInUseUsageDescription` (iOS) declared, or the locate-me button silently no-ops on real devices; `flutter_map`, `latlong2`, `geolocator`, and an explicit `http` entry (previously only transitive via Flutter's plugin graph, now also called directly here and in `EmailJsService`) need adding to `pubspec.yaml`.