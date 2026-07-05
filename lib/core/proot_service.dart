import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:flutter/services.dart';

class ProotService {
  static const _rootfsDirName = 'rootfs';
  static const _rootfsUrl =
      'https://github.com/debuerreotype/docker-debian-artifacts/raw/dist-arm64v8/bookworm/oci/blobs/rootfs.tar.gz';

  final String _nativeLibDir;
  final String _filesDir;

  ProotService({
    required MethodChannel channel,
    required String nativeLibDir,
    required String filesDir,
  })  : _nativeLibDir = nativeLibDir,
        _filesDir = filesDir;

  String get rootfsDir => '$_filesDir/$_rootfsDirName';
  String get rootfsHome => '$rootfsDir/root';
  String get prootBin => '$_nativeLibDir/libproot.so';
  String get tallocLib => '$_nativeLibDir/libtalloc.so';
  String get shmemLib => '$_nativeLibDir/libandroid-shmem.so';

  bool get isRootfsReady {
    final bin = Directory('$rootfsDir/bin');
    return bin.existsSync() && bin.listSync().isNotEmpty;
  }

  Future<void> ensureRootfs({
    Function(double progress, String message)? onProgress,
  }) async {
    if (isRootfsReady) return;

    final rootfsDirectory = Directory(rootfsDir);
    if (!rootfsDirectory.existsSync()) {
      await rootfsDirectory.create(recursive: true);
    }

    onProgress?.call(0.0, 'Downloading Debian rootfs...');

    final client = http.Client();
    final request = http.Request('GET', Uri.parse(_rootfsUrl));
    final response = await client.send(request);

    if (response.statusCode != 200) {
      client.close();
      throw Exception('Failed to download rootfs: ${response.statusCode}');
    }

    final contentLength = response.contentLength ?? 0;
    final bytes = <int>[];
    int received = 0;

    await for (final chunk in response.stream) {
      bytes.addAll(chunk);
      received += chunk.length;
      if (contentLength > 0) {
        onProgress?.call(
          received / contentLength * 0.7,
          'Downloading rootfs: ${(received / 1024 / 1024).toStringAsFixed(1)} MiB',
        );
      }
    }
    client.close();

    onProgress?.call(0.7, 'Extracting rootfs...');

    final archive = GZipDecoder().decodeBytes(Uint8List.fromList(bytes));
    final tarArchive = TarDecoder().decodeBytes(archive);

    int extracted = 0;
    final total = tarArchive.length;
    for (final file in tarArchive) {
      final filePath = '$rootfsDir/${file.name}';
      if (file.isFile) {
        final outDir = Directory(filePath.substring(0, filePath.lastIndexOf('/')));
        if (!outDir.existsSync()) {
          await outDir.create(recursive: true);
        }
        final outFile = File(filePath);
        await outFile.writeAsBytes(file.content as List<int>);
      } else if (file.isDirectory) {
        final outDir = Directory(filePath);
        if (!outDir.existsSync()) {
          await outDir.create(recursive: true);
        }
      }
      extracted++;
      if (extracted % 100 == 0) {
        onProgress?.call(
          0.7 + (extracted / total) * 0.2,
          'Extracting rootfs: $extracted/$total',
        );
      }
    }

    onProgress?.call(0.9, 'Creating directories...');

    final dirs = [
      '$rootfsDir/tmp',
      '$rootfsDir/root',
      '$rootfsDir/root/.config',
      '$rootfsDir/root/storage',
      '$rootfsDir/proc',
      '$rootfsDir/sys',
      '$rootfsDir/dev',
    ];
    for (final dirPath in dirs) {
      final dir = Directory(dirPath);
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
    }

    final hostsFile = File('$rootfsDir/etc/hosts');
    if (!hostsFile.existsSync()) {
      await hostsFile.writeAsString('127.0.0.1 localhost\n');
    }

    final resolvFile = File('$rootfsDir/etc/resolv.conf');
    if (!resolvFile.existsSync()) {
      await resolvFile.writeAsString('nameserver 8.8.8.8\nnameserver 8.8.4.4\n');
    }

    onProgress?.call(1.0, 'Rootfs ready');
  }

  List<String> buildProotCommand({
    required String command,
    List<String> args = const [],
    Map<String, String> env = const {},
    String? workingDir,
  }) {
    final prootArgs = [
      '-L',
      '-S',
      rootfsDir,
      '--link2symlink',
      '--kill-on-exit',
      '--root-id',
      '--kernel-release=5.4.0',
    ];

    prootArgs.addAll(['-b', '/dev']);
    prootArgs.addAll(['-b', '/proc']);
    prootArgs.addAll(['-b', '/sys']);
    prootArgs.addAll(['-b', '/dev/urandom:/dev/random']);
    prootArgs.addAll(['-b', '/proc/self/fd:/dev/fd']);
    prootArgs.addAll(['-b', '/proc/self/fd/0:/dev/stdin']);
    prootArgs.addAll(['-b', '/proc/self/fd/1:/dev/stdout']);
    prootArgs.addAll(['-b', '/proc/self/fd/2:/dev/stderr']);
    prootArgs.addAll(['-b', '/storage:/storage']);

    prootArgs.addAll(['-E', 'PROOT_TMP_DIR=$_filesDir/tmp']);

    env.forEach((key, value) {
      prootArgs.addAll(['-E', '$key=$value']);
    });

    if (workingDir != null) {
      prootArgs.addAll(['-w', workingDir]);
    }

    prootArgs.add('/bin/sh');
    prootArgs.addAll(['-c', command]);

    return [prootBin, ...prootArgs];
  }
}
