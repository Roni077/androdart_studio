import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'proot_service.dart';
import 'shell_service.dart';

enum BuildMode { debug, release }

class BuildService {
  final ShellService _shell;

  BuildService({
    required ProotService proot,
    required ShellService shell,
    required MethodChannel ptyChannel,
  }) : _shell = shell;

  Future<void> flutterCreate({
    required String projectName,
    required String org,
    String? template,
  }) async {
    final args = [
      'create',
      '--org',
      org,
      if (template != null) ...['--template', template],
      projectName,
    ];
    await _shell.writeInput('flutter ${args.join(' ')}\n');
  }

  Future<void> flutterBuild({
    required String projectPath,
    required BuildMode mode,
  }) async {
    final flag = mode == BuildMode.debug ? '--debug' : '--release';
    await _shell.writeInput('cd $projectPath && flutter build apk $flag\n');
  }

  Future<void> flutterPubGet(String projectPath) async {
    await _shell.writeInput('cd $projectPath && flutter pub get\n');
  }

  Future<void> flutterClean(String projectPath) async {
    await _shell.writeInput('cd $projectPath && flutter clean\n');
  }

  Future<void> flutterDoctor() async {
    await _shell.writeInput('flutter doctor -v\n');
  }

  String getApkOutputPath(String projectPath, BuildMode mode) {
    final suffix = mode == BuildMode.debug ? 'debug' : 'release';
    return '$projectPath/build/app/outputs/flutter-apk/app-$suffix.apk';
  }

  Future<bool> validateProject(String projectPath) async {
    final pubspec = File('$projectPath/pubspec.yaml');
    final libDir = Directory('$projectPath/lib');
    return pubspec.existsSync() && libDir.existsSync();
  }

  Future<Map<String, dynamic>> getProjectInfo(String projectPath) async {
    final pubspec = File('$projectPath/pubspec.yaml');
    if (!pubspec.existsSync()) return {};

    final content = pubspec.readAsStringSync();
    final nameMatch = RegExp(r'name:\s+(.+)').firstMatch(content);
    final versionMatch = RegExp(r'version:\s+(.+)').firstMatch(content);

    return {
      'name': nameMatch?.group(1)?.trim() ?? 'unknown',
      'version': versionMatch?.group(1)?.trim() ?? '0.0.0',
      'path': projectPath,
    };
  }
}
