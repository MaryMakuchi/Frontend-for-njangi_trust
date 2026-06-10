# Njangi Trust Mobile Application

Production-ready Flutter frontend for **Njangi Trust** — a digital platform that automates traditional African/Cameroonian rotating savings and credit associations (Njangi/ROSCA).

## Tech Stack

- **Flutter** (latest stable) + **Dart**
- **Riverpod** — state management
- **GoRouter** — navigation
- **Clean Architecture** — core / data / domain / presentation
- **Firebase** — placeholders for Auth, FCM, Storage (optional)
- **Mock API** — works offline until Django backend is connected

## Project Structure

```
lib/
├── core/
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   └── services/
├── data/
│   ├── models/
│   ├── repositories/
│   └── datasources/
├── domain/
│   ├── entities/
│   ├── usecases/
│   └── repositories/
├── presentation/
│   ├── screens/
│   ├── widgets/
│   ├── providers/
│   └── routes/
├── firebase/
└── main.dart
```

## Prerequisites

- Flutter SDK 3.16+ ([install guide](https://docs.flutter.dev/get-started/install))
- Android Studio or VS Code with Flutter extension
- Android emulator or physical device

## Installation

```bash
cd njangi_trust
flutter pub get
```

## Run on Android Emulator

1. Start an Android emulator (Android Studio → Device Manager).
2. Verify device is connected:

```bash
flutter devices
```

3. Run the app:

```bash
flutter run
```

## Demo Credentials

The app uses **mock authentication**. Any valid email/password (8+ chars) works for login.

- **Phone OTP demo code:** `123456`
- **Join group invite code:** `NJA2025`

## Features Implemented

| Module | Status |
|--------|--------|
| Splash & Onboarding | ✅ |
| Register / Login / OTP / KYC / PIN | ✅ |
| Dashboard with MRI Score | ✅ |
| Groups (list, create, join, details) | ✅ |
| Contributions & Payment flow | ✅ |
| Loans (eligibility, request, tracking) | ✅ |
| Profile & Settings | ✅ |
| Notifications | ✅ |
| Savings chart | ✅ |
| Social Fund | ✅ |
| Blockchain Ledger (mock) | ✅ |
| Bottom navigation | ✅ |

## Firebase Setup (Optional)

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com).
2. Install FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

3. Replace placeholders in `lib/firebase/firebase_options.dart`.
4. In `lib/main.dart`, enable Firebase:

```dart
await initializeFirebase(useFirebase: true);
```

## Django Backend Integration

The app is connected to the Django API by default.

1. Start the backend: see `../njangi_trust_api/README.md`
2. API URL is auto-detected in `lib/core/constants/app_constants.dart`:
   - Linux/desktop: `http://127.0.0.1:8000/api/v1`
   - Android emulator: `http://10.0.2.2:8000/api/v1`
3. Set `AppConstants.useMockData = true` to use offline mock data again.
4. Demo login: `makuchi@example.com` / `password123`

## Sample Test Data

Mock data lives in `lib/data/datasources/mock_data.dart`:
- User: Makuchi (MRI 9.4)
- 3 Njangi groups
- Contributions, loans, transactions, notifications

## Code Quality

```bash
flutter analyze
flutter test
```

## License

Proprietary — Njangi Trust project.
