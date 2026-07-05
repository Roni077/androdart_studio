import 'package:flutter/material.dart';
import '../ui/theme.dart';

enum ErrorType {
  rootDenied,
  sdkMissing,
  buildFailed,
  network,
  diskSpace,
  unknown,
}

class ErrorScreen extends StatelessWidget {
  final ErrorType type;
  final String? message;
  final VoidCallback? onRetry;
  final VoidCallback? onSettings;

  const ErrorScreen({
    super.key,
    required this.type,
    this.message,
    this.onRetry,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIcon(),
              const SizedBox(height: 24),
              _buildTitle(),
              const SizedBox(height: 12),
              _buildMessage(),
              const SizedBox(height: 32),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final (icon, color) = switch (type) {
      ErrorType.rootDenied => (Icons.lock_outline, AndrodartTheme.warningColor),
      ErrorType.sdkMissing => (Icons.download, AndrodartTheme.primaryColor),
      ErrorType.buildFailed => (Icons.error_outline, AndrodartTheme.errorColor),
      ErrorType.network => (Icons.wifi_off, AndrodartTheme.warningColor),
      ErrorType.diskSpace => (Icons.storage, AndrodartTheme.errorColor),
      ErrorType.unknown => (Icons.help_outline, AndrodartTheme.textMuted),
    };

    return Icon(icon, size: 80, color: color);
  }

  Widget _buildTitle() {
    final title = switch (type) {
      ErrorType.rootDenied => 'Root Access Denied',
      ErrorType.sdkMissing => 'SDK Not Installed',
      ErrorType.buildFailed => 'Build Failed',
      ErrorType.network => 'Network Error',
      ErrorType.diskSpace => 'Insufficient Storage',
      ErrorType.unknown => 'Something Went Wrong',
    };

    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AndrodartTheme.textPrimary,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMessage() {
    final defaultMessage = switch (type) {
      ErrorType.rootDenied =>
        'Root access is required for some features. Please grant root permission or use the app without root.',
      ErrorType.sdkMissing =>
        'Flutter SDK is not installed. Please run the SDK setup wizard to install required tools.',
      ErrorType.buildFailed =>
        'The build process failed. Check the build output for details.',
      ErrorType.network =>
        'Unable to connect to the network. Please check your internet connection.',
      ErrorType.diskSpace =>
        'Not enough storage space. Please free up some space and try again.',
      ErrorType.unknown =>
        'An unexpected error occurred. Please try again or report this issue.',
    };

    return Text(
      message ?? defaultMessage,
      style: const TextStyle(
        fontSize: 14,
        color: AndrodartTheme.textSecondary,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        if (onRetry != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onRetry,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Retry'),
              ),
            ),
          ),
        if (onSettings != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onSettings,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Settings'),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Go Back'),
        ),
      ],
    );
  }
}
