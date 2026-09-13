# GalleryPlus

Local photo & video gallery — Flutter, Android 8 (API 26) → latest.

## Architecture

```
lib/
├── main.dart                 Hive + media_kit init, runApp
├── app.dart                  MaterialApp, theme, permission gate
├── core/
│   ├── theme/                Material 3 theme (dark-first), spacing scale
│   ├── permissions/          photo_manager permission wrapper (API 26-35+)
│   └── db/                   Hive init, TrashEntry model (hand-written adapter)
├── features/
│   ├── gallery/               album/asset repository, sort, paginated grid state
│   ├── viewer/                full-screen viewer: zoom, swipe-dismiss, video
│   ├── trash/                 custom in-app trash (API<30) + native trash trigger (API30+)
│   └── favorites/             Hive-backed favorite marks
└── shared/widgets/            permission gate, empty states
```

State management: **Riverpod** (classic `StateNotifierProvider`/`FutureProvider` —
no code generation, so there's no `build_runner` step needed in CI).

Local DB: **Hive**, with a hand-written `TypeAdapter` for `TrashEntry` (also no
codegen needed — keeps the CI pipeline simple).

## Delete / Trash behaviour (as discussed)

Every deleted item — on **every** Android version (API 26+) — moves into
GalleryPlus's own trash: the file is copied into the app's private
storage, tracked in Hive, and the original is removed from MediaStore.
Nothing ever goes to the OS-level MediaStore trash, so behaviour is
identical across every device/OEM. `TrashRepository.purgeExpired()` runs
once on every app start and silently removes anything past 30 days.

## Splash screen

Native (Kotlin) splash via AndroidX `core-splashscreen` — consistent
branded splash (purple background + app icon) on every Android version,
not just Android 12's built-in SplashScreen API. Wired up in:
- `styles.xml` — `Theme.App.Starting`
- `MainActivity.kt` — `installSplashScreen()` before `super.onCreate()`
- `AndroidManifest.xml` — MainActivity's theme

## Before your first build

1. **Storage trade-off, by design** — since everything now goes through
   the app's own trash, a deleted video sits in app-private storage
   (duplicated) until it's restored, permanently deleted, or the 30-day
   auto-purge runs. Worth knowing if someone deletes a lot of large videos
   at once.
2. **App icon** — I generated a simple placeholder launcher icon (purple,
   matches the app theme, gallery/photo glyph) at every mipmap density so
   the build doesn't fail on a missing resource. Swap it for your real
   branding whenever you want — just replace the PNGs under
   `android/app/src/main/res/mipmap-*/ic_launcher.png`.
2. **Release signing** — `android/app/build.gradle`'s `release` build type
   currently signs with the **debug** key so `flutter build apk --release`
   works out of the box. Swap in a real `signingConfig` before a Play Store
   release.
4. **Rename feature** — not implemented yet (photo_manager's rename API
   varies by version). Everything else in the requested feature list is in.

## Next step

You already push through GAX IDE, so no Termux step needed — just get these
files into a GAX IDE workspace folder (or push this zip's contents straight
to a new GitHub repo) and push via GAX IDE's Git Init / Push flow. CI
(`.github/workflows/android.yml`) runs `flutter pub get`, `flutter analyze`,
then builds split-per-ABI release APKs automatically on every push to
`main` — that's where package versions actually get resolved and validated,
since no Flutter SDK ran on this end.
