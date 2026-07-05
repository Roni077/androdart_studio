import 'dart:async';
import '../core/build_service.dart';
import '../core/shell_service.dart';

enum BuildStatus {
  idle,
  running,
  success,
  failed,
}

class BuildInfo {
  final String projectPath;
  final String projectName;
  final bool isDebug;
  final DateTime startTime;

  const BuildInfo({
    required this.projectPath,
    required this.projectName,
    this.isDebug = true,
    required this.startTime,
  });
}

class BuildRunner {
  final ShellService _shell;
  final BuildService _buildService;
  final List<String> _outputBuffer = [];
  BuildStatus _status = BuildStatus.idle;
  BuildInfo? _currentBuild;
  StreamSubscription<String>? _outputSub;
  StreamSubscription<int>? _exitSub;

  final StreamController<String> _outputController =
      StreamController<String>.broadcast();
  final StreamController<BuildStatus> _statusController =
      StreamController<BuildStatus>.broadcast();

  BuildRunner({
    required ShellService shell,
    required BuildService buildService,
  })  : _shell = shell,
        _buildService = buildService;

  Stream<String> get output => _outputController.stream;
  Stream<BuildStatus> get status => _statusController.stream;
  BuildStatus get currentStatus => _status;
  BuildInfo? get currentBuild => _currentBuild;
  List<String> get outputBuffer => List.unmodifiable(_outputBuffer);

  Future<void> startBuild({
    required String projectPath,
    required String projectName,
    bool isDebug = true,
  }) async {
    if (_status == BuildStatus.running) {
      throw StateError('Build already in progress');
    }

    _currentBuild = BuildInfo(
      projectPath: projectPath,
      projectName: projectName,
      isDebug: isDebug,
      startTime: DateTime.now(),
    );

    _status = BuildStatus.running;
    _outputBuffer.clear();
    _statusController.add(_status);

    _outputSub = _shell.output.listen(
      (data) {
        addOutput(data);
      },
    );

    _exitSub = _shell.onExit.listen((code) {
      if (_status == BuildStatus.running) {
        _status = code == 0 ? BuildStatus.success : BuildStatus.failed;
        _statusController.add(_status);
        addOutput(
          code == 0
              ? 'Build completed successfully'
              : 'Build failed with exit code $code',
        );
      }
      _cleanup();
    });

    if (!_shell.isRunning) {
      await _shell.startShell();
    }

    final mode = isDebug ? BuildMode.debug : BuildMode.release;
    await _buildService.flutterBuild(projectPath: projectPath, mode: mode);
  }

  void addOutput(String message) {
    final lines = message.split('\n');
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      final timestamp = DateTime.now().toString().substring(11, 19);
      final formattedMessage = '[$timestamp] $line';
      _outputBuffer.add(formattedMessage);
      _outputController.add(formattedMessage);
    }
  }

  void cancelBuild() {
    _shell.close();
    _status = BuildStatus.failed;
    _statusController.add(_status);
    addOutput('Build cancelled by user');
    _cleanup();
  }

  void clearOutput() {
    _outputBuffer.clear();
  }

  String getApkPath() {
    if (_currentBuild == null) return '';
    final mode = _currentBuild!.isDebug ? 'debug' : 'release';
    return '${_currentBuild!.projectPath}/build/app/outputs/flutter-apk/app-$mode.apk';
  }

  Duration get buildDuration {
    if (_currentBuild == null) return Duration.zero;
    return DateTime.now().difference(_currentBuild!.startTime);
  }

  void _cleanup() {
    _outputSub?.cancel();
    _exitSub?.cancel();
  }

  void dispose() {
    _cleanup();
    _outputController.close();
    _statusController.close();
  }
}
