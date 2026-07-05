import 'dart:io';
import 'package:flutter/material.dart';
import '../ui/theme.dart';
import 'file_tree.dart';

class FileBrowserTab extends StatefulWidget {
  final String rootPath;
  final Function(String path)? onFileOpen;

  const FileBrowserTab({
    super.key,
    required this.rootPath,
    this.onFileOpen,
  });

  @override
  State<FileBrowserTab> createState() => _FileBrowserTabState();
}

class _FileBrowserTabState extends State<FileBrowserTab> {
  late String _currentPath;
  final List<String> _pathHistory = [];

  @override
  void initState() {
    super.initState();
    _currentPath = widget.rootPath;
  }

  @override
  void didUpdateWidget(FileBrowserTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rootPath != widget.rootPath) {
      setState(() {
        _currentPath = widget.rootPath;
        _pathHistory.clear();
      });
    }
  }

  void _navigateTo(String path) {
    final dir = Directory(path);
    if (dir.existsSync()) {
      setState(() {
        _pathHistory.add(_currentPath);
        _currentPath = path;
      });
    }
  }

  void _goBack() {
    if (_pathHistory.isNotEmpty) {
      setState(() {
        _currentPath = _pathHistory.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: FileTree(
            rootPath: _currentPath,
            onFileTap: (path) {
              final file = File(path);
              if (file.existsSync()) {
                widget.onFileOpen?.call(path);
              } else {
                _navigateTo(path);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AndrodartTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          if (_pathHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 18),
              onPressed: _goBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentPath.split(Platform.pathSeparator).last,
                  style: const TextStyle(
                    color: AndrodartTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _currentPath,
                  style: const TextStyle(
                    color: AndrodartTheme.textMuted,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            onPressed: () {
              setState(() {});
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    );
  }
}
