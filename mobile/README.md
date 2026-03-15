# WoodGuard Mobile

Flutter mobile client for the existing WoodGuard FastAPI backend.

## What is implemented

- Login against `/api/v1/auth/login`
- Refresh token based session restore with secure storage
- Dashboard metrics screen
- Invoice queue with search and risk/status filters
- Manual invoice creation
- Full dossier editor for metadata, seller card, wood specification and risk inputs
- Mobile geolocation capture and backend reverse geocoding
- Evidence upload into invoice sections
- Invoice audit trail and risk recap
- Warehub sync trigger from the account screen for allowed roles

## Stack

- Flutter 3.41+
- `provider` for app/session state
- `http` for REST and multipart uploads
- `flutter_secure_storage` for access and refresh tokens
- `shared_preferences` for editable API base URL
- `geolocator` for device location
- `file_picker` for evidence uploads
- `url_launcher` for file and map links

## Run

Use Flutter `3.41.x` or newer.

```bash
cd mobile
flutter pub get
flutter run
```

Run static analysis:

```bash
flutter analyze
```

## API URL

The app stores API base URL locally and lets you change it on the login and account screens.

Examples:

- Android emulator: `http://10.0.2.2:8000/api/v1`
- iOS simulator: `http://127.0.0.1:8000/api/v1`
- Physical device: `http://YOUR-LAN-IP:8000/api/v1`

## Notes

- Android manifest enables cleartext HTTP because local development uses non-HTTPS API URLs.
- iOS `Info.plist` allows local HTTP requests and location access for dossier geolocation capture.
- The app talks directly to the same REST endpoints as the web workspace.
- If you switch backend host inside the app, sign in again if the old session belongs to another server.
