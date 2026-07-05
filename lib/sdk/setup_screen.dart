import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xterm/xterm.dart';
import '../core/proot_service.dart';
import '../core/shell_service.dart';
import '../ui/theme.dart';

class SetupScreen extends StatefulWidget {
  final ShellService shell;
  final ProotService proot;
  final VoidCallback onComplete;

  const SetupScreen({
    super.key,
    required this.shell,
    required this.proot,
    required this.onComplete,
  });

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  late Terminal _terminal;
  double _progress = 0.0;
  bool _isComplete = false;
  String _currentStep = 'Initializing...';
  StreamSubscription<String>? _outputSubscription;

  @override
  void initState() {
    super.initState();
    _terminal = Terminal();
    _startSetup();
  }

  @override
  void dispose() {
    _outputSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startSetup() async {
    try {
      // Step 1: Download and extract rootfs
      setState(() => _currentStep = 'Downloading Debian rootfs...');
      await widget.proot.ensureRootfs(
        onProgress: (progress, message) {
          setState(() {
            _progress = progress * 0.3;
            _currentStep = message;
          });
        },
      );

      setState(() {
        _progress = 0.3;
        _currentStep = 'Rootfs ready. Starting setup...';
      });
      _terminal.write('\r\n[ROOTFS] Debian rootfs downloaded and extracted\r\n');

      // Step 2: Copy setup.sh from assets into rootfs
      final scriptContent = await rootBundle.loadString('assets/setup.sh');
      final scriptFile = File('${widget.proot.rootfsDir}/tmp/setup.sh');
      await scriptFile.writeAsString(scriptContent);

      // Step 3: Run setup.sh inside proot
      _outputSubscription = widget.shell.output.listen(
        (data) {
          _terminal.write(data);
          _parseOutput(data);
        },
      );

      await widget.shell.startShell();
      await widget.shell.writeInput('sh /tmp/setup.sh\n');
    } catch (e) {
      setState(() {
        _currentStep = 'Error: $e';
      });
      _terminal.write('\r\n[ERROR] $e\r\n');
    }
  }

  void _parseOutput(String line) {
    if (line.startsWith('[PROGRESS]')) {
      final value = double.tryParse(line.split(' ').last) ?? 0.0;
      // Setup.sh progress is 70% (after rootfs 30%)
      setState(() => _progress = 0.3 + value * 0.7);
    }

    if (line.startsWith('[STEP]')) {
      setState(() => _currentStep = line.substring(6).trim());
    }

    if (line.startsWith('[COMPLETE]')) {
      setState(() {
        _isComplete = true;
        _progress = 1.0;
        _currentStep = 'Setup Complete!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AndrodartTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(),
            Expanded(child: _buildTerminal()),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(
            Icons.code,
            size: 64,
            color: AndrodartTheme.primaryColor,
          ),
          const SizedBox(height: 16),
          const Text(
            'androdart_studio',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AndrodartTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentStep,
            style: TextStyle(
              fontSize: 14,
              color: _isComplete
                  ? AndrodartTheme.successColor
                  : AndrodartTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progress',
                style: TextStyle(
                  fontSize: 12,
                  color: AndrodartTheme.textMuted,
                ),
              ),
              Text(
                '${(_progress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: AndrodartTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: AndrodartTheme.surfaceColor,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AndrodartTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminal() {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: TerminalView(
          _terminal,
          padding: const EdgeInsets.all(12),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isComplete ? widget.onComplete : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AndrodartTheme.primaryColor,
            disabledBackgroundColor: AndrodartTheme.surfaceColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(
            _isComplete ? 'Get Started' : 'Setting up...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _isComplete
                  ? Colors.white
                  : AndrodartTheme.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
