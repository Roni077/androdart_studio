import 'dart:async';
import '../core/proot_service.dart';
import '../core/shell_service.dart';

class LspClient {
  LspClient({
    required ProotService proot,
    required ShellService shell,
  });

  bool get isRunning => false;

  Future<void> start() async {}

  Future<void> stop() async {}
  void dispose() {}
}
