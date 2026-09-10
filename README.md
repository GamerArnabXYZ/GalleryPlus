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

- **Android 11+ (API 30+):** native MediaStore trash via
  `PhotoManager.editor.android.moveToTrash()` — recoverable from the system
  Photos/Files app for 30 days.
- **Android 8–10 (API 26-29):** `moveToTrash` throws on these versions, so
  `MediaDeleteService` catches that and falls back to GalleryPlus's own
  trash — the file is copied into the app's private storage, tracked in
  Hive, and auto-purged after 30 days (`TrashRepository.purgeExpired()`,
  called once on every app start).

## Before your first build

1. **App icons** — I didn't generate `mipmap-*` launcher icons (no image
   asset was provided). Easiest: drop your icon into `assets/icon.png` and
   add `flutter_launcher_icons` as a dev dependency, or place PNGs manually
   under `android/app/src/main/res/mipmap-*/ic_launcher.png`.
2. **Release signing** — `android/app/build.gradle`'s `release` build type
   currently signs with the **debug** key so `flutter build apk --release`
   works out of the box. Swap in a real `signingConfig` before a Play Store
   release.
3. **Verify pinned versions** — I couldn't run `flutter pub get` in this
   environment, so package versions in `pubspec.yaml` (photo_manager,
   media_kit, riverpod, etc.) are current-as-of-research but not resolved.
   Run `flutter pub get` first; if any version conflicts, bump the ^caret
   floor for that package.
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
