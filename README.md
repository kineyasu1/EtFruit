# Agriገበያ (EtFruit) - Ethiopian Agricultural Marketplace

Agriገበያ (EtFruit) is a production-ready, multi-lingual agricultural marketplace mobile application built in Flutter. The platform enables Ethiopian farmers (sellers) and buyers to trade agricultural products directly, check real-time pricing, chat, track orders, and secure transactions.

---

## Features

- [x] **Multi-Language Support**: Fully localized in English, Amharic (አማርኛ), Afaan Oromo (Oromoo), Somali (Soomaali), and Tigrinya (ትግርኛ).
- [x] **OTP & Password Authentication**: Secure phone-number-based login using Firebase Auth.
- [x] **Dynamic Listings Feed**: Search, filter by category/region, and paginate products using Firestore query cursors.
- [x] **Order Management State Machine**: Sequential status tracking: `pending` → `confirmed` → `preparing` → `shipped` → `delivered`/`completed`/`cancelled`.
- [x] **In-App Messaging & Notifications**: Real-time push notifications via Firebase Cloud Messaging (FCM).
- [x] **Deep Linking**: Direct navigation to products (`/product/{id}`), orders (`/order/{id}`), and profiles (`/user/{id}`) using Android App Links and iOS Universal Links.
- [x] **Robust Security Rules**: Complete, schema-validated rules for Firestore and Storage.

---

## Architecture & Project Structure

The project follows a clean feature-first architecture using **Flutter Riverpod** for state management.

```text
lib/
├── l10n/                 # ARB translation files
├── models/               # Schema-validated data models (UserModel, ListingModel)
├── providers/            # Riverpod state providers (auth, language)
├── services/             # Firebase & local cache wrappers (Firestore, Auth, Notification)
├── utils/                # Pure business logic utilities (OrderStateMachine)
└── views/                # Screen layouts and widgets
    ├── auth/             # Login, profile setup, and onboarding screens
    ├── cart/             # Shopping cart and order tracking screens
    ├── chat/             # Chat lists and detail messaging screens
    ├── home/             # Main dashboard and listings feed
    ├── listing/          # Product creation and detail screens
    └── profile/          # User and seller profiles
```

---

## Setup Instructions

### Prerequisites
- Flutter SDK `3.44.x` (or newer stable release)
- Dart SDK `3.12.x`
- Firebase CLI (for rules & functions deployment)

### Clone & Install
1. Clone the repository:
   ```bash
   git clone https://github.com/kineyasu1/EtFruit.git
   cd EtFruit
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```

### Firebase Configuration
1. Create a Firebase project in the [Firebase Console](https://console.firebase.google.com/).
2. Enable the following services:
   - **Authentication**: Phone Authentication and Email/Password sign-in.
   - **Cloud Firestore**: Start in test mode, then deploy rules.
   - **Cloud Storage**: Enable storage bucket for images.
   - **Cloud Messaging**: Enable FCM for push notifications.
3. Download config files:
   - Android: `google-services.json` to `android/app/`
   - iOS: `GoogleService-Info.plist` to `ios/Runner/`

### Deployment of Rules & Functions
1. Log in to Firebase CLI:
   ```bash
   firebase login
   ```
2. Deploy Firestore & Storage rules:
   ```bash
   firebase deploy --only firestore:rules,storage
   ```

---

## Running the App

Run the application locally in debug mode (uses local sandbox mock database if `google-services.json` is missing):
```bash
flutter run
```

Build release split APKs for distribution:
```bash
flutter build apk --release --split-per-abi
```

---

## Running Tests

Execute the automated unit and widget test suite:
```bash
flutter test
```

Execute end-to-end integration tests:
```bash
flutter test integration_test/app_integration_test.dart
```

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
