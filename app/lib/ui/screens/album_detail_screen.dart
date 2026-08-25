import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoardlib/core/utils/formatters.dart';
import 'package:hoardlib/models/album.dart';
import 'package:hoardlib/models/download_item.dart';
import 'package:hoardlib/providers/audio_provider.dart';
import 'package:hoardlib/providers/downloads_provider.dart';
import 'package:hoardlib/providers/library_provider.dart';
import 'package:hoardlib/providers/settings_provider.dart';
import 'package:hoardlib/ui/widgets/track_list_tile.dart';
import 'package:hoardlib/ui/screens/artist_detail_screen.dart';

class AlbumDetailScreen extends ConsumerWidget {
  final int albumId;
  final Album? initialAlbum;

  const AlbumDetailScreen({
    super.key,
    required this.albumId,
    this.initialAlbum,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final apiClient = ref.watch(apiClientProvider);
    final albumAsync = ref.watch(albumDetailProvider(albumId));
    final activeDownloads = ref.watch(activeDownloadsProvider);
    final isDownloaded = ref
        .watch(downloadedAlbumsProvider.notifier)
        .isAlbumDownloaded(albumId);
    final downloadItem = activeDownloads[albumId];

    final album = albumAsync.valueOrNull ?? initialAlbum;

    if (album == null && albumAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (album == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              const Text('Album not found'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(albumDetailProvider(albumId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    Widget buildCoverArt() {
      if (album.localCoverPath != null &&
          File(album.localCoverPath!).existsSync()) {
        return Image.file(File(album.localCoverPath!), fit: BoxFit.cover);
      }
      if (album.hasCover && album.coverUrl.isNotEmpty) {
        return CachedNetworkImage(
          imageUrl: apiClient.resolveUrl(album.coverUrl),
          fit: BoxFit.cover,
          placeholder: (context, url) =>
              Container(color: theme.colorScheme.surfaceContainerHighest),
          errorWidget: (context, url, error) => Container(
            color: theme.colorScheme.surfaceContainerHighest,
            child: const Icon(Icons.album_rounded, size: 80),
          ),
        );
      }
      return Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.album_rounded, size: 80),
      );
    }

    final isDownloading =
        downloadItem != null &&
        downloadItem.status == DownloadStatus.downloading;
    final isExtracting =
        downloadItem != null &&
        downloadItem.status == DownloadStatus.extracting;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  buildCoverArt(),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.2),
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          album.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ArtistDetailScreen(
                                  artistId: album.artistId,
                                  artistName: album.artistName,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            album.artistName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Metadata Bar
                  Row(
                    children: [
                      if (album.year != null) ...[
                        Text(
                          '${album.year}',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          ' • ',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      Text(
                        '${album.tracks.length} tracks',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        ' • ',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        Formatters.formatBytes(album.totalSizeBytes),
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      // Listened chip
                      FilterChip(
                        selected: album.listened,
                        label: Text(
                          album.listened ? 'Listened' : 'Mark as Listened',
                        ),
                        avatar: Icon(
                          album.listened
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked,
                          color: album.listened ? Colors.green : null,
                          size: 18,
                        ),
                        onSelected: (val) async {
                          await ref
                              .read(libraryNotifierProvider.notifier)
                              .toggleListened(album.id);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Action Buttons (Play All, Shuffle, Download Zip)
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: album.tracks.isEmpty
                              ? null
                              : () {
                                  ref
                                      .read(audioControllerProvider)
                                      .playAlbum(album);
                                },
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Play Album'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isDownloading || isExtracting) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  value: isDownloading
                                      ? downloadItem.progress
                                      : null,
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isDownloading
                                    ? '${(downloadItem.progress * 100).toInt()}%'
                                    : 'Extracting...',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ] else if (isDownloaded) ...[
                        IconButton.filledTonal(
                          icon: const Icon(
                            Icons.download_done_rounded,
                            color: Colors.green,
                          ),
                          tooltip: 'Downloaded (Tap to remove)',
                          onPressed: () {
                            ref
                                .read(downloadedAlbumsProvider.notifier)
                                .deleteDownload(album.id);
                          },
                        ),
                      ] else ...[
                        IconButton.filledTonal(
                          icon: const Icon(Icons.download_rounded),
                          tooltip: 'Download Album Zip',
                          onPressed: () {
                            ref
                                .read(downloadedAlbumsProvider.notifier)
                                .startDownload(album);
                          },
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'TRACKS',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final track = album.tracks[index];
              return TrackListTile(track: track, album: album, index: index);
            }, childCount: album.tracks.length),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 80), // Mini player padding
          ),
        ],
      ),
    );
  }
}
