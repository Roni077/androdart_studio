import 'dart:async';
import 'package:flutter/services.dart';
import 'proot_service.dart';
import 'session_manager.dart';

class ShellService {
  final ProotService _proot;
  final MethodChannel _ptyChannel;
  final SessionManager _sessions = SessionManager();
  int? _currentSessionId;
  StreamSubscription<String>? _outputSub;
  StreamSubscription<int>? _exitSub;

  final StreamController<String> _outputController =
      StreamController<String>.broadcast();
  final StreamController<int> _exitController =
      StreamController<int>.broadcast();

  ShellService({
    required ProotService proot,
    required MethodChannel ptyChannel,
    required MethodChannel outputChannel,
    required MethodChannel exitChannel,
  })  : _proot = proot,
        _ptyChannel = ptyChannel {
    _sessions.initialize(outputChannel, exitChannel);
  }

  Stream<String> get output => _outputController.stream;
  Stream<int> get onExit => _exitController.stream;
  bool get isRunning => _currentSessionId != null;

  Future<int> startShell({
    Map<String, String> env = const {},
    String? workingDir,
  }) async {
    if (_currentSessionId != null) {
      throw StateError('Shell already running');
    }

    final sessionId = _sessions.register();
    _outputSub = _sessions.outputStream(sessionId)?.listen(_outputController.add);
    _exitSub = _sessions.exitStream(sessionId)?.listen((code) {
      _exitController.add(code);
      _currentSessionId = null;
      _cleanup();
    });

    final defaultEnv = {
      'HOME': '/root',
      'PATH':
          '/usr/local/bin:/usr/bin:/bin:/root/flutter/bin:/root/android-sdk/cmdline-tools/latest/bin',
      'TERM': 'xterm-256color',
      'LANG': 'en_US.UTF-8',
      'TMPDIR': '/tmp',
    };
    final mergedEnv = {...defaultEnv, ...env};

    final prootCmd = _proot.buildProotCommand(
      command: 'exec /bin/sh --login',
      env: mergedEnv,
      workingDir: workingDir ?? _proot.rootfsHome,
    );

    final result = await _ptyChannel.invokeMethod('create', {
      'command': prootCmd.first,
      'args': prootCmd.sublist(1),
      'envVars': mergedEnv.entries.expand((e) => [e.key, e.value]).toList(),
      'workingDir': workingDir ?? _proot.rootfsHome,
    });

    _currentSessionId = result as int;
    return _currentSessionId!;
  }

  Future<void> run(String command) async {
    if (_currentSessionId == null) {
      await startShell();
    }
    await writeInput('$command\n');
  }

  Future<void> writeInput(String input) async {
    if (_currentSessionId == null) {
      throw StateError('No shell running');
    }
    await _ptyChannel.invokeMethod('write', {
      'sessionId': _currentSessionId,
      'input': input,
    });
  }

  Future<void> resize(int cols, int rows) async {
    if (_currentSessionId == null) return;
    await _ptyChannel.invokeMethod('resize', {
      'sessionId': _currentSessionId,
      'cols': cols,
      'rows': rows,
    });
  }

  Future<void> close() async {
    if (_currentSessionId == null) return;
    await _ptyChannel.invokeMethod('close', {
      'sessionId': _currentSessionId,
    });
    _currentSessionId = null;
    _cleanup();
  }

  void _cleanup() {
    _outputSub?.cancel();
    _exitSub?.cancel();
    if (_currentSessionId != null) {
      _sessions.unregister(_currentSessionId!);
    }
  }

  void dispose() {
    close();
    _outputController.close();
    _exitController.close();
  }
}
