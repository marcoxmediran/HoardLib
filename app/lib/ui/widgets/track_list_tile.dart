import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoardlib/core/utils/formatters.dart';
import 'package:hoardlib/models/album.dart';
import 'package:hoardlib/models/track.dart';
import 'package:hoardlib/providers/audio_provider.dart';

class TrackListTile extends ConsumerWidget {
  final Track track;
  final Album album;
  final int index;

  const TrackListTile({
    super.key,
    required this.track,
    required this.album,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentAlbum = ref.watch(currentAlbumProvider);
    final playerStateAsync = ref.watch(playerStateStreamProvider);
    final currentIndexAsync = ref.watch(playerIndexStreamProvider);

    final isThisAlbum = currentAlbum?.id == album.id;
    final isPlayingThisTrack =
        isThisAlbum &&
        currentIndexAsync.valueOrNull == index &&
        (playerStateAsync.valueOrNull?.playing ?? false);
    final isCurrentTrack =
        isThisAlbum && currentIndexAsync.valueOrNull == index;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: SizedBox(
        width: 32,
        child: Center(
          child: isPlayingThisTrack
              ? Icon(
                  Icons.graphic_eq_rounded,
                  color: theme.colorScheme.primary,
                  size: 22,
                )
              : isCurrentTrack
              ? Icon(
                  Icons.pause_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                )
              : Text(
                  Formatters.formatTrackNumber(track.trackNumber ?? index + 1),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
        ),
      ),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: isCurrentTrack ? FontWeight.bold : FontWeight.w500,
          color: isCurrentTrack
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              track.extension.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            Formatters.formatBytes(track.fileSizeBytes),
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (track.localFilePath != null) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.download_done_rounded,
              size: 14,
              color: theme.colorScheme.primary,
            ),
          ],
        ],
      ),
      trailing: IconButton(
        icon: Icon(
          isPlayingThisTrack
              ? Icons.pause_circle_filled_rounded
              : Icons.play_circle_fill_rounded,
          color: theme.colorScheme.primary,
          size: 28,
        ),
        onPressed: () {
          if (isPlayingThisTrack) {
            ref.read(audioControllerProvider).pause();
          } else {
            ref.read(audioControllerProvider).playTrack(track, album);
          }
        },
      ),
      onTap: () {
        ref.read(audioControllerProvider).playTrack(track, album);
      },
    );
  }
}
