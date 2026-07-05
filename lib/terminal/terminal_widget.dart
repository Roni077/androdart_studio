import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';
import 'terminal_session.dart';

class TerminalWidget extends StatefulWidget {
  final TerminalSession session;

  const TerminalWidget({
    super.key,
    required this.session,
  });

  @override
  State<TerminalWidget> createState() => _TerminalWidgetState();
}

class _TerminalWidgetState extends State<TerminalWidget> {
  late Terminal _terminal;

  @override
  void initState() {
    super.initState();
    _terminal = Terminal();

    _terminal.onOutput = (output) {
      widget.session.write(output);
    };

    widget.session.output.listen((data) {
      _terminal.write(data);
    });

    widget.session.onExit.listen((_) {
      _terminal.write('\r\n[Process exited]\r\n');
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TerminalView(
      _terminal,
      padding: const EdgeInsets.all(8),
    );
  }
}
