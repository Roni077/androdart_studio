# AGENTS.md

## Project

Flutter app targeting Android only. SDK constraint: `^3.11.5`. Kotlin Gradle DSL. App ID: `com.androdartstudio.flutteride.androdart_studio`.

## Commands

- `flutter pub get` — install deps (run after any pubspec change)
- `flutter analyze` — lint check (uses `flutter_lints` via `analysis_options.yaml`)
- `flutter test` — run widget tests in `test/`
- `flutter build apk --debug --split-per-abi` — local debug build
- `flutter build apk --release --split-per-abi` — release build (requires `android/key.properties` + keystore)

## CI

Single workflow: `.github/workflows/androdart_studio_android_build.yml`
Runs on push/PR to `master`. Pipeline: test → build-debug → build-release.
Release builds use keystore secrets (`KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`).
CI filters out `x86_64` APKs; only `arm64-v8a` and `armeabi-v7a` are uploaded as artifacts.

## Conventions

- No `ios/` or `windows/` directories — Android-only project.
- `android/key.properties` and `*.jks`/`*.keystore` are gitignored — never commit signing keys.
- Java 17 target (`compileOptions` / `kotlinOptions` in `android/app/build.gradle.kts`).
- Gradle JVM args tuned for large builds (`-Xmx8G`).
