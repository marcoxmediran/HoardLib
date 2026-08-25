import 'package:flutter_test/flutter_test.dart';
import 'package:hoardlib/core/utils/formatters.dart';
import 'package:hoardlib/models/album.dart';
import 'package:hoardlib/models/artist.dart';
import 'package:hoardlib/models/scan_summary.dart';
import 'package:hoardlib/models/track.dart';

void main() {
  group('Formatters Unit Tests', () {
    test('formatDuration handles hours, minutes, and seconds', () {
      expect(Formatters.formatDuration(null), '0:00');
      expect(Formatters.formatDuration(Duration.zero), '0:00');
      expect(Formatters.formatDuration(const Duration(seconds: 45)), '0:45');
      expect(
        Formatters.formatDuration(const Duration(minutes: 3, seconds: 24)),
        '3:24',
      );
      expect(
        Formatters.formatDuration(
          const Duration(hours: 1, minutes: 12, seconds: 5),
        ),
        '1:12:05',
      );
    });

    test('formatBytes formats bytes to human readable string', () {
      expect(Formatters.formatBytes(0), '0 B');
      expect(Formatters.formatBytes(1024), '1.0 KB');
      expect(Formatters.formatBytes(5242880), '5.0 MB');
      expect(Formatters.formatBytes(1073741824), '1.0 GB');
    });

    test('formatTrackNumber pads 2 digits', () {
      expect(Formatters.formatTrackNumber(null), '');
      expect(Formatters.formatTrackNumber(1), '01');
      expect(Formatters.formatTrackNumber(12), '12');
    });
  });

  group('Models Serialization Tests', () {
    test('Track model json parsing and serialization', () {
      final json = {
        'id': 1,
        'title': 'Pump Up the Love',
        'trackNumber': 1,
        'fileSizeBytes': 5242880,
        'extension': 'mp3',
        'streamUrl': '/api/tracks/1/stream',
      };

      final track = Track.fromJson(json);
      expect(track.id, 1);
      expect(track.title, 'Pump Up the Love');
      expect(track.trackNumber, 1);
      expect(track.fileSizeBytes, 5242880);
      expect(track.extension, 'mp3');
      expect(track.streamUrl, '/api/tracks/1/stream');

      final serialized = track.toJson();
      expect(serialized['id'], 1);
      expect(serialized['title'], 'Pump Up the Love');
    });

    test('Album model json parsing with nested tracks', () {
      final json = {
        'id': 10,
        'title': 'Memories of Tokyo-To',
        'year': 2018,
        'listened': false,
        'hasCover': true,
        'coverUrl': '/api/albums/10/cover',
        'downloadUrl': '/api/albums/10/download',
        'artistName': '2 Mello',
        'artistId': 5,
        'tracks': [
          {
            'id': 101,
            'title': 'Track One',
            'trackNumber': 1,
            'fileSizeBytes': 3000000,
            'extension': 'mp3',
            'streamUrl': '/api/tracks/101/stream',
          },
          {
            'id': 102,
            'title': 'Track Two',
            'trackNumber': 2,
            'fileSizeBytes': 4000000,
            'extension': 'flac',
            'streamUrl': '/api/tracks/102/stream',
          },
        ],
      };

      final album = Album.fromJson(json);
      expect(album.id, 10);
      expect(album.title, 'Memories of Tokyo-To');
      expect(album.year, 2018);
      expect(album.listened, isFalse);
      expect(album.hasCover, isTrue);
      expect(album.tracks.length, 2);
      expect(album.totalSizeBytes, 7000000);
      expect(album.tracks[0].title, 'Track One');
      expect(album.tracks[1].extension, 'flac');
    });

    test('Artist model json parsing with albums', () {
      final json = {
        'id': 5,
        'name': '2 Mello',
        'albums': [
          {
            'id': 10,
            'title': 'Memories of Tokyo-To',
            'year': 2018,
            'listened': true,
            'hasCover': true,
            'coverUrl': '/api/albums/10/cover',
            'downloadUrl': '/api/albums/10/download',
            'artistName': '2 Mello',
            'artistId': 5,
            'tracks': [],
          },
        ],
      };

      final artist = Artist.fromJson(json);
      expect(artist.id, 5);
      expect(artist.name, '2 Mello');
      expect(artist.albums.length, 1);
      expect(artist.albums.first.listened, isTrue);
    });

    test('ScanSummary model json parsing', () {
      final json = {
        'artistsScanned': 120,
        'albumsScanned': 340,
        'tracksScanned': 4120,
        'durationMs': 1450,
        'status': 'SUCCESS',
      };

      final summary = ScanSummary.fromJson(json);
      expect(summary.artistsScanned, 120);
      expect(summary.albumsScanned, 340);
      expect(summary.tracksScanned, 4120);
      expect(summary.durationMs, 1450);
      expect(summary.status, 'SUCCESS');
    });
  });
}
