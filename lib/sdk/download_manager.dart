import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

class DownloadProgress {
  final double progress;
  final int bytesReceived;
  final int totalBytes;
  final String message;

  const DownloadProgress({
    required this.progress,
    required this.bytesReceived,
    required this.totalBytes,
    required this.message,
  });

  bool get isComplete => progress >= 1.0;
}

class DownloadManager {
  final http.Client _client;
  final Map<String, bool> _activeDownloads = {};

  DownloadManager({http.Client? client}) : _client = client ?? http.Client();

  bool isDownloading(String url) => _activeDownloads[url] == true;

  Future<File> download({
    required String url,
    required String savePath,
    Function(DownloadProgress)? onProgress,
  }) async {
    if (_activeDownloads[url] == true) {
      throw StateError('Download already in progress');
    }

    _activeDownloads[url] = true;

    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await _client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Download failed: ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      int bytesReceived = 0;

      final file = File(savePath);
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        bytesReceived += chunk.length;

        final progress = contentLength > 0 ? bytesReceived / contentLength : 0.0;
        onProgress?.call(DownloadProgress(
          progress: progress,
          bytesReceived: bytesReceived,
          totalBytes: contentLength,
          message: _formatBytes(bytesReceived),
        ));
      }

      await sink.close();

      onProgress?.call(DownloadProgress(
        progress: 1.0,
        bytesReceived: bytesReceived,
        totalBytes: contentLength,
        message: 'Complete',
      ));

      return file;
    } finally {
      _activeDownloads.remove(url);
    }
  }

  Future<void> downloadToFile({
    required String url,
    required File file,
    Function(DownloadProgress)? onProgress,
  }) async {
    await download(url: url, savePath: file.path, onProgress: onProgress);
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void cancelAll() {
    _client.close();
  }
}
