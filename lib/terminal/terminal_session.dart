import 'dart:async';
import 'package:flutter/services.dart';
import '../core/proot_service.dart';
import '../core/session_manager.dart';

class TerminalSession {
  final String id;
  final ProotService _proot;
  final MethodChannel _ptyChannel;
  final SessionManager _sessions = SessionManager();
  int? _sessionId;
  bool _isRunning = false;
  StreamSubscription<String>? _outputSub;
  StreamSubscription<int>? _exitSub;

  final StreamController<String> _outputController =
      StreamController<String>.broadcast();
  final StreamController<void> _exitController =
      StreamController<void>.broadcast();

  TerminalSession({
    required this.id,
    required ProotService proot,
    required MethodChannel ptyChannel,
    required MethodChannel outputChannel,
    required MethodChannel exitChannel,
  })  : _proot = proot,
        _ptyChannel = ptyChannel {
    _sessions.initialize(outputChannel, exitChannel);
  }

  Stream<String> get output => _outputController.stream;
  Stream<void> get onExit => _exitController.stream;
  bool get isRunning => _isRunning;
  int? get sessionId => _sessionId;

  Future<void> start({
    Map<String, String> env = const {},
    String? workingDir,
  }) async {
    if (_isRunning) {
      throw StateError('Session already running');
    }

    _sessionId = _sessions.register();
    final sid = _sessionId!;
    _outputSub = _sessions.outputStream(sid)?.listen((data) {
      if (_isRunning) _outputController.add(data);
    });
    _exitSub = _sessions.exitStream(sid)?.listen((code) {
      _isRunning = false;
      _exitController.add(null);
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

    _sessionId = result as int;
    _isRunning = true;
  }

  Future<void> write(String input) async {
    if (!_isRunning || _sessionId == null) {
      throw StateError('Session not running');
    }
    await _ptyChannel.invokeMethod('write', {
      'sessionId': _sessionId,
      'input': input,
    });
  }

  Future<void> resize(int cols, int rows) async {
    if (!_isRunning || _sessionId == null) return;
    await _ptyChannel.invokeMethod('resize', {
      'sessionId': _sessionId,
      'cols': cols,
      'rows': rows,
    });
  }

  Future<void> close() async {
    if (!_isRunning || _sessionId == null) return;
    await _ptyChannel.invokeMethod('close', {
      'sessionId': _sessionId,
    });
    _isRunning = false;
    _cleanup();
  }

  void _cleanup() {
    _outputSub?.cancel();
    _exitSub?.cancel();
    if (_sessionId != null) {
      _sessions.unregister(_sessionId!);
      _sessionId = null;
    }
  }

  void dispose() {
    close();
    _outputController.close();
    _exitController.close();
  }
}
