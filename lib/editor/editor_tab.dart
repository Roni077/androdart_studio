import 'package:flutter/material.dart';
import '../ui/theme.dart';
import 'tab_manager.dart';
import 'code_editor.dart';

class EditorTab extends StatefulWidget {
  final TabManager tabManager;
  final Function(String path)? onFileOpen;

  const EditorTab({
    super.key,
    required this.tabManager,
    this.onFileOpen,
  });

  @override
  State<EditorTab> createState() => _EditorTabState();
}

class _EditorTabState extends State<EditorTab> {
  @override
  void initState() {
    super.initState();
    widget.tabManager.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    widget.tabManager.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.tabManager.tabs.isNotEmpty) _buildTabBar(),
        Expanded(
          child: widget.tabManager.currentFile != null
              ? _buildEditor()
              : _buildEmptyState(),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 36,
      decoration: const BoxDecoration(
        color: AndrodartTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.tabManager.tabs.length,
        itemBuilder: (context, index) {
          final file = widget.tabManager.tabs[index];
          final isSelected = index == widget.tabManager.selectedIndex;

          return GestureDetector(
            onTap: () => widget.tabManager.selectTab(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AndrodartTheme.backgroundColor
                    : Colors.transparent,
                border: Border(
                  right: BorderSide(color: Colors.grey[800]!, width: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getFileIcon(file.language),
                    size: 14,
                    color: isSelected
                        ? AndrodartTheme.primaryColor
                        : AndrodartTheme.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    file.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? AndrodartTheme.textPrimary
                          : AndrodartTheme.textSecondary,
                    ),
                  ),
                  if (file.isModified) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AndrodartTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => widget.tabManager.closeFile(index),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: AndrodartTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEditor() {
    final file = widget.tabManager.currentFile!;

    return CodeEditorWidget(
      content: file.content,
      language: file.language,
      onChanged: (content) {
        widget.tabManager.updateContent(content);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.code,
            size: 64,
            color: AndrodartTheme.textMuted,
          ),
          const SizedBox(height: 16),
          const Text(
            'No file open',
            style: TextStyle(
              fontSize: 16,
              color: AndrodartTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Open a file from the file browser to start editing',
            style: TextStyle(
              fontSize: 14,
              color: AndrodartTheme.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Open file picker
            },
            icon: const Icon(Icons.folder_open),
            label: const Text('Open File'),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String language) {
    return switch (language) {
      'dart' => Icons.code,
      'yaml' || 'yml' => Icons.settings,
      'json' => Icons.data_object,
      'xml' => Icons.code,
      'html' => Icons.language,
      'css' => Icons.palette,
      'javascript' => Icons.javascript,
      'kotlin' => Icons.code,
      'java' => Icons.coffee,
      'gradle' => Icons.build,
      _ => Icons.description,
    };
  }
}
