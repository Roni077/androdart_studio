import 'package:flutter/material.dart';
import '../ui/theme.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(
            child: Icon(
              Icons.code,
              size: 80,
              color: AndrodartTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'androdart_studio',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AndrodartTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'A lightweight Flutter IDE for Android',
              style: TextStyle(
                fontSize: 14,
                color: AndrodartTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildSection(
            'Toolchain',
            [
              _buildInfoRow('Flutter SDK', '3.44.4'),
              _buildInfoRow('Dart SDK', '3.12.2'),
              _buildInfoRow('Android SDK', '35.0.1'),
              _buildInfoRow('JDK', 'OpenJDK 17'),
              _buildInfoRow('Git', '2.39+'),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Features',
            [
              _buildFeatureItem(Icons.code, 'Code Editor', 'Syntax highlighting, line numbers, code folding'),
              _buildFeatureItem(Icons.terminal, 'Terminal', 'Full PTY terminal with proot container'),
              _buildFeatureItem(Icons.folder, 'File Browser', 'Browse and edit files in your projects'),
              _buildFeatureItem(Icons.build, 'Build System', 'Build Android APKs directly on device'),
              _buildFeatureItem(Icons.storage, 'Storage Access', 'Access shared storage via SAF'),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Credits',
            [
              _buildInfoRow('proot', 'proot-me/proot'),
              _buildInfoRow('re_editor', 'reqable/re-editor'),
              _buildInfoRow('xterm', 'TerminalStudio/xterm.dart'),
              _buildInfoRow('Flutter', 'flutter/flutter'),
            ],
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Made with ❤️ for Flutter developers',
              style: TextStyle(
                fontSize: 12,
                color: AndrodartTheme.textMuted,
              ),
            ),
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
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AndrodartTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AndrodartTheme.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AndrodartTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AndrodartTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AndrodartTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AndrodartTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
