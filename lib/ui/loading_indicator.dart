import 'package:flutter/material.dart';
import '../ui/theme.dart';

class LoadingIndicator extends StatelessWidget {
  final String message;
  final double? progress;

  const LoadingIndicator({
    super.key,
    this.message = 'Loading...',
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (progress != null) ...[
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4,
                    backgroundColor: AndrodartTheme.surfaceColor,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AndrodartTheme.primaryColor,
                    ),
                  ),
                  Text(
                    '${(progress! * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AndrodartTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ] else
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AndrodartTheme.primaryColor,
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: AndrodartTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final String message;
  final double? progress;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    this.message = 'Loading...',
    this.progress,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black54,
            child: LoadingIndicator(
              message: message,
              progress: progress,
            ),
          ),
      ],
    );
  }
}
