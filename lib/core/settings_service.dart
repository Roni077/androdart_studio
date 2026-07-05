import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keySdkPath = 'sdk_path';
  static const _keyShellPath = 'shell_path';
  static const _keyFontSize = 'font_size';
  static const _keyTheme = 'theme';
  static const _keyAutoSave = 'auto_save';
  static const _keyShowLineNumbers = 'show_line_numbers';
  static const _keyWordWrap = 'word_wrap';

  late SharedPreferences _prefs;

  String get sdkPath => _prefs.getString(_keySdkPath) ?? '/root/flutter';
  String get shellPath => _prefs.getString(_keyShellPath) ?? '/bin/bash';
  double get fontSize => _prefs.getDouble(_keyFontSize) ?? 14.0;
  String get theme => _prefs.getString(_keyTheme) ?? 'dark';
  bool get autoSave => _prefs.getBool(_keyAutoSave) ?? true;
  bool get showLineNumbers => _prefs.getBool(_keyShowLineNumbers) ?? true;
  bool get wordWrap => _prefs.getBool(_keyWordWrap) ?? false;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> setSdkPath(String value) async {
    await _prefs.setString(_keySdkPath, value);
  }

  Future<void> setShellPath(String value) async {
    await _prefs.setString(_keyShellPath, value);
  }

  Future<void> setFontSize(double value) async {
    await _prefs.setDouble(_keyFontSize, value);
  }

  Future<void> setTheme(String value) async {
    await _prefs.setString(_keyTheme, value);
  }

  Future<void> setAutoSave(bool value) async {
    await _prefs.setBool(_keyAutoSave, value);
  }

  Future<void> setShowLineNumbers(bool value) async {
    await _prefs.setBool(_keyShowLineNumbers, value);
  }

  Future<void> setWordWrap(bool value) async {
    await _prefs.setBool(_keyWordWrap, value);
  }
}
