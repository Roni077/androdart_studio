import 'package:flutter/material.dart';
import 'theme.dart';

enum ActionType {
  newFile,
  openFile,
  saveFile,
  run,
  build,
  clean,
  terminal,
  settings,
}

class Toolbar extends StatelessWidget {
  final List<ActionType> actions;
  final Function(ActionType)? onAction;
  final bool isRunning;

  const Toolbar({
    super.key,
    required this.actions,
    this.onAction,
    this.isRunning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: const BoxDecoration(
        color: AndrodartTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          ...actions.map((action) => _buildActionButton(action)),
          const Spacer(),
          if (isRunning)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(ActionType action) {
    final (icon, tooltip) = _getActionInfo(action);

    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      onPressed: isRunning && action == ActionType.run
          ? null
          : () => onAction?.call(action),
      color: AndrodartTheme.textSecondary,
      hoverColor: AndrodartTheme.primaryColor.withValues(alpha: 0.2),
    );
  }

  (IconData, String) _getActionInfo(ActionType action) {
    return switch (action) {
      ActionType.newFile => (Icons.add, 'New File'),
      ActionType.openFile => (Icons.folder_open, 'Open File'),
      ActionType.saveFile => (Icons.save, 'Save'),
      ActionType.run => (Icons.play_arrow, 'Run'),
      ActionType.build => (Icons.build, 'Build APK'),
      ActionType.clean => (Icons.delete_outline, 'Clean'),
      ActionType.terminal => (Icons.terminal, 'Terminal'),
      ActionType.settings => (Icons.settings, 'Settings'),
    };
  }
}
