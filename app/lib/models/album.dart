import 'package:hoardlib/models/track.dart';

class Album {
  final int id;
  final String title;
  final int? year;
  final bool listened;
  final bool hasCover;
  final String coverUrl;
  final String downloadUrl;
  final String artistName;
  final int artistId;
  final List<Track> tracks;
  final String? localCoverPath;
  final bool isDownloaded;

  const Album({
    required this.id,
    required this.title,
    this.year,
    required this.listened,
    required this.hasCover,
    required this.coverUrl,
    required this.downloadUrl,
    required this.artistName,
    required this.artistId,
    this.tracks = const [],
    this.localCoverPath,
    this.isDownloaded = false,
  });

  int get totalSizeBytes =>
      tracks.fold(0, (sum, track) => sum + track.fileSizeBytes);

  Album copyWith({
    int? id,
    String? title,
    int? year,
    bool? listened,
    bool? hasCover,
    String? coverUrl,
    String? downloadUrl,
    String? artistName,
    int? artistId,
    List<Track>? tracks,
    String? localCoverPath,
    bool? isDownloaded,
  }) {
    return Album(
      id: id ?? this.id,
      title: title ?? this.title,
      year: year ?? this.year,
      listened: listened ?? this.listened,
      hasCover: hasCover ?? this.hasCover,
      coverUrl: coverUrl ?? this.coverUrl,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      artistName: artistName ?? this.artistName,
      artistId: artistId ?? this.artistId,
      tracks: tracks ?? this.tracks,
      localCoverPath: localCoverPath ?? this.localCoverPath,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }

  factory Album.fromJson(Map<String, dynamic> json) {
    var rawTracks = json['tracks'];
    List<Track> parsedTracks = [];
    if (rawTracks is List) {
      parsedTracks = rawTracks
          .map((t) => Track.fromJson(t as Map<String, dynamic>))
          .toList();
    }

    return Album(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'Untitled Album',
      year: json['year'] as int?,
      listened: json['listened'] as bool? ?? false,
      hasCover: json['hasCover'] as bool? ?? false,
      coverUrl: json['coverUrl'] as String? ?? '',
      downloadUrl: json['downloadUrl'] as String? ?? '',
      artistName: json['artistName'] as String? ?? 'Unknown Artist',
      artistId: (json['artistId'] as num?)?.toInt() ?? 0,
      tracks: parsedTracks,
      localCoverPath: json['localCoverPath'] as String?,
      isDownloaded: json['isDownloaded'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'year': year,
      'listened': listened,
      'hasCover': hasCover,
      'coverUrl': coverUrl,
      'downloadUrl': downloadUrl,
      'artistName': artistName,
      'artistId': artistId,
      'tracks': tracks.map((t) => t.toJson()).toList(),
      'localCoverPath': localCoverPath,
      'isDownloaded': isDownloaded,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Album && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
