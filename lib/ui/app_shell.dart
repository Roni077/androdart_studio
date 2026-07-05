import 'package:flutter/material.dart';
import 'theme.dart';

enum AppTab { editor, terminal, files }

class AppShell extends StatefulWidget {
  final AppTab initialTab;
  final List<Widget> tabs;

  const AppShell({
    super.key,
    this.initialTab = AppTab.editor,
    required this.tabs,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab.index;
  }

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _selectedIndex = widget.initialTab.index;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: widget.tabs[_selectedIndex],
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.code),
            selectedIcon: Icon(Icons.code, color: AndrodartTheme.primaryColor),
            label: 'Editor',
          ),
          NavigationDestination(
            icon: Icon(Icons.terminal),
            selectedIcon: Icon(Icons.terminal, color: AndrodartTheme.primaryColor),
            label: 'Terminal',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder),
            selectedIcon: Icon(Icons.folder, color: AndrodartTheme.primaryColor),
            label: 'Files',
          ),
        ],
      ),
    );
  }
}
