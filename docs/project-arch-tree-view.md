# androdart_studio — Project Architecture Tree View

## Overview

Lightweight Flutter IDE for Android. All features work without root via proot.
Flutter 3.44.4 + Dart 3.12.2 + Debian bookworm rootfs.

---

## Directory Structure

```
androdart_studio/
├── AGENTS.md                          # Agent instructions
├── README.md                          # Project readme
├── pubspec.yaml                       # Flutter dependencies
├── pubspec.lock                       # Dependency lock file
├── analysis_options.yaml              # Dart lint rules
├── .gitignore                         # Git ignore rules
│
├── lib/                               # Dart source code
│   ├── main.dart                      # App entry point + AppServices + MainScreen
│   │
│   ├── core/                          # Core services layer
│   │   ├── proot_service.dart         # Container lifecycle, rootfs extraction
│   │   ├── shell_service.dart         # proot shell execution
│   │   ├── file_service.dart          # SAF + rootfs file access
│   │   ├── sdk_manager.dart           # Tool installation inside proot
│   │   ├── build_service.dart         # Flutter build orchestration
│   │   └── storage_service.dart       # setup-storage, symlinks, permissions
│   │
│   ├── ui/                            # UI shell & navigation
│   │   ├── theme.dart                 # Dark IDE theme
│   │   ├── app_shell.dart             # Bottom tab navigation
│   │   ├── toolbar.dart               # Context-sensitive actions
│   │   ├── status_bar.dart            # SDK status, line:col
│   │   ├── settings_page.dart         # Settings UI
│   │   ├── error_screen.dart          # Error states
│   │   ├── loading_indicator.dart     # Loading UI
│   │   └── about_page.dart            # About info
│   │
│   ├── editor/                        # Code editor
│   │   ├── editor_tab.dart            # Editor container with tabs
│   │   ├── code_editor.dart           # re_editor wrapper
│   │   └── tab_manager.dart           # Multi-file tab state
│   │
│   ├── terminal/                      # Terminal emulator
│   │   ├── terminal_tab.dart          # Terminal container
│   │   ├── terminal_widget.dart       # xterm rendering
│   │   └── terminal_session.dart      # PTY process management
│   │
│   ├── file_browser/                  # File explorer
│   │   ├── file_browser_tab.dart      # File browser container
│   │   ├── file_tree.dart             # Recursive directory tree
│   │   └── file_tile.dart             # File/folder entry widget
│   │
│   ├── sdk/                           # SDK management
│   │   ├── setup_wizard.dart          # First-run SDK installation UI
│   │   └── download_manager.dart      # HTTP download with progress
│   │
│   ├── build/                         # Build pipeline
│   │   ├── build_screen.dart          # Full-screen build output viewer
│   │   └── build_runner.dart          # Build orchestration logic
│   │
│   └── lsp/                           # Language server
│       ├── lsp_client.dart            # JSON-RPC 2.0 client
│       └── dart_analysis.dart         # Dart LSP wrapper
│
├── test/                              # Widget tests
│   └── widget_test.dart               # Default counter test
│
├── docs/                              # Documentation
│   ├── todo.md                        # Implementation checklist
│   └── project-arch-tree-view.md      # This file
│
└── android/                           # Android native code
    ├── build.gradle.kts               # Root Gradle config (JitPack repo)
    ├── settings.gradle.kts            # Gradle settings
    ├── gradle.properties              # Gradle JVM args
    ├── gradlew                        # Gradle wrapper (Unix)
    ├── gradlew.bat                    # Gradle wrapper (Windows)
    │
    └── app/
        ├── build.gradle.kts           # App Gradle config (libsu, packaging)
        │
        └── src/
            ├── main/
            │   ├── AndroidManifest.xml           # Permissions + SAF provider
            │   │
            │   ├── kotlin/.../
            │   │   ├── MainActivity.kt           # FlutterActivity + channels
            │   │   └── AndrodartStorageProvider.kt # SAF DocumentsProvider
            │   │
            │   ├── c/
            │   │   └── pty.c                     # Native PTY code
            │   │
            │   ├── cpp/
            │   │   └── CMakeLists.txt            # CMake build config
            │   │
            │   ├── jniLibs/
            │   │   └── arm64-v8a/
            │   │       ├── libproot.so           # proot binary (placeholder)
            │   │       ├── libproot-loader.so    # proot loader (placeholder)
            │   │       ├── libtalloc.so          # proot dependency (placeholder)
            │   │       └── libandroid-shmem.so   # shared memory shim (placeholder)
            │   │
            │   └── assets/
            │       └── rootfs-debian-arm64.tar.gz # Debian bookworm rootfs (placeholder)
            │
            ├── debug/                            # Debug build config
            └── profile/                          # Profile build config
```

---

## Module Dependency Graph

