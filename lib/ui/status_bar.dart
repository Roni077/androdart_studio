import 'package:flutter/material.dart';
import 'theme.dart';

class StatusBar extends StatelessWidget {
  final String? filePath;
  final int? line;
  final int? column;
  final String? encoding;
  final String? language;
  final bool sdkReady;
  final String? message;

  const StatusBar({
    super.key,
    this.filePath,
    this.line,
    this.column,
    this.encoding,
    this.language,
    this.sdkReady = false,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      decoration: const BoxDecoration(
        color: AndrodartTheme.surfaceColor,
        border: Border(
          top: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // SDK status
          _buildSdkStatus(),
          const SizedBox(width: 12),

          // File path
          if (filePath != null) ...[
            Icon(Icons.description, size: 14, color: AndrodartTheme.textMuted),
            const SizedBox(width: 4),
            Text(
              filePath!.split('/').last,
              style: const TextStyle(
                color: AndrodartTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Line:Column
          if (line != null && column != null)
            Text(
              'Ln $line, Col $column',
              style: const TextStyle(
                color: AndrodartTheme.textMuted,
                fontSize: 12,
              ),
            ),

          const Spacer(),

          // Message
          if (message != null)
            Text(
              message!,
              style: const TextStyle(
                color: AndrodartTheme.textMuted,
                fontSize: 12,
              ),
            ),

          // Language
          if (language != null) ...[
            const SizedBox(width: 12),
            Text(
              language!,
              style: const TextStyle(
                color: AndrodartTheme.textMuted,
                fontSize: 12,
              ),
            ),
          ],

          // Encoding
          if (encoding != null) ...[
            const SizedBox(width: 12),
            Text(
              encoding!,
              style: const TextStyle(
                color: AndrodartTheme.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSdkStatus() {
    return Tooltip(
      message: sdkReady ? 'SDK Ready' : 'SDK Not Installed',
      child: Icon(
        sdkReady ? Icons.check_circle : Icons.warning,
        size: 14,
        color: sdkReady ? AndrodartTheme.successColor : AndrodartTheme.warningColor,
      ),
    );
  }
}
