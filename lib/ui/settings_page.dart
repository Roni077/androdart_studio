import 'package:flutter/material.dart';
import '../core/settings_service.dart';
import '../ui/theme.dart';

class SettingsPage extends StatefulWidget {
  final SettingsService settings;

  const SettingsPage({
    super.key,
    required this.settings,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _sdkPathController;
  late TextEditingController _shellPathController;
  late double _fontSize;
  late bool _autoSave;
  late bool _showLineNumbers;
  late bool _wordWrap;

  @override
  void initState() {
    super.initState();
    _sdkPathController = TextEditingController(text: widget.settings.sdkPath);
    _shellPathController =
        TextEditingController(text: widget.settings.shellPath);
    _fontSize = widget.settings.fontSize;
    _autoSave = widget.settings.autoSave;
    _showLineNumbers = widget.settings.showLineNumbers;
    _wordWrap = widget.settings.wordWrap;
  }

  @override
  void dispose() {
    _sdkPathController.dispose();
    _shellPathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            'SDK Configuration',
            [
              _buildTextField(
                label: 'Flutter SDK Path',
                controller: _sdkPathController,
                onChanged: (value) => widget.settings.setSdkPath(value),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                label: 'Shell Path',
                controller: _shellPathController,
                onChanged: (value) => widget.settings.setShellPath(value),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Editor',
            [
              _buildSlider(
                label: 'Font Size',
                value: _fontSize,
                min: 10,
                max: 24,
                onChanged: (value) {
                  setState(() => _fontSize = value);
                  widget.settings.setFontSize(value);
                },
              ),
              const SizedBox(height: 12),
              _buildSwitch(
                label: 'Auto Save',
                value: _autoSave,
                onChanged: (value) {
                  setState(() => _autoSave = value);
                  widget.settings.setAutoSave(value);
                },
              ),
              const SizedBox(height: 12),
              _buildSwitch(
                label: 'Show Line Numbers',
                value: _showLineNumbers,
                onChanged: (value) {
                  setState(() => _showLineNumbers = value);
                  widget.settings.setShowLineNumbers(value);
                },
              ),
              const SizedBox(height: 12),
              _buildSwitch(
                label: 'Word Wrap',
                value: _wordWrap,
                onChanged: (value) {
                  setState(() => _wordWrap = value);
                  widget.settings.setWordWrap(value);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Storage',
            [
              _buildInfoTile(
                title: 'Root Filesystem',
                subtitle: '/data/data/.../files/rootfs',
                icon: Icons.folder,
              ),
              const SizedBox(height: 8),
              _buildInfoTile(
                title: 'Projects',
                subtitle: '/root/projects',
                icon: Icons.code,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'About',
            [
              _buildInfoTile(
                title: 'Version',
                subtitle: '1.0.0+1',
                icon: Icons.info,
              ),
              const SizedBox(height: 8),
              _buildInfoTile(
                title: 'Flutter SDK',
                subtitle: '3.44.4',
                icon: Icons.flutter_dash,
              ),
              const SizedBox(height: 8),
              _buildInfoTile(
                title: 'Dart SDK',
                subtitle: '3.12.2',
                icon: Icons.code,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AndrodartTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required Function(String) onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: AndrodartTheme.surfaceColor,
      ),
      style: const TextStyle(color: AndrodartTheme.textPrimary),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: AndrodartTheme.textSecondary),
            ),
            Text(
              '${value.round()}px',
              style: const TextStyle(color: AndrodartTheme.textMuted),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSwitch({
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AndrodartTheme.textSecondary),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: AndrodartTheme.primaryColor),
      title: Text(
        title,
        style: const TextStyle(color: AndrodartTheme.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AndrodartTheme.textMuted, fontSize: 12),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
}
