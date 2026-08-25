import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoardlib/providers/audio_provider.dart';
import 'package:hoardlib/providers/settings_provider.dart';
import 'package:hoardlib/ui/screens/player_screen.dart';

class MiniPlayerDock extends ConsumerWidget {
  const MiniPlayerDock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final apiClient = ref.watch(apiClientProvider);
    final audioPlayerService = ref.watch(audioPlayerServiceProvider);
    final currentAlbum = ref.watch(currentAlbumProvider);
    final playerStateAsync = ref.watch(playerStateStreamProvider);
    final positionAsync = ref.watch(playerPositionStreamProvider);
    final durationAsync = ref.watch(playerDurationStreamProvider);
    final currentIndexAsync = ref.watch(playerIndexStreamProvider);

    final currentIndex = currentIndexAsync.valueOrNull ?? 0;
    final playlist = audioPlayerService.currentPlaylist;

    if (currentAlbum == null || playlist.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentTrack = (currentIndex >= 0 && currentIndex < playlist.length)
        ? playlist[currentIndex]
        : null;

    final isPlaying = playerStateAsync.valueOrNull?.playing ?? false;
    final position = positionAsync.valueOrNull ?? Duration.zero;
    final duration = durationAsync.valueOrNull ?? Duration.zero;
    final progress = (duration.inMilliseconds > 0)
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    Widget buildCoverThumbnail() {
      if (currentAlbum.localCoverPath != null &&
          File(currentAlbum.localCoverPath!).existsSync()) {
        return Image.file(
          File(currentAlbum.localCoverPath!),
          fit: BoxFit.cover,
        );
      }
      if (currentAlbum.hasCover && currentAlbum.coverUrl.isNotEmpty) {
        return CachedNetworkImage(
          imageUrl: apiClient.resolveUrl(currentAlbum.coverUrl),
          fit: BoxFit.cover,
          placeholder: (context, url) =>
              Container(color: theme.colorScheme.surfaceContainerHighest),
          errorWidget: (context, url, error) => Container(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.music_note_rounded,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }
      return Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.music_note_rounded,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              backgroundColor: theme.scaffoldBackgroundColor,
              builder: (context) => const PlayerScreen(),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 46,
                        height: 46,
                        child: buildCoverThumbnail(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currentTrack?.title ?? currentAlbum.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentAlbum.artistName,
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
                    IconButton(
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 30,
                      ),
                      color: theme.colorScheme.primary,
                      onPressed: () {
                        if (isPlaying) {
                          ref.read(audioControllerProvider).pause();
                        } else {
                          ref.read(audioControllerProvider).play();
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded, size: 28),
                      color: theme.colorScheme.onSurface,
                      onPressed: () {
                        ref.read(audioControllerProvider).seekToNext();
                      },
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 2.5,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
