class ScanSummary {
  final int artistsScanned;
  final int albumsScanned;
  final int tracksScanned;
  final int durationMs;
  final String status;

  const ScanSummary({
    required this.artistsScanned,
    required this.albumsScanned,
    required this.tracksScanned,
    required this.durationMs,
    required this.status,
  });

  factory ScanSummary.fromJson(Map<String, dynamic> json) {
    return ScanSummary(
      artistsScanned: (json['artistsScanned'] as num?)?.toInt() ?? 0,
      albumsScanned: (json['albumsScanned'] as num?)?.toInt() ?? 0,
      tracksScanned: (json['tracksScanned'] as num?)?.toInt() ?? 0,
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'SUCCESS',
    );
  }
}
