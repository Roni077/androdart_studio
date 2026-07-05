import 'dart:async';
import 'dart:io';
import 'proot_service.dart';

class FileService {
  final ProotService _proot;
  bool _useSaf = false;

  FileService({required ProotService proot}) : _proot = proot;

  bool get useSaf => _useSaf;

  Future<void> init() async {
    final testDir = Directory(_proot.rootfsHome);
    if (testDir.existsSync()) {
      _useSaf = false;
    } else {
      _useSaf = true;
    }
  }

  void setSafMode(bool value) {
    _useSaf = value;
  }

  Future<List<FileSystemEntity>> listDir(String path) async {
    if (_useSaf) {
      return _listDirSaf(path);
    }
    return _listDirDirect(path);
  }

  Future<List<FileSystemEntity>> _listDirDirect(String path) async {
    final dir = Directory(path);
    if (!dir.existsSync()) {
      throw FileSystemException('Directory not found', path);
    }
    return dir.listSync()..sort((a, b) => a.path.compareTo(b.path));
  }

  Future<List<FileSystemEntity>> _listDirSaf(String path) async {
    // SAF implementation would traverse via document provider
    return [];
  }

  Future<String> readFile(String path) async {
    if (_useSaf) {
      return _readFileSaf(path);
    }
    return _readFileDirect(path);
  }

  Future<String> _readFileDirect(String path) async {
    final file = File(path);
    if (!file.existsSync()) {
      throw FileSystemException('File not found', path);
    }
    return file.readAsString();
  }

  Future<String> _readFileSaf(String path) async {
    return '';
  }

  Future<void> writeFile(String path, String content) async {
    if (_useSaf) {
      await _writeFileSaf(path, content);
    } else {
      await _writeFileDirect(path, content);
    }
  }

  Future<void> _writeFileDirect(String path, String content) async {
    final file = File(path);
    final parent = file.parent;
    if (!parent.existsSync()) {
      await parent.create(recursive: true);
    }
    await file.writeAsString(content);
  }

  Future<void> _writeFileSaf(String path, String content) async {
    // SAF implementation
  }

  Future<void> deleteFile(String path) async {
    if (_useSaf) {
      return;
    }
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  Future<void> createDirectory(String path) async {
    if (_useSaf) {
      return;
    }
    final dir = Directory(path);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
  }

  Future<bool> exists(String path) async {
    if (_useSaf) {
      return false;
    }
    return FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound;
  }

  Future<int> getFileSize(String path) async {
    if (_useSaf) {
      return 0;
    }
    final file = File(path);
    if (!file.existsSync()) return 0;
    return file.lengthSync();
  }

  Future<DateTime> getLastModified(String path) async {
    if (_useSaf) {
      return DateTime.now();
    }
    final file = File(path);
    if (!file.existsSync()) return DateTime.now();
    return file.lastModifiedSync();
  }

  String getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'dart' => 'text/x-dart',
      'yaml' || 'yml' => 'text/x-yaml',
      'json' => 'application/json',
      'xml' => 'application/xml',
      'html' => 'text/html',
      'css' => 'text/css',
      'js' => 'application/javascript',
      'kt' => 'text/x-kotlin',
      'java' => 'text/x-java',
      'gradle' => 'text/x-gradle',
      'md' => 'text/markdown',
      'txt' => 'text/plain',
      _ => 'application/octet-stream',
    };
  }
}
