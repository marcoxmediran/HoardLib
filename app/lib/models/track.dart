class Track {
  final int id;
  final String title;
  final int? trackNumber;
  final int fileSizeBytes;
  final String extension;
  final String streamUrl;
  final String? localFilePath;

  const Track({
    required this.id,
    required this.title,
    this.trackNumber,
    required this.fileSizeBytes,
    required this.extension,
    required this.streamUrl,
    this.localFilePath,
  });

  Track copyWith({
    int? id,
    String? title,
    int? trackNumber,
    int? fileSizeBytes,
    String? extension,
    String? streamUrl,
    String? localFilePath,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      trackNumber: trackNumber ?? this.trackNumber,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      extension: extension ?? this.extension,
      streamUrl: streamUrl ?? this.streamUrl,
      localFilePath: localFilePath ?? this.localFilePath,
    );
  }

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'Untitled Track',
      trackNumber: json['trackNumber'] as int?,
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      extension: json['extension'] as String? ?? 'mp3',
      streamUrl: json['streamUrl'] as String? ?? '',
      localFilePath: json['localFilePath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'trackNumber': trackNumber,
      'fileSizeBytes': fileSizeBytes,
      'extension': extension,
      'streamUrl': streamUrl,
      'localFilePath': localFilePath,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Track && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
