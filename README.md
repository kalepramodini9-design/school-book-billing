# School Book Billing Mobile App

Offline school textbook + notebook/stationery billing application built with Flutter.

## Main features
- School, academic year and standard selection
- Student name and mobile number
- TextBooks (A) and Notebook & Stationery (B)
- Quantity +/- controls and automatic calculation
- Invoice numbering
- Local SQLite storage; no server or monthly hosting
- Bill history and search
- PDF preview, printing and sharing
- Editable school/standard masters
- Sample Venus World School 4th Standard 2026-27 data
- Android APK cloud-build workflow included

## Build from a phone
See `BUILD_FROM_PHONE.md`. GitHub Actions can compile the APK without a PC.

## Local build (if a computer is available later)
```bash
flutter create . --platforms=android,ios
flutter pub get
flutter build apk --release
```

APK output:
`build/app/outputs/flutter-apk/app-release.apk`
