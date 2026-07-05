import 'package:flutter/material.dart';
import '../ui/theme.dart';

class FileTile extends StatelessWidget {
  final String name;
  final String path;
  final bool isDirectory;
  final bool isExpanded;
  final int depth;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const FileTile({
    super.key,
    required this.name,
    required this.path,
    this.isDirectory = false,
    this.isExpanded = false,
    this.depth = 0,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: EdgeInsets.only(
          left: 12.0 + (depth * 16.0),
          right: 12.0,
          top: 4,
          bottom: 4,
        ),
        child: Row(
          children: [
            _buildIcon(),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  color: isDirectory
                      ? AndrodartTheme.textPrimary
                      : AndrodartTheme.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (isDirectory) {
      return Icon(
        isExpanded ? Icons.folder_open : Icons.folder,
        size: 18,
        color: AndrodartTheme.primaryColor,
      );
    }

    return Icon(
      _getFileIcon(),
      size: 18,
      color: _getFileColor(),
    );
  }

  IconData _getFileIcon() {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'dart' => Icons.code,
      'yaml' || 'yml' => Icons.settings,
      'json' => Icons.data_object,
      'xml' => Icons.code,
      'html' => Icons.language,
      'css' => Icons.palette,
      'js' => Icons.javascript,
      'kt' => Icons.code,
      'java' => Icons.coffee,
      'gradle' => Icons.build,
      'md' => Icons.description,
      'txt' => Icons.description,
      'png' || 'jpg' || 'jpeg' || 'gif' => Icons.image,
      'mp3' || 'wav' => Icons.audio_file,
      'mp4' || 'avi' => Icons.video_file,
      'pdf' => Icons.picture_as_pdf,
      _ => Icons.insert_drive_file,
    };
  }

  Color _getFileColor() {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'dart' => AndrodartTheme.syntaxKeyword,
      'yaml' || 'yml' => AndrodartTheme.syntaxString,
      'json' => AndrodartTheme.syntaxNumber,
      'md' => AndrodartTheme.syntaxComment,
      'txt' => AndrodartTheme.textMuted,
      _ => AndrodartTheme.textSecondary,
    };
  }
}
