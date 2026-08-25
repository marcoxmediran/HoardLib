import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:hoardlib/core/utils/formatters.dart';
import 'package:hoardlib/models/album.dart';
import 'package:hoardlib/models/track.dart';
import 'package:hoardlib/providers/audio_provider.dart';
import 'package:hoardlib/providers/library_provider.dart';
import 'package:hoardlib/providers/settings_provider.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

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
    final currentTrack = (currentIndex >= 0 && currentIndex < playlist.length)
        ? playlist[currentIndex]
        : null;

    final isPlaying = playerStateAsync.valueOrNull?.playing ?? false;
    final processingState = playerStateAsync.valueOrNull?.processingState;
    final isBuffering =
        processingState == ProcessingState.buffering ||
        processingState == ProcessingState.loading;

    final position = positionAsync.valueOrNull ?? Duration.zero;
    final duration = durationAsync.valueOrNull ?? Duration.zero;

    Widget buildCoverArt() {
      final localCover = currentAlbum?.localCoverPath;
      if (localCover != null && File(localCover).existsSync()) {
        return Image.file(File(localCover), fit: BoxFit.cover);
      }
      if (currentAlbum != null &&
          currentAlbum.hasCover &&
          currentAlbum.coverUrl.isNotEmpty) {
        return CachedNetworkImage(
          imageUrl: apiClient.resolveUrl(currentAlbum.coverUrl),
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: theme.colorScheme.surfaceContainerHighest,
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.music_note_rounded,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }
      return Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.music_note_rounded,
          size: 80,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'PLAYING FROM ALBUM',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              currentAlbum?.title ?? 'HoardLib',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (currentAlbum != null)
            IconButton(
              icon: Icon(
                currentAlbum.listened
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: currentAlbum.listened ? Colors.green : null,
              ),
              tooltip: currentAlbum.listened
                  ? 'Mark as Unlistened'
                  : 'Mark as Listened',
              onPressed: () async {
                final updated = await ref
                    .read(libraryNotifierProvider.notifier)
                    .toggleListened(currentAlbum.id);
                if (updated != null) {
                  ref.read(currentAlbumProvider.notifier).setAlbum(updated);
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.queue_music_rounded),
            tooltip: 'Queue',
            onPressed: () {
              _showQueueBottomSheet(
                context,
                ref,
                playlist,
                currentIndex,
                currentAlbum,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              const Spacer(flex: 1),
              // Album Art
              Center(
                child: Hero(
                  tag: 'current_playing_art',
                  child: Container(
                    constraints: const BoxConstraints(
                      maxHeight: 320,
                      maxWidth: 320,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: buildCoverArt(),
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 2),
              // Track Info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentTrack?.title ?? 'No Track Selected',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${currentAlbum?.artistName ?? 'Unknown Artist'}${currentAlbum?.year != null ? ' • ${currentAlbum!.year}' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Seek Slider
              Column(
                children: [
                  Slider(
                    value: position.inMilliseconds.toDouble().clamp(
                      0.0,
                      duration.inMilliseconds.toDouble() > 0
                          ? duration.inMilliseconds.toDouble()
                          : 0.0,
                    ),
                    max: duration.inMilliseconds.toDouble() > 0
                        ? duration.inMilliseconds.toDouble()
                        : 1.0,
                    onChanged: (val) {
                      ref
                          .read(audioControllerProvider)
                          .seek(Duration(milliseconds: val.toInt()));
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Formatters.formatDuration(position),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          Formatters.formatDuration(duration),
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
              const SizedBox(height: 12),
              // Playback Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StreamBuilder<bool>(
                    stream: audioPlayerService.shuffleModeEnabledStream,
                    builder: (context, snapshot) {
                      final shuffleEnabled = snapshot.data ?? false;
                      return IconButton(
                        icon: Icon(
                          Icons.shuffle_rounded,
                          color: shuffleEnabled
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                        ),
                        onPressed: () {
                          ref
                              .read(audioControllerProvider)
                              .setShuffleMode(!shuffleEnabled);
                        },
                      );
                    },
                  ),
                  IconButton(
                    iconSize: 38,
                    icon: const Icon(Icons.skip_previous_rounded),
                    onPressed: () {
                      ref.read(audioControllerProvider).seekToPrevious();
                    },
                  ),
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary,
                    ),
                    child: isBuffering
                        ? Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                color: theme.colorScheme.onPrimary,
                                strokeWidth: 3,
                              ),
                            ),
                          )
                        : IconButton(
                            iconSize: 36,
                            icon: Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: theme.colorScheme.onPrimary,
                            ),
                            onPressed: () {
                              if (isPlaying) {
                                ref.read(audioControllerProvider).pause();
                              } else {
                                ref.read(audioControllerProvider).play();
                              }
                            },
                          ),
                  ),
                  IconButton(
                    iconSize: 38,
                    icon: const Icon(Icons.skip_next_rounded),
                    onPressed: () {
                      ref.read(audioControllerProvider).seekToNext();
                    },
                  ),
                  StreamBuilder<LoopMode>(
                    stream: audioPlayerService.loopModeStream,
                    builder: (context, snapshot) {
                      final loopMode = snapshot.data ?? LoopMode.off;
                      IconData loopIcon = Icons.repeat_rounded;
                      Color loopColor = theme.colorScheme.outline;
                      if (loopMode == LoopMode.one) {
                        loopIcon = Icons.repeat_one_rounded;
                        loopColor = theme.colorScheme.primary;
                      } else if (loopMode == LoopMode.all) {
                        loopIcon = Icons.repeat_rounded;
                        loopColor = theme.colorScheme.primary;
                      }
                      return IconButton(
                        icon: Icon(loopIcon, color: loopColor),
                        onPressed: () {
                          final nextMode = loopMode == LoopMode.off
                              ? LoopMode.all
                              : (loopMode == LoopMode.all
                                    ? LoopMode.one
                                    : LoopMode.off);
                          ref
                              .read(audioControllerProvider)
                              .setLoopMode(nextMode);
                        },
                      );
                    },
                  ),
                ],
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  void _showQueueBottomSheet(
    BuildContext context,
    WidgetRef ref,
    List<Track> playlist,
    int currentIndex,
    Album? album,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Text(
                    'Playing Queue (${playlist.length} tracks)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: playlist.length,
                    itemBuilder: (context, index) {
                      final track = playlist[index];
                      final isCurrent = index == currentIndex;
                      return ListTile(
                        leading: isCurrent
                            ? const Icon(
                                Icons.graphic_eq_rounded,
                                color: Colors.purpleAccent,
                              )
                            : Text('${index + 1}'),
                        title: Text(
                          track.title,
                          style: TextStyle(
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(track.extension.toUpperCase()),
                        onTap: () {
                          if (album != null) {
                            ref
                                .read(audioControllerProvider)
                                .playTrack(track, album);
                            Navigator.pop(context);
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
