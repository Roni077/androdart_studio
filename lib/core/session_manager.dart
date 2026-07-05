import 'dart:async';
import 'package:flutter/services.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._();
  factory SessionManager() => _instance;
  SessionManager._();

  final Map<int, StreamController<String>> _outputControllers = {};
  final Map<int, StreamController<int>> _exitControllers = {};
  MethodChannel? _outputChannel;
  MethodChannel? _exitChannel;
  bool _initialized = false;

  void initialize(MethodChannel outputChannel, MethodChannel exitChannel) {
    if (_initialized) return;
    _initialized = true;
    _outputChannel = outputChannel;
    _exitChannel = exitChannel;
    _outputChannel!.setMethodCallHandler(_handleOutput);
    _exitChannel!.setMethodCallHandler(_handleExit);
  }

  int register() {
    final sessionId = DateTime.now().microsecondsSinceEpoch;
    _outputControllers[sessionId] = StreamController<String>.broadcast();
    _exitControllers[sessionId] = StreamController<int>.broadcast();
    return sessionId;
  }

  void unregister(int sessionId) {
    _outputControllers.remove(sessionId)?.close();
    _exitControllers.remove(sessionId)?.close();
  }

  Stream<String>? outputStream(int sessionId) => _outputControllers[sessionId]?.stream;
  Stream<int>? exitStream(int sessionId) => _exitControllers[sessionId]?.stream;

  Future<dynamic> _handleOutput(MethodCall call) async {
    if (call.method == 'onOutput') {
      final args = call.arguments as Map<dynamic, dynamic>;
      final sessionId = args['sessionId'] as int;
      final data = args['data'] as String;
      _outputControllers[sessionId]?.add(data);
    }
  }

  Future<dynamic> _handleExit(MethodCall call) async {
    if (call.method == 'onExit') {
      final args = call.arguments as Map<dynamic, dynamic>;
      final sessionId = args['sessionId'] as int;
      final code = args['code'] as int;
      _exitControllers[sessionId]?.add(code);
    }
  }
}
