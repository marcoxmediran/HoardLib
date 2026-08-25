import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:hoardlib/models/album.dart';
import 'package:hoardlib/models/track.dart';
import 'package:hoardlib/services/audio_player_service.dart';
import 'package:hoardlib/providers/settings_provider.dart';

final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService();
  ref.onDispose(() => service.dispose());
  return service;
});

// Playback state stream
final playerStateStreamProvider = StreamProvider.autoDispose<PlayerState>((
  ref,
) {
  final playerService = ref.watch(audioPlayerServiceProvider);
  return playerService.playerStateStream;
});

// Playback position stream
final playerPositionStreamProvider = StreamProvider.autoDispose<Duration>((
  ref,
) {
  final playerService = ref.watch(audioPlayerServiceProvider);
  return playerService.positionStream;
});

// Playback duration stream
final playerDurationStreamProvider = StreamProvider.autoDispose<Duration?>((
  ref,
) {
  final playerService = ref.watch(audioPlayerServiceProvider);
  return playerService.durationStream;
});

// Buffered position stream
final playerBufferedPositionStreamProvider =
    StreamProvider.autoDispose<Duration>((ref) {
      final playerService = ref.watch(audioPlayerServiceProvider);
      return playerService.bufferedPositionStream;
    });

// Current playing track index stream
final playerIndexStreamProvider = StreamProvider.autoDispose<int?>((ref) {
  final playerService = ref.watch(audioPlayerServiceProvider);
  return playerService.currentIndexStream;
});

// Current Album State
class CurrentAlbumNotifier extends StateNotifier<Album?> {
  CurrentAlbumNotifier() : super(null);

  void setAlbum(Album album) {
    state = album;
  }
}

final currentAlbumProvider =
    StateNotifierProvider<CurrentAlbumNotifier, Album?>((ref) {
      return CurrentAlbumNotifier();
    });

// Helper provider to play an album or track easily
class AudioController {
  final AudioPlayerService _service;
  final Ref _ref;

  AudioController(this._service, this._ref);

  Future<void> playAlbum(Album album, {int initialIndex = 0}) async {
    final apiClient = _ref.read(apiClientProvider);
    _ref.read(currentAlbumProvider.notifier).setAlbum(album);
    await _service.playAlbum(
      album: album,
      initialIndex: initialIndex,
      apiClient: apiClient,
    );
  }

  Future<void> playTrack(Track track, Album album) async {
    final apiClient = _ref.read(apiClientProvider);
    _ref.read(currentAlbumProvider.notifier).setAlbum(album);
    await _service.playTrack(track: track, album: album, apiClient: apiClient);
  }

  Future<void> play() => _service.play();
  Future<void> pause() => _service.pause();
  Future<void> seek(Duration position) => _service.seek(position);
  Future<void> seekToNext() => _service.seekToNext();
  Future<void> seekToPrevious() => _service.seekToPrevious();
  Future<void> setLoopMode(LoopMode mode) => _service.setLoopMode(mode);
  Future<void> setShuffleMode(bool enabled) =>
      _service.setShuffleModeEnabled(enabled);
}

final audioControllerProvider = Provider<AudioController>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return AudioController(service, ref);
});
