import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

class CodeEditorWidget extends StatefulWidget {
  final String content;
  final String language;
  final bool readOnly;
  final Function(String)? onChanged;

  const CodeEditorWidget({
    super.key,
    required this.content,
    this.language = 'dart',
    this.readOnly = false,
    this.onChanged,
  });

  @override
  State<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends State<CodeEditorWidget> {
  late CodeLineEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CodeLineEditingController.fromText(widget.content);
  }

  @override
  void didUpdateWidget(CodeEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _controller.text = widget.content;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CodeEditor(
      controller: _controller,
      readOnly: widget.readOnly,
      indicatorBuilder: (context, editingController, chunkController, notifier) {
        return Row(
          children: [
            DefaultCodeLineNumber(
              controller: editingController,
              notifier: notifier,
            ),
            DefaultCodeChunkIndicator(
              width: 20,
              controller: chunkController,
              notifier: notifier,
            ),
          ],
        );
      },
      chunkAnalyzer: const DefaultCodeChunkAnalyzer(),
    );
  }
}
