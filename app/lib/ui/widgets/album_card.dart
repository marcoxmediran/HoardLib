import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoardlib/models/album.dart';
import 'package:hoardlib/models/download_item.dart';
import 'package:hoardlib/providers/audio_provider.dart';
import 'package:hoardlib/providers/downloads_provider.dart';
import 'package:hoardlib/providers/library_provider.dart';
import 'package:hoardlib/providers/settings_provider.dart';
import 'package:hoardlib/ui/screens/album_detail_screen.dart';

class AlbumCard extends ConsumerWidget {
  final Album album;
  final bool compact;

  const AlbumCard({super.key, required this.album, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiClient = ref.watch(apiClientProvider);
    final activeDownloads = ref.watch(activeDownloadsProvider);
    final isDownloaded = ref
        .watch(downloadedAlbumsProvider.notifier)
        .isAlbumDownloaded(album.id);
    final currentDownload = activeDownloads[album.id];
    final theme = Theme.of(context);

    Widget buildCoverArt() {
      if (album.localCoverPath != null &&
          File(album.localCoverPath!).existsSync()) {
        return Image.file(File(album.localCoverPath!), fit: BoxFit.cover);
      }
      if (album.hasCover && album.coverUrl.isNotEmpty) {
        return CachedNetworkImage(
          imageUrl: apiClient.resolveUrl(album.coverUrl),
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: theme.colorScheme.surfaceContainerHighest,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.album_rounded,
              size: compact ? 32 : 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }
      return Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.album_rounded,
            size: compact ? 32 : 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    if (compact) {
      // List Tile layout
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(width: 52, height: 52, child: buildCoverArt()),
          ),
          title: Text(
            album.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Row(
            children: [
              Expanded(
                child: Text(
                  '${album.artistName}${album.year != null ? ' • ${album.year}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (isDownloaded)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.download_done_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  album.listened
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: album.listened
                      ? Colors.green
                      : theme.colorScheme.outline,
                ),
                tooltip: album.listened
                    ? 'Mark as Unlistened'
                    : 'Mark as Listened',
                onPressed: () {
                  ref
                      .read(libraryNotifierProvider.notifier)
                      .toggleListened(album.id);
                },
              ),
              IconButton(
                icon: const Icon(Icons.play_circle_fill_rounded),
                iconSize: 34,
                color: theme.colorScheme.primary,
                onPressed: () {
                  ref.read(audioControllerProvider).playAlbum(album);
                },
              ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AlbumDetailScreen(albumId: album.id, initialAlbum: album),
              ),
            );
          },
        ),
      );
    }

    // Grid Card layout
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AlbumDetailScreen(albumId: album.id, initialAlbum: album),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: buildCoverArt(),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isDownloaded)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.download_done_rounded,
                              size: 12,
                              color: Colors.lightGreenAccent,
                            ),
                          ),
                        Icon(
                          album.listened ? Icons.check_circle : Icons.fiber_new,
                          size: 13,
                          color: album.listened
                              ? Colors.greenAccent
                              : Colors.orangeAccent,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          album.listened ? 'Listened' : 'Backlog',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (currentDownload != null &&
                    currentDownload.status == DownloadStatus.downloading)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: currentDownload.progress,
                      backgroundColor: Colors.black45,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${album.artistName}${album.year != null ? ' • ${album.year}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
