import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../ui/theme.dart';
import 'build_runner.dart';

class BuildScreen extends StatefulWidget {
  final BuildRunner buildRunner;

  const BuildScreen({
    super.key,
    required this.buildRunner,
  });

  @override
  State<BuildScreen> createState() => _BuildScreenState();
}

class _BuildScreenState extends State<BuildScreen> {
  final ScrollController _scrollController = ScrollController();
  BuildStatus _status = BuildStatus.idle;

  @override
  void initState() {
    super.initState();
    widget.buildRunner.status.listen((status) {
      setState(() => _status = status);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Build Output'),
        actions: [
          if (_status == BuildStatus.running)
            TextButton(
              onPressed: () {
                widget.buildRunner.cancelBuild();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.red),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy Output',
            onPressed: _copyOutput,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear Output',
            onPressed: () {
              widget.buildRunner.clearOutput();
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusBar(),
          Expanded(
            child: _buildOutputView(),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _status == BuildStatus.running
            ? AndrodartTheme.primaryColor.withValues(alpha: 0.2)
            : _status == BuildStatus.success
                ? AndrodartTheme.successColor.withValues(alpha: 0.2)
                : _status == BuildStatus.failed
                    ? AndrodartTheme.errorColor.withValues(alpha: 0.2)
                    : AndrodartTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey[800]!, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          _buildStatusIcon(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _status == BuildStatus.running
                      ? 'Building...'
                      : _status == BuildStatus.success
                          ? 'Build Successful'
                          : _status == BuildStatus.failed
                              ? 'Build Failed'
                              : 'Ready',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AndrodartTheme.textPrimary,
                  ),
                ),
                if (widget.buildRunner.currentBuild != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${widget.buildRunner.currentBuild!.projectName} • ${widget.buildRunner.currentBuild!.isDebug ? "Debug" : "Release"}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AndrodartTheme.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_status == BuildStatus.running)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (_status) {
      case BuildStatus.running:
        return const Icon(
          Icons.hourglass_empty,
          color: AndrodartTheme.primaryColor,
        );
      case BuildStatus.success:
        return const Icon(
          Icons.check_circle,
          color: AndrodartTheme.successColor,
        );
      case BuildStatus.failed:
        return const Icon(
          Icons.error,
          color: AndrodartTheme.errorColor,
        );
      case BuildStatus.idle:
        return const Icon(
          Icons.code,
          color: AndrodartTheme.textMuted,
        );
    }
  }

  Widget _buildOutputView() {
    final output = widget.buildRunner.outputBuffer;

    if (output.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.terminal, size: 64, color: AndrodartTheme.textMuted),
            SizedBox(height: 16),
            Text(
              'No build output',
              style: TextStyle(color: AndrodartTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFF1E1E2E),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: output.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              output[index],
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: AndrodartTheme.textSecondary,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AndrodartTheme.surfaceColor,
        border: Border(
          top: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${widget.buildRunner.outputBuffer.length} lines',
            style: const TextStyle(
              fontSize: 12,
              color: AndrodartTheme.textMuted,
            ),
          ),
          const Spacer(),
          if (_status == BuildStatus.success)
            ElevatedButton.icon(
              onPressed: _openApkLocation,
              icon: const Icon(Icons.folder_open, size: 16),
              label: const Text('Open APK'),
            ),
        ],
      ),
    );
  }

  void _copyOutput() {
    final output = widget.buildRunner.outputBuffer.join('\n');
    Clipboard.setData(ClipboardData(text: output));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Output copied to clipboard')),
    );
  }

  void _openApkLocation() {
    // TODO: Open file manager at APK location
  }
}
