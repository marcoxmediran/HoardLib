import 'package:hoardlib/models/album.dart';

enum DownloadStatus { idle, downloading, extracting, completed, failed }

class DownloadItem {
  final Album album;
  final DownloadStatus status;
  final double progress; // 0.0 to 1.0
  final String? errorMessage;
  final DateTime? completedAt;

  const DownloadItem({
    required this.album,
    this.status = DownloadStatus.idle,
    this.progress = 0.0,
    this.errorMessage,
    this.completedAt,
  });

  DownloadItem copyWith({
    Album? album,
    DownloadStatus? status,
    double? progress,
    String? errorMessage,
    DateTime? completedAt,
  }) {
    return DownloadItem(
      album: album ?? this.album,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
