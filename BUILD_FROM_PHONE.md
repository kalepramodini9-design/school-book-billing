# Build the APK using only a phone

This project does not require a PC to build if you use GitHub Actions.

## Steps

1. On your Android phone, open GitHub in Chrome and sign in/create a free account.
2. Create a new repository, for example `school-book-billing`.
3. Upload all files from this project ZIP, including `.github/workflows/build-apk.yml`.
4. Open the repository's **Actions** tab.
5. Select **Build Android APK**.
6. Tap **Run workflow**.
7. Wait for the workflow to finish successfully.
8. Open the completed workflow run and scroll to **Artifacts**.
9. Download `school-book-billing-apk` on your phone.
10. Extract the downloaded ZIP and install `app-release.apk`.

The app itself is offline and stores billing data locally on the phone. GitHub is used only to compile the APK; it is not required for daily billing.

## Important

The current source is a functional starter version. Before using it for real billing, verify the receipt layout and enter the complete school/book/stationery master data. The sample Venus World School 4th Standard 2026-27 data is preloaded.
