import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/proot_service.dart';
import 'core/shell_service.dart';
import 'core/file_service.dart';
import 'core/sdk_manager.dart';
import 'core/build_service.dart';
import 'core/storage_service.dart';
import 'core/settings_service.dart';
import 'ui/theme.dart';
import 'ui/toolbar.dart';
import 'ui/status_bar.dart';
import 'editor/editor_tab.dart';
import 'editor/tab_manager.dart';
import 'terminal/terminal_session.dart';
import 'terminal/terminal_tab.dart';
import 'file_browser/file_browser_tab.dart';
import 'build/build_runner.dart';
import 'build/build_screen.dart';
import 'ui/settings_page.dart';
import 'sdk/setup_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class AppServices {
  final ProotService proot;
  final ShellService shell;
  final FileService fileService;
  final SdkManager sdkManager;
  final BuildService buildService;
  final StorageService storageService;
  final SettingsService settingsService;

  AppServices({
    required this.proot,
    required this.shell,
    required this.fileService,
    required this.sdkManager,
    required this.buildService,
    required this.storageService,
    required this.settingsService,
  });

  static Future<AppServices> create() async {
    const prootChannel = MethodChannel(
      'com.androdartstudio.flutteride.androdart_studio/proot',
    );
    const ptyChannel = MethodChannel(
      'com.androdartstudio.flutteride.androdart_studio/pty',
    );
    const ptyOutputChannel = MethodChannel(
      'com.androdartstudio.flutteride.androdart_studio/pty_output',
    );
    const ptyExitChannel = MethodChannel(
      'com.androdartstudio.flutteride.androdart_studio/pty_exit',
    );

    final nativeLibDir =
        await prootChannel.invokeMethod<String>('getNativeLibDir') ?? '';
    final filesDir =
        await prootChannel.invokeMethod<String>('getFilesDir') ?? '';

    final proot = ProotService(
      channel: prootChannel,
      nativeLibDir: nativeLibDir,
      filesDir: filesDir,
    );

    final shell = ShellService(
      proot: proot,
      ptyChannel: ptyChannel,
      outputChannel: ptyOutputChannel,
      exitChannel: ptyExitChannel,
    );
    final fileService = FileService(proot: proot);
    final sdkManager = SdkManager(proot: proot, shell: shell);
    final buildService = BuildService(
      proot: proot,
      shell: shell,
      ptyChannel: ptyChannel,
    );
    final storageService = StorageService(proot: proot, shell: shell);
    final settingsService = SettingsService();
    await settingsService.init();

    return AppServices(
      proot: proot,
      shell: shell,
      fileService: fileService,
      sdkManager: sdkManager,
      buildService: buildService,
      storageService: storageService,
      settingsService: settingsService,
    );
  }

  void dispose() {
    shell.dispose();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'androdart_studio',
      debugShowCheckedModeBanner: false,
      theme: AndrodartTheme.darkTheme,
      home: const AppInit(),
    );
  }
}

class AppInit extends StatefulWidget {
  const AppInit({super.key});

  @override
  State<AppInit> createState() => _AppInitState();
}

class _AppInitState extends State<AppInit> {
  late Future<AppServices> _servicesFuture;

  @override
  void initState() {
    super.initState();
    _servicesFuture = AppServices.create();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppServices>(
      future: _servicesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing services...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Failed to initialize: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _servicesFuture = AppServices.create();
                    }),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final services = snapshot.data!;
        
