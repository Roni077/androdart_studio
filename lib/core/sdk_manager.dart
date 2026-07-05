import 'dart:io';
import 'proot_service.dart';
import 'shell_service.dart';

class SdkManager {
  final ProotService _proot;

  SdkManager({
    required ProotService proot,
    required ShellService shell,
  }) : _proot = proot;

  String get _rootfsHome => _proot.rootfsHome;
  String get _rootfsDir => _proot.rootfsDir;
  String get _jdkDir => '$_rootfsHome/jdk';
  String get _flutterDir => '$_rootfsHome/flutter';
  String get _androidSdkDir => '$_rootfsHome/android-sdk';
  String get _cmdlineToolsDir => '$_androidSdkDir/cmdline-tools/latest';
  String get _buildToolsDir => '$_androidSdkDir/build-tools/35.0.1';

  Future<bool> isSetupComplete() async {
    final marker = File('$_rootfsHome/.setup_complete');
    return marker.existsSync();
  }

  Future<bool> isJdkInstalled() async {
    final java = File('$_jdkDir/bin/java');
    return java.existsSync();
  }

  Future<bool> isFlutterInstalled() async {
    final flutter = File('$_flutterDir/bin/flutter');
    return flutter.existsSync();
  }

  Future<bool> isAndroidSdkInstalled() async {
    final sdkmanager = File('$_cmdlineToolsDir/bin/sdkmanager');
    return sdkmanager.existsSync();
  }

  Future<bool> isAapt2Installed() async {
    final aapt2 = File('$_buildToolsDir/aapt2');
    return aapt2.existsSync();
  }

  Future<bool> isGitInstalled() async {
    final gitBin = File('$_rootfsDir/usr/bin/git');
    return gitBin.existsSync();
  }

  Future<Map<String, bool>> verifyAll() async {
    return {
      'jdk': await isJdkInstalled(),
      'git': await isGitInstalled(),
      'flutter': await isFlutterInstalled(),
      'android_sdk': await isAndroidSdkInstalled(),
      'aapt2': await isAapt2Installed(),
    };
  }

  Future<Map<String, String>> getVersions() async {
    final versions = <String, String>{};

    if (await isJdkInstalled()) {
      versions['jdk'] = 'JDK 17 (Temurin)';
    }

    if (await isFlutterInstalled()) {
      versions['flutter'] = 'Flutter 3.44.4';
    }

    if (await isGitInstalled()) {
      versions['git'] = 'Git';
    }

    if (await isAndroidSdkInstalled()) {
      versions['android_sdk'] = 'Android SDK';
    }

    if (await isAapt2Installed()) {
      versions['aapt2'] = 'aapt2 ARM64';
    }

    return versions;
  }
}