```
main.dart
  ├── core/proot_service.dart
  ├── core/shell_service.dart
  ├── core/file_service.dart
  ├── core/sdk_manager.dart
  ├── core/build_service.dart
  ├── core/storage_service.dart
  ├── ui/theme.dart
  ├── ui/toolbar.dart
  ├── ui/status_bar.dart
  ├── ui/settings_page.dart
  ├── ui/about_page.dart
  ├── editor/editor_tab.dart
  │    └── editor/tab_manager.dart
  ├── terminal/terminal_tab.dart
  │    └── terminal/terminal_session.dart
  ├── file_browser/file_browser_tab.dart
  │    └── file_browser/file_tree.dart
  ├── build/build_screen.dart
  │    └── build/build_runner.dart
  └── lsp/dart_analysis.dart
       └── lsp/lsp_client.dart

core/proot_service.dart
  └── (rootfs extraction, proot execution)

core/shell_service.dart
  ├── core/proot_service.dart
  └── (PTY via MethodChannel)

core/file_service.dart
  └── core/proot_service.dart

core/sdk_manager.dart
  ├── core/proot_service.dart
  ├── core/shell_service.dart
  └── sdk/download_manager.dart

core/build_service.dart
  ├── core/shell_service.dart
  └── core/sdk_manager.dart

core/storage_service.dart
  ├── core/proot_service.dart
  └── core/shell_service.dart

editor/editor_tab.dart
  ├── editor/tab_manager.dart
  └── editor/code_editor.dart

terminal/terminal_tab.dart
  └── terminal/terminal_session.dart

file_browser/file_browser_tab.dart
  └── file_browser/file_tree.dart
       └── file_browser/file_tile.dart
```

---

## Data Flow

### App Launch
```
main.dart
  → MyApp (MaterialApp + theme)
    → AppInit (FutureBuilder)
      → AppServices.create() (initialize all services)
        → MainScreen (tab navigation)
```

### Terminal Command
```
User types command
  → TerminalSession.writeInput()
    → PTY native write(masterFd)
      → proot shell processes command
        → Output streams back via PTY read
          → TerminalWidget renders via xterm
```

### File Open
```
User taps file in FileBrowser
  → FileService.readFile(path)
    → proot shell: cat /home/user/projects/file.dart
      → Contents returned
        → CodeEditor displays with syntax highlighting
```

### Build APK
```
User taps Build button
  → BuildRunner.startBuild(projectPath, mode)
    → Output streams to BuildScreen
      → APK generated at /home/user/projects/.../build/app/outputs/
```

### Storage Setup
```
User runs "setup-storage" in terminal
  → StorageService.setupStorage()
    → Request READ_EXTERNAL_STORAGE permission
    → Create ~/storage/ directory in rootfs
    → Create symlinks:
        shared → /storage/emulated/0
        downloads → /storage/emulated/0/Download
        dcim → /storage/emulated/0/DCIM
        music → /storage/emulated/0/Music
        pictures → /storage/emulated/0/Pictures
        movies → /storage/emulated/0/Movies
```

---

## Key Architectural Decisions

### 1. proot (No Root Required)
- Uses ptrace (unprivileged syscall) for filesystem virtualization
- All tools execute inside proot container
- No root access needed on device

### 2. Debian Bookworm Rootfs
- glibc-based (full Flutter/Dart compatibility)
- ~50MB compressed
- Standard apt package manager

### 3. Flutter 3.44.4 + Dart 3.12.2
- Latest stable release
- Auto-patched for ARM64 execution inside proot

### 4. Native PTY
- POSIX PTY via C FFI (openpty/forkpty)
- Real terminal experience (job control, signals, ncurses)
- xterm for rendering (60fps, themes)

### 5. Dual-Mode File Access
- SAF for user-selected directories (non-root)
- Direct filesystem for rootfs
- Hybrid file browser

### 6. SAF Document Provider
- Exposes rootfs to external file managers
- Material Files, FX, Solid Explorer compatible

---

## Technology Stack

| Layer | Technology |
|-------|-----------|
| UI Framework | Flutter 3.44.4 |
| Language | Dart 3.12.2 |
| Code Editor | re_editor 0.10.0 |
| Terminal | xterm 4.0.0 |
| State Management | Provider 6.1.5 |
| HTTP | http 1.6.0 |
| Archive | archive 4.0.9 |
| Permissions | permission_handler 12.0.3 |
| SAF | saf 1.0.4 |
| File Access | path_provider 2.1.6 |
| Native Bridge | MethodChannel + EventChannel |
| PTY | POSIX PTY (C code) |
| Container | proot 5.4.0 |
| Rootfs | Debian bookworm ARM64 |
| JDK | OpenJDK 17 (Temurin) |
| Flutter SDK | 3.44.4 (stable) |
| Android SDK | cmdline-tools + build-tools 35.0.1 |
| Build Tools | aapt2, aidl, zipalign (ARM64) |
| Version Control | Git 2.39+ |

---

## On-Device Paths

| Path | Purpose |
|------|---------|
| `/data/data/.../files/rootfs/` | Debian rootfs |
| `/data/data/.../files/rootfs/home/user/` | User home |
| `/data/data/.../files/rootfs/home/user/flutter/` | Flutter SDK |
| `/data/data/.../files/rootfs/home/user/android-sdk/` | Android SDK |
| `/data/data/.../files/rootfs/home/user/projects/` | User projects |
| `/data/data/.../files/rootfs/home/user/storage/` | Symlinks to shared storage |
| `/data/data/.../lib/arm64/` | nativeLibraryDir (proot binaries) |
| `/data/data/.../cache/` | App cache |

---

## External Resources

| Resource | URL |
|----------|-----|
| Flutter SDK | `https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.44.4-stable.tar.xz` |
| Android SDK CLI | `https://dl.google.com/android/repository/commandlinetools-linux-*.zip` |
| aapt2 ARM64 | `https://github.com/lzhiyong/android-sdk-tools/releases` |
| Debian rootfs | `https://cdimage.debian.org/debian-cd/current/arm64/iso-cd/` |
| proot | `https://github.com/proot-me/proot` |
| re_editor | `https://pub.dev/packages/re_editor` |
| xterm | `https://pub.dev/packages/xterm` |
| saf | `https://pub.dev/packages/saf` |
