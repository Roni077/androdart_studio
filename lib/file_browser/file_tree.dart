import 'dart:io';
import 'package:flutter/material.dart';
import 'file_tile.dart';

class FileNode {
  final String name;
  final String path;
  final bool isDirectory;
  List<FileNode> children;
  bool isExpanded;
  bool isLoaded;

  FileNode({
    required this.name,
    required this.path,
    this.isDirectory = false,
    this.children = const [],
    this.isExpanded = false,
    this.isLoaded = false,
  });
}

class FileTree extends StatefulWidget {
  final String rootPath;
  final Function(String path)? onFileTap;
  final Function(String path)? onFileLongPress;

  const FileTree({
    super.key,
    required this.rootPath,
    this.onFileTap,
    this.onFileLongPress,
  });

  @override
  State<FileTree> createState() => _FileTreeState();
}

class _FileTreeState extends State<FileTree> {
  FileNode? _rootNode;

  static const _skipDirs = {
    '.git',
    '.dart_tool',
    'build',
    '.gradle',
    '.idea',
    '.vscode',
    'node_modules',
    '.pub-cache',
    '.pub',
  };

  static const _skipFiles = {
    '.DS_Store',
    'Thumbs.db',
    '.metadata',
    'pubspec.lock',
  };

  @override
  void initState() {
    super.initState();
    _loadRoot();
  }

  @override
  void didUpdateWidget(FileTree oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rootPath != widget.rootPath) {
      _loadRoot();
    }
  }

  void _loadRoot() {
    final rootDir = Directory(widget.rootPath);
    if (!rootDir.existsSync()) {
      setState(() {
        _rootNode = null;
      });
      return;
    }

    setState(() {
      _rootNode = FileNode(
        name: widget.rootPath.split(Platform.pathSeparator).last,
        path: widget.rootPath,
        isDirectory: true,
        isExpanded: true,
        isLoaded: true,
      );
      _loadChildren(_rootNode!);
    });
  }

  void _loadChildren(FileNode node) {
    if (!node.isDirectory) return;

    final dir = Directory(node.path);
    List<FileSystemEntity> entries;
    try {
      entries = dir.listSync();
    } catch (_) {
      return;
    }

    entries.sort((a, b) {
      final aIsDir = a is Directory;
      final bIsDir = b is Directory;
      if (aIsDir && !bIsDir) return -1;
      if (!aIsDir && bIsDir) return 1;
      return a.path.compareTo(b.path);
    });

    node.children = entries.map((entry) {
      final name = entry.path.split(Platform.pathSeparator).last;

      if (name.startsWith('.') && name != '.') {
        return null;
      }
      if (_skipDirs.contains(name)) {
        return null;
      }
      if (entry is! Directory && _skipFiles.contains(name)) {
        return null;
      }

      return FileNode(
        name: name,
        path: entry.path,
        isDirectory: entry is Directory,
      );
    }).whereType<FileNode>().toList();
  }

  void _toggleExpanded(FileNode node) {
    if (!node.isDirectory) return;

    setState(() {
      node.isExpanded = !node.isExpanded;
      if (node.isExpanded && !node.isLoaded) {
        _loadChildren(node);
        node.isLoaded = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_rootNode == null) {
      return const Center(
        child: Text(
          'No project loaded',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: _buildNodes(_rootNode!, 0),
    );
  }

  List<Widget> _buildNodes(FileNode node, int depth) {
    final widgets = <Widget>[];

    widgets.add(
      FileTile(
        name: node.name,
        path: node.path,
        isDirectory: node.isDirectory,
        isExpanded: node.isExpanded,
        depth: depth,
        onTap: () {
          if (node.isDirectory) {
            _toggleExpanded(node);
          } else {
            widget.onFileTap?.call(node.path);
          }
        },
        onLongPress: () {
          widget.onFileLongPress?.call(node.path);
        },
      ),
    );

    if (node.isExpanded && node.isDirectory) {
      for (final child in node.children) {
        widgets.addAll(_buildNodes(child, depth + 1));
      }
    }

    return widgets;
  }
}
