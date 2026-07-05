import 'package:flutter/material.dart';
import '../ui/theme.dart';
import 'terminal_session.dart';
import 'terminal_widget.dart';

class TerminalTab extends StatefulWidget {
  final List<TerminalSession> sessions;
  final int selectedIndex;
  final Function(int) onSessionSelected;
  final Function() onNewSession;
  final Function(int) onCloseSession;

  const TerminalTab({
    super.key,
    required this.sessions,
    required this.selectedIndex,
    required this.onSessionSelected,
    required this.onNewSession,
    required this.onCloseSession,
  });

  @override
  State<TerminalTab> createState() => _TerminalTabState();
}

class _TerminalTabState extends State<TerminalTab> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSessionBar(),
        Expanded(
          child: widget.sessions.isNotEmpty &&
                  widget.selectedIndex >= 0 &&
                  widget.selectedIndex < widget.sessions.length
              ? TerminalWidget(session: widget.sessions[widget.selectedIndex])
              : _buildEmptyState(),
        ),
      ],
    );
  }

  Widget _buildSessionBar() {
    return Container(
      height: 36,
      decoration: const BoxDecoration(
        color: AndrodartTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.sessions.length,
              itemBuilder: (context, index) {
                final isSelected = index == widget.selectedIndex;

                return GestureDetector(
                  onTap: () => widget.onSessionSelected(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AndrodartTheme.backgroundColor
                          : Colors.transparent,
                      border: Border(
                        right: BorderSide(color: Colors.grey[800]!, width: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.terminal,
                          size: 14,
                          color: isSelected
                              ? AndrodartTheme.primaryColor
                              : AndrodartTheme.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Session ${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? AndrodartTheme.textPrimary
                                : AndrodartTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => widget.onCloseSession(index),
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: AndrodartTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: widget.onNewSession,
            color: AndrodartTheme.textSecondary,
            tooltip: 'New Session',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.terminal,
            size: 64,
            color: AndrodartTheme.textMuted,
          ),
          const SizedBox(height: 16),
          const Text(
            'No terminal sessions',
            style: TextStyle(
              fontSize: 16,
              color: AndrodartTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Open a new session to get started',
            style: TextStyle(
              fontSize: 14,
              color: AndrodartTheme.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: widget.onNewSession,
            icon: const Icon(Icons.add),
            label: const Text('New Session'),
          ),
        ],
      ),
    );
  }
}