        return FutureBuilder<bool>(
          future: services.sdkManager.isSetupComplete(),
          builder: (context, setupSnapshot) {
            if (setupSnapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Checking setup...'),
                    ],
                  ),
                ),
              );
            }

            final isSetupComplete = setupSnapshot.data ?? false;

            if (!isSetupComplete) {
              return SetupScreen(
                shell: services.shell,
                proot: services.proot,
                onComplete: () {
                  setState(() {});
                },
              );
            }

            return MainScreen(services: services);
          },
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  final AppServices services;

  const MainScreen({super.key, required this.services});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _isRunning = false;
  final TabManager _tabManager = TabManager();
  final List<TerminalSession> _terminalSessions = [];
  int _selectedTerminalIndex = -1;
  late final BuildRunner _buildRunner;
  StreamSubscription<BuildStatus>? _buildStatusSub;

  @override
  void initState() {
    super.initState();
    _buildRunner = BuildRunner(
      shell: widget.services.shell,
      buildService: widget.services.buildService,
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _buildStatusSub?.cancel();
    _buildRunner.dispose();
    for (final session in _terminalSessions) {
      session.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // App went to background
        break;
      case AppLifecycleState.resumed:
        // App came back to foreground
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _onAction(ActionType action) {
    switch (action) {
      case ActionType.run:
        setState(() => _isRunning = true);
        // TODO: Implement run
        break;
      case ActionType.build:
        _startBuild();
        break;
      case ActionType.saveFile:
        // TODO: Implement save
        break;
      case ActionType.openFile:
        // TODO: Implement file picker
        break;
      case ActionType.settings:
        _openSettings();
        break;
      default:
        break;
    }
  }

  void _startBuild() {
    final projectPath = _tabManager.currentProjectPath;
    if (projectPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No project open. Open a Dart file first.')),
      );
      return;
    }

    setState(() => _isRunning = true);

    _buildStatusSub?.cancel();
    _buildStatusSub = _buildRunner.status.listen((status) {
      setState(() {
        _isRunning = status == BuildStatus.running;
      });
    });

    _buildRunner.startBuild(
      projectPath: projectPath,
      projectName: projectPath.split(Platform.pathSeparator).last,
      isDebug: true,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BuildScreen(buildRunner: _buildRunner),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsPage(
          settings: widget.services.settingsService,
        ),
      ),
    );
  }

  void _openFileInEditor(String path) {
    final file = File(path);
    if (!file.existsSync()) return;

    String content;
    try {
      content = file.readAsStringSync();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to read file: $e')),
      );
      return;
    }

    final name = path.split(Platform.pathSeparator).last;
    final language = _tabManager.getLanguage(path);

    _tabManager.openFile(OpenFile(
      path: path,
      name: name,
      content: content,
      language: language,
    ));

    setState(() => _selectedIndex = 0);
  }

  void _newTerminalSession() {
    final session = TerminalSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      ptyChannel: const MethodChannel(
        'com.androdartstudio.flutteride.androdart_studio/pty',
      ),
      outputChannel: const MethodChannel(
        'com.androdartstudio.flutteride.androdart_studio/pty_output',
      ),
      exitChannel: const MethodChannel(
        'com.androdartstudio.flutteride.androdart_studio/pty_exit',
      ),
    );
    setState(() {
      _terminalSessions.add(session);
      _selectedTerminalIndex = _terminalSessions.length - 1;
    });
    session.start();
  }

  void _closeTerminalSession(int index) {
    if (index >= 0 && index < _terminalSessions.length) {
      _terminalSessions[index].dispose();
      setState(() {
        _terminalSessions.removeAt(index);
        if (_selectedTerminalIndex >= _terminalSessions.length) {
          _selectedTerminalIndex = _terminalSessions.length - 1;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Toolbar(
            actions: [
              ActionType.newFile,
              ActionType.openFile,
              ActionType.saveFile,
              ActionType.run,
              ActionType.build,
              ActionType.terminal,
              ActionType.settings,
            ],
            onAction: _onAction,
            isRunning: _isRunning,
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                EditorTab(tabManager: _tabManager),
                TerminalTab(
                  sessions: _terminalSessions,
                  selectedIndex: _selectedTerminalIndex,
                  onSessionSelected: (index) {
                    setState(() => _selectedTerminalIndex = index);
                  },
                  onNewSession: _newTerminalSession,
                  onCloseSession: _closeTerminalSession,
                ),
                FileBrowserTab(
                  rootPath: '/storage/emulated/0',
                  onFileOpen: (path) {
                    _openFileInEditor(path);
                  },
                ),
              ],
            ),
          ),
          StatusBar(
            sdkReady: false,
            line: 1,
            column: 1,
            encoding: 'UTF-8',
            language: _tabManager.currentFile?.language ?? 'Dart',
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.code),
            selectedIcon: Icon(Icons.code, color: AndrodartTheme.primaryColor),
            label: 'Editor',
          ),
          NavigationDestination(
            icon: Icon(Icons.terminal),
            selectedIcon:
                Icon(Icons.terminal, color: AndrodartTheme.primaryColor),
            label: 'Terminal',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder),
            selectedIcon:
                Icon(Icons.folder, color: AndrodartTheme.primaryColor),
            label: 'Files',
          ),
        ],
      ),
    );
  }
}
