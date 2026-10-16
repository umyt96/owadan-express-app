# Owadan Express

Owadan Express is a Flutter shopping app for iOS and Android. Customers can browse the catalog, discover brands and categories, save products, place orders, and follow their order history in one place.

## Features

- Product catalog with search, categories, brands, filters, and product details
- Favorites, shopping cart, checkout, delivery addresses, and order history
- Account registration and sign-in, including Google, Apple, and Yandex options supported by the backend
- Push notifications through Firebase Cloud Messaging on Android and iOS
- Russian, Turkmen, and English interface languages
- Light and dark themes
- In-app contact and support features

## Requirements

- Flutter SDK with Dart 3.5.4 or newer
- Android Studio or Xcode for the platform you want to run
- A configured Android emulator or iOS simulator/device
- Access to the Owadan Express API for live catalog and account data

## Getting started

```bash
git clone https://github.com/Dadebay/Owadan-express.git
cd Owadan-express
flutter pub get
flutter run
```

The app's API base URL is defined in [`lib/config/api_config.dart`](lib/config/api_config.dart). The included configuration points to `https://owadanexpress.com.tm/api/v1`.

Firebase client configuration is included for the current Android and iOS app identifiers. To use another Firebase project, replace `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist` with files for your own app identifiers, then configure push notifications for those apps. iOS push notifications require an APNs key in Firebase and a physical device for testing.

## Build

```bash
flutter build apk
flutter build ios
```

Release signing requires your own Android signing configuration and Apple development team. Keep keystores, signing passwords, APNs keys, and Apple Sign in private keys out of the repository.

## Project layout

| Path | Purpose |
| --- | --- |
| `lib/screens/` | App pages and flows |
| `lib/widgets/` | Reusable interface components |
| `lib/providers/` | App state for authentication, cart, language, and theme |
| `lib/services/` | API, authentication, checkout, analytics, and notifications |
| `lib/models/` | Data models |
| `lib/l10n/` | Interface strings |
| `assets/` | Branding, illustrations, icons, and fonts |

## Tests

```bash
flutter test
```
