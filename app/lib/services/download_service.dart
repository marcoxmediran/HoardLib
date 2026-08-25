import 'dart:io';
import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hoardlib/core/network/api_client.dart';
import 'package:hoardlib/models/album.dart';
import 'package:hoardlib/models/download_item.dart';
import 'package:hoardlib/services/storage_service.dart';

class DownloadService {
  final StorageService _storageService;
  final Dio _downloadDio = Dio();

  DownloadService(this._storageService);

  Future<String> _getAlbumsDirectoryPath() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final albumsDir = Directory('${appDocDir.path}/hoardlib/albums');
    if (!await albumsDir.exists()) {
      await albumsDir.create(recursive: true);
    }
    return albumsDir.path;
  }

  Future<void> downloadAndExtractAlbum({
    required Album album,
    required ApiClient apiClient,
    required void Function(DownloadItem item) onProgress,
  }) async {
    DownloadItem currentItem = DownloadItem(
      album: album,
      status: DownloadStatus.downloading,
      progress: 0.0,
    );
    onProgress(currentItem);

    final basePath = await _getAlbumsDirectoryPath();
    final albumDir = Directory('$basePath/${album.id}');
    if (!await albumDir.exists()) {
      await albumDir.create(recursive: true);
    }

    final tempZipFile = File('${albumDir.path}/temp_album.zip');

    try {
      final downloadUrl = apiClient.resolveUrl(album.downloadUrl);

      await _downloadDio.download(
        downloadUrl,
        tempZipFile.path,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = received / total;
            currentItem = currentItem.copyWith(
              progress: progress.clamp(0.0, 0.95),
            );
            onProgress(currentItem);
          }
        },
      );

      // Extraction phase
      currentItem = currentItem.copyWith(
        status: DownloadStatus.extracting,
        progress: 0.96,
      );
      onProgress(currentItem);

      final bytes = await tempZipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      String? localCoverPath;
      final extractedFiles = <String, String>{}; // filename -> absolutePath

      final tracksSubdir = Directory('${albumDir.path}/tracks');
      if (!await tracksSubdir.exists()) {
        await tracksSubdir.create(recursive: true);
      }

      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          if (filename.toLowerCase().endsWith('cover.jpg') ||
              filename.toLowerCase().endsWith('cover.jpeg') ||
              filename.toLowerCase().endsWith('cover.png')) {
            final coverFile = File('${albumDir.path}/cover.jpg');
            await coverFile.writeAsBytes(data, flush: true);
            localCoverPath = coverFile.path;
          } else {
            // Audio track file
            final trackFile = File('${tracksSubdir.path}/$filename');
            await trackFile.writeAsBytes(data, flush: true);
            extractedFiles[filename.toLowerCase()] = trackFile.path;
          }
        }
      }

      // Delete temporary zip
      if (await tempZipFile.exists()) {
        await tempZipFile.delete();
      }

      // Map local paths back to tracks
      final updatedTracks = album.tracks.map((track) {
        String? matchedPath;
        // Search by title or track number
        for (final entry in extractedFiles.entries) {
          final fname = entry.key;
          final sanitizedTitle = track.title.toLowerCase().replaceAll(
            RegExp(r'[^a-z0-9]'),
            '',
          );
          final sanitizedFname = fname.replaceAll(RegExp(r'[^a-z0-9]'), '');

          if (sanitizedFname.contains(sanitizedTitle) ||
              (track.trackNumber != null &&
                  fname.startsWith(
                    track.trackNumber.toString().padLeft(2, '0'),
                  ))) {
            matchedPath = entry.value;
            break;
          }
        }
        // Fallback: match by index if tracks order matches
        if (matchedPath == null && extractedFiles.isNotEmpty) {
          final values = extractedFiles.values.toList()..sort();
          final idx =
              track.trackNumber != null &&
                  track.trackNumber! - 1 < values.length &&
                  track.trackNumber! - 1 >= 0
              ? track.trackNumber! - 1
              : 0;
          if (idx < values.length) {
            matchedPath = values[idx];
          }
        }

        return track.copyWith(localFilePath: matchedPath);
      }).toList();

      final updatedAlbum = album.copyWith(
        isDownloaded: true,
        localCoverPath: localCoverPath,
        tracks: updatedTracks,
      );

      await _storageService.addDownloadedAlbum(updatedAlbum);

      currentItem = currentItem.copyWith(
        album: updatedAlbum,
        status: DownloadStatus.completed,
        progress: 1.0,
        completedAt: DateTime.now(),
      );
      onProgress(currentItem);
    } catch (e) {
      if (await tempZipFile.exists()) {
        await tempZipFile.delete();
      }
      currentItem = currentItem.copyWith(
        status: DownloadStatus.failed,
        errorMessage: e.toString(),
      );
      onProgress(currentItem);
    }
  }

  Future<void> deleteDownloadedAlbum(int albumId) async {
    final basePath = await _getAlbumsDirectoryPath();
    final albumDir = Directory('$basePath/$albumId');
    if (await albumDir.exists()) {
      await albumDir.delete(recursive: true);
    }
    await _storageService.removeDownloadedAlbum(albumId);
  }

  Future<int> getTotalStorageUsageBytes() async {
    final basePath = await _getAlbumsDirectoryPath();
    final dir = Directory(basePath);
    if (!await dir.exists()) return 0;

    var totalBytes = 0;
    try {
      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          totalBytes += await entity.length();
        }
      }
    } catch (_) {}
    return totalBytes;
  }
}
