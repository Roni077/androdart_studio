# androdart_studio — Implementation TODO

## Overview

Lightweight Flutter IDE for Android. All features work without root via proot.
Flutter 3.44.4 + Dart 3.12.2 + Debian bookworm rootfs.

---

## Phase 1: Project Scaffolding ✅

### 1.1 Dependencies
- [x] Update `pubspec.yaml` with all dependencies
- [x] Run `flutter pub get`
- [x] Verify no dependency conflicts

### 1.2 Android Build Config
- [x] Add JitPack repository to `android/build.gradle.kts`
- [x] Add `useLegacyPackaging = true` to `android/app/build.gradle.kts`
- [x] Add libsu dependencies to `android/app/build.gradle.kts`

### 1.3 Permissions
- [x] Add INTERNET permission to AndroidManifest.xml
- [x] Add READ/WRITE_EXTERNAL_STORAGE permissions
- [x] Add MANAGE_EXTERNAL_STORAGE permission
- [x] Add SAF document provider declaration

### 1.4 Native Binaries
- [x] Download proot binaries (real ARM64 ELF binaries)
- [x] Place in `android/app/src/main/jniLibs/arm64-v8a/`

### 1.5 Rootfs Asset
- [x] Rootfs downloaded on first launch (~47 MiB from GitHub)

### 1.6 Native PTY Code
- [x] Create `android/app/src/main/c/pty.c`
- [x] Implement openpty/forkpty/execve
- [x] Add CMakeLists.txt for native build

### 1.7 MainActivity Bridge
- [x] Extend MainActivity.kt with MethodChannel handlers
- [x] Add EventChannel for streaming output
- [x] Add proot execution channel
- [x] Add PTY channel
- [x] Add nativeLibraryDir path provider

### 1.8 SAF Document Provider
- [x] Create `AndrodartStorageProvider.kt`
- [x] Implement queryRoots, queryChildDocuments
- [x] Implement openDocument, createDocument
- [x] Register in AndroidManifest.xml

---

## Phase 2: Core Services ✅

### 2.1 Proot Service
- [x] Create `lib/core/proot_service.dart`
- [x] Implement `extractRootfs()`
- [x] Implement `isRootfsReady()`
- [x] Implement `getNativeLibDir()`
- [x] Implement `buildProotCommand()`

### 2.2 Shell Service
- [x] Create `lib/core/shell_service.dart`
- [x] Implement `startShell()`
- [x] Implement `run()`
- [x] Implement `writeInput()`
- [x] Implement `resize()`
- [x] Implement `close()`

### 2.3 File Service
- [x] Create `lib/core/file_service.dart`
- [x] Implement SAF-based operations
- [x] Implement direct filesystem access
- [x] Implement `listDir()`, `readFile()`, `writeFile()`

### 2.4 SDK Manager
- [x] Create `lib/core/sdk_manager.dart`
- [x] Implement status checks (isJdkInstalled, isFlutterInstalled, etc.)

### 2.5 Build Service
- [x] Create `lib/core/build_service.dart`
- [x] Implement `flutterCreate()`
- [x] Implement `flutterBuild()`
- [x] Implement `flutterPubGet()`
- [x] Implement `flutterClean()`

### 2.6 Storage Service
- [x] Create `lib/core/storage_service.dart`
- [x] Implement `setupStorage()`
- [x] Implement `isStorageSetup()`
- [x] Create symlinks in rootfs

### 2.7 Settings Service
- [x] Create `lib/core/settings_service.dart`
- [x] Implement shared_preferences persistence

---

## Phase 3: SDK Manager UI ✅

### 3.1 Setup Wizard
- [x] Create `lib/sdk/setup_wizard.dart`
- [x] Design step-by-step progress UI
- [x] Show download progress bars
- [x] Add retry failed steps

### 3.2 Download Manager
- [x] Create `lib/sdk/download_manager.dart`
- [x] Implement HTTP download with progress
- [x] Handle network errors gracefully

---

## Phase 4: UI Shell ✅

### 4.1 App Shell
- [x] Create `lib/ui/app_shell.dart`
- [x] Implement bottom tab navigation
- [x] Add Editor, Terminal, Files tabs

