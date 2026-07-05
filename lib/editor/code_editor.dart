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
  bool _isUpdatingFromParent = false;

  @override
  void initState() {
    super.initState();
    _controller = CodeLineEditingController.fromText(widget.content);
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(CodeEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _isUpdatingFromParent = true;
      _controller.text = widget.content;
      _isUpdatingFromParent = false;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_isUpdatingFromParent) return;
    widget.onChanged?.call(_controller.text);
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
