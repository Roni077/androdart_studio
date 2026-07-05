import 'dart:async';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'proot_service.dart';
import 'shell_service.dart';

class StorageService {
  final ProotService _proot;
  final ShellService _shell;

  StorageService({
    required ProotService proot,
    required ShellService shell,
  })  : _proot = proot,
        _shell = shell;

  bool get isStorageSetup {
    final storageDir = Directory('${_proot.rootfsHome}/storage');
    return storageDir.existsSync() &&
        storageDir.listSync().isNotEmpty;
  }

  Future<bool> setupStorage() async {
    // Request permissions
    final status = await Permission.manageExternalStorage.request();
    if (!status.isGranted) {
      // Try standard storage permission
      final standardStatus = await Permission.storage.request();
      if (!standardStatus.isGranted) {
        return false;
      }
    }

    // Create storage directory in rootfs
    final storageDir = Directory('${_proot.rootfsHome}/storage');
    await storageDir.create(recursive: true);

    // Create symlinks to shared storage
    final symlinks = {
      'shared': '/storage/emulated/0',
      'downloads': '/storage/emulated/0/Download',
      'dcim': '/storage/emulated/0/DCIM',
      'music': '/storage/emulated/0/Music',
      'pictures': '/storage/emulated/0/Pictures',
      'movies': '/storage/emulated/0/Movies',
    };

    for (final entry in symlinks.entries) {
      final linkPath = '${_proot.rootfsHome}/storage/${entry.key}';
      final targetPath = entry.value;

      // Create symlink using ln -s
      await _shell.writeInput('ln -sf $targetPath $linkPath');
    }

    // Create common directories if they don't exist
    final commonDirs = [
      '/storage/emulated/0/Download',
      '/storage/emulated/0/DCIM',
      '/storage/emulated/0/Music',
      '/storage/emulated/0/Pictures',
      '/storage/emulated/0/Movies',
    ];

    for (final dir in commonDirs) {
      final directory = Directory(dir);
      if (!directory.existsSync()) {
        await directory.create(recursive: true);
      }
    }

    return true;
  }

  Future<List<String>> getGrantedPaths() async {
    final paths = <String>[];

    // Check if MANAGE_EXTERNAL_STORAGE is granted
    if (await Permission.manageExternalStorage.isGranted) {
      paths.add('/storage/emulated/0');
    }

    // Check standard storage permission
    if (await Permission.storage.isGranted) {
      paths.add('/storage/emulated/0');
    }

    return paths;
  }

  Future<void> releaseStorage() async {
    await Permission.manageExternalStorage.request();
    await Permission.storage.request();
  }

  Future<Map<String, bool>> getStorageStatus() async {
    return {
      'manage_external':
          await Permission.manageExternalStorage.isGranted,
      'storage': await Permission.storage.isGranted,
    };
  }

  String getStoragePath(String type) {
    final storageDir = '${_proot.rootfsHome}/storage';
    return '$storageDir/$type';
  }

  Future<int> getStorageUsage() async {
    final result = await Process.run('du', ['-sb', '${_proot.rootfsHome}/storage']);
    if (result.exitCode == 0) {
      final output = result.stdout.toString().split('\t').first;
      return int.tryParse(output) ?? 0;
    }
    return 0;
  }

  Future<List<FileSystemEntity>> listStorageContents() async {
    final storageDir = Directory('${_proot.rootfsHome}/storage');
    if (!storageDir.existsSync()) {
      return [];
    }
    return storageDir.listSync();
  }
}