### 4.2 Theme
- [x] Create `lib/ui/theme.dart`
- [x] Design dark IDE color scheme
- [x] Define text styles

### 4.3 Toolbar
- [x] Create `lib/ui/toolbar.dart`
- [x] Design context-sensitive actions
- [x] Add Run, Build, Save, Open Folder buttons

### 4.4 Status Bar
- [x] Create `lib/ui/status_bar.dart`
- [x] Show SDK status indicator
- [x] Show line:col for editor
- [x] Show encoding

---

## Phase 5: Code Editor ✅

### 5.1 Editor Tab
- [x] Create `lib/editor/editor_tab.dart`
- [x] Design editor container with tabs
- [x] Handle open/close tabs

### 5.2 Code Editor Widget
- [x] Create `lib/editor/code_editor.dart`
- [x] Integrate re_editor
- [x] Add line numbers
- [x] Add code folding

### 5.3 Tab Manager
- [x] Create `lib/editor/tab_manager.dart`
- [x] Manage open file tabs
- [x] Track unsaved changes
- [x] Handle tab switching

---

## Phase 6: Terminal ✅

### 6.1 Terminal Tab
- [x] Create `lib/terminal/terminal_tab.dart`
- [x] Design terminal container
- [x] Add new session button
- [x] Add close session button

### 6.2 Terminal Widget
- [x] Create `lib/terminal/terminal_widget.dart`
- [x] Integrate xterm
- [x] Configure terminal theme

### 6.3 Terminal Session
- [x] Create `lib/terminal/terminal_session.dart`
- [x] Spawn proot shell via PTY
- [x] Read output from master FD
- [x] Write input to master FD
- [x] Support multiple concurrent sessions

---

## Phase 7: File Browser ✅

### 7.1 File Browser Tab
- [x] Create `lib/file_browser/file_browser_tab.dart`
- [x] Design file browser container
- [x] Add navigation controls

### 7.2 File Tree
- [x] Create `lib/file_browser/file_tree.dart`
- [x] Implement recursive directory listing
- [x] Implement expandable folder nodes
- [x] Lazy-load children
- [x] Error handling for permission denied

### 7.3 File Tile
- [x] Create `lib/file_browser/file_tile.dart`
- [x] Design file/folder entry widget
- [x] Add tap handler (open in editor)
- [x] Show file type icons

---

## Phase 8: Build Integration ✅

### 8.1 Build Screen
- [x] Create `lib/build/build_screen.dart`
- [x] Design full-screen build output viewer
- [x] Add copy output button

### 8.2 Build Runner
- [x] Create `lib/build/build_runner.dart`
- [x] Implement build orchestration
- [x] Track build status
- [x] Wire to real ShellService output

---

## Phase 9: LSP Integration ✅

### 9.1 LSP Client
- [x] Create `lib/lsp/lsp_client.dart`
- [x] Placeholder implementation (requires PTY bridge for Android)

### 9.2 Dart Analysis
- [x] Create `lib/lsp/dart_analysis.dart`
- [x] Placeholder implementation

---

## Phase 10: Polish ✅

### 10.1 Settings
- [x] Create settings page with SettingsService
- [x] SDK path configuration (persisted)
- [x] Font size configuration (persisted)
- [x] Auto save, line numbers, word wrap (persisted)

### 10.2 Error Handling
- [x] Root denied error screen
- [x] SDK missing error screen
- [x] Build failure error screen
- [x] Network error handling
- [x] Disk space error handling

### 10.3 Loading States
- [x] Loading indicator with progress
- [x] Loading overlay

### 10.4 About Page
- [x] Version info
- [x] Toolchain status
- [x] Credits

### 10.5 Lifecycle
- [x] Handle app pause/resume
- [x] Dispose resources properly

---

## Final Verification

- [x] App compiles (flutter analyze passes)
- [x] App builds (flutter build apk --debug succeeds)
- [ ] App installs on device (requires real device testing)
- [ ] First-launch wizard runs
- [ ] SDK installs successfully
- [ ] Terminal works
- [ ] Editor works
- [ ] File browser works
- [ ] Build APK works
- [ ] LSP works (placeholder only)
- [ ] Storage access works
