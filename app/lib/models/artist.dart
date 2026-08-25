import 'package:hoardlib/models/album.dart';

class Artist {
  final int id;
  final String name;
  final List<Album> albums;

  const Artist({required this.id, required this.name, this.albums = const []});

  Artist copyWith({int? id, String? name, List<Album>? albums}) {
    return Artist(
      id: id ?? this.id,
      name: name ?? this.name,
      albums: albums ?? this.albums,
    );
  }

  factory Artist.fromJson(Map<String, dynamic> json) {
    var rawAlbums = json['albums'];
    List<Album> parsedAlbums = [];
    if (rawAlbums is List) {
      parsedAlbums = rawAlbums
          .map((a) => Album.fromJson(a as Map<String, dynamic>))
          .toList();
    }

    return Artist(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown Artist',
      albums: parsedAlbums,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'albums': albums.map((a) => a.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Artist && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
