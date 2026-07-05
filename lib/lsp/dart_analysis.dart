import 'dart:async';
import 'lsp_client.dart';

class Diagnostic {
  final int line;
  final int column;
  final int endLine;
  final int endColumn;
  final String message;
  final int severity;
  final String? code;

  const Diagnostic({
    required this.line,
    required this.column,
    required this.endLine,
    required this.endColumn,
    required this.message,
    required this.severity,
    this.code,
  });

  bool get isError => severity == 1;
  bool get isWarning => severity == 2;
  bool get isInfo => severity == 3;
  bool get isHint => severity == 4;
}

class DartAnalysis {
  final LspClient _client;

  final StreamController<List<Diagnostic>> _diagnosticsController =
      StreamController<List<Diagnostic>>.broadcast();

  Stream<List<Diagnostic>> get diagnostics => _diagnosticsController.stream;

  DartAnalysis({required LspClient client}) : _client = client;

  bool get isRunning => _client.isRunning;

  Future<void> start() async {
    await _client.start();
  }

  Future<void> openFile(String path, String content) async {}
  Future<void> updateFile(String path, String content, int version) async {}
  Future<void> closeFile(String path) async {}

  Future<void> stop() async {
    await _client.stop();
  }

  void dispose() {
    _diagnosticsController.close();
  }
}
