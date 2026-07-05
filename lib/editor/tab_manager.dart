import 'dart:io';
import 'package:flutter/material.dart';

class OpenFile {
  final String path;
  final String name;
  final String content;
  final bool isModified;
  final String language;

  const OpenFile({
    required this.path,
    required this.name,
    required this.content,
    this.isModified = false,
    this.language = 'dart',
  });

  OpenFile copyWith({
    String? content,
    bool? isModified,
  }) {
    return OpenFile(
      path: path,
      name: name,
      content: content ?? this.content,
      isModified: isModified ?? this.isModified,
      language: language,
    );
  }
}

class TabManager extends ChangeNotifier {
  final List<OpenFile> _tabs = [];
  int _selectedIndex = -1;
  String? _currentProjectPath;

  List<OpenFile> get tabs => List.unmodifiable(_tabs);
  int get selectedIndex => _selectedIndex;
  String? get currentProjectPath => _currentProjectPath;

  OpenFile? get currentFile =>
      _selectedIndex >= 0 && _selectedIndex < _tabs.length
          ? _tabs[_selectedIndex]
          : null;

  void openFile(OpenFile file) {
    final existingIndex = _tabs.indexWhere((t) => t.path == file.path);
    if (existingIndex >= 0) {
      _selectedIndex = existingIndex;
    } else {
      _tabs.add(file);
      _selectedIndex = _tabs.length - 1;
    }
    _currentProjectPath = _findProjectRoot(file.path);
    notifyListeners();
  }

  void closeFile(int index) {
    if (index < 0 || index >= _tabs.length) return;

    _tabs.removeAt(index);

    if (_tabs.isEmpty) {
      _selectedIndex = -1;
      _currentProjectPath = null;
    } else if (_selectedIndex >= _tabs.length) {
      _selectedIndex = _tabs.length - 1;
      _currentProjectPath = _findProjectRoot(_tabs[_selectedIndex].path);
    } else if (_selectedIndex > index) {
      _selectedIndex--;
    }

    notifyListeners();
  }

  void closeCurrentFile() {
    if (_selectedIndex >= 0) {
      closeFile(_selectedIndex);
    }
  }

  void selectTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      _selectedIndex = index;
      _currentProjectPath = _findProjectRoot(_tabs[index].path);
      notifyListeners();
    }
  }

  void updateContent(String content) {
    if (_selectedIndex < 0 || _selectedIndex >= _tabs.length) return;

    _tabs[_selectedIndex] = _tabs[_selectedIndex].copyWith(
      content: content,
      isModified: true,
    );
    notifyListeners();
  }

  void markSaved(int index) {
    if (index < 0 || index >= _tabs.length) return;

    _tabs[index] = _tabs[index].copyWith(isModified: false);
    notifyListeners();
  }

  bool hasUnsavedChanges() {
    return _tabs.any((tab) => tab.isModified);
  }

  String getLanguage(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'dart' => 'dart',
      'yaml' || 'yml' => 'yaml',
      'json' => 'json',
      'xml' => 'xml',
      'html' => 'html',
      'css' => 'css',
      'js' => 'javascript',
      'kt' => 'kotlin',
      'java' => 'java',
      'gradle' => 'gradle',
      'md' => 'markdown',
      'txt' => 'plaintext',
      _ => 'plaintext',
    };
  }

  String? _findProjectRoot(String filePath) {
    var dir = File(filePath).parent;
    final visited = <String>{};

    while (true) {
      final path = dir.path;
      if (visited.contains(path)) break;
      visited.add(path);

      final pubspec = File('${dir.path}${Platform.pathSeparator}pubspec.yaml');
      if (pubspec.existsSync()) {
        return dir.path;
      }

      final parent = dir.parent;
      if (parent.path == path) break;
      dir = parent;
    }

    return null;
  }
}
