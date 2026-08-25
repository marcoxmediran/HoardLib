import 'dart:io';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:hoardlib/core/network/api_client.dart';
import 'package:hoardlib/models/album.dart';
import 'package:hoardlib/models/track.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  Album? _currentAlbum;
  List<Track> _currentPlaylist = [];

  AudioPlayerService() {
    _initSession();
  }

  Future<void> _initSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  AudioPlayer get player => _player;
  Album? get currentAlbum => _currentAlbum;
  List<Track> get currentPlaylist => _currentPlaylist;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;
  Stream<SequenceState?> get sequenceStateStream => _player.sequenceStateStream;
  Stream<bool> get shuffleModeEnabledStream => _player.shuffleModeEnabledStream;
  Stream<LoopMode> get loopModeStream => _player.loopModeStream;

  Track? get currentTrack {
    final index = _player.currentIndex;
    if (index != null && index >= 0 && index < _currentPlaylist.length) {
      return _currentPlaylist[index];
    }
    return null;
  }

  Future<void> playAlbum({
    required Album album,
    int initialIndex = 0,
    required ApiClient apiClient,
  }) async {
    if (album.tracks.isEmpty) return;

    _currentAlbum = album;
    _currentPlaylist = List.from(album.tracks);

    final audioSources = <AudioSource>[];

    for (final track in album.tracks) {
      final mediaItem = MediaItem(
        id: track.id.toString(),
        album: album.title,
        title: track.title,
        artist: album.artistName,
        artUri:
            album.localCoverPath != null &&
                File(album.localCoverPath!).existsSync()
            ? Uri.file(album.localCoverPath!)
            : (album.hasCover
                  ? Uri.parse(apiClient.resolveUrl(album.coverUrl))
                  : null),
      );

      if (track.localFilePath != null &&
          File(track.localFilePath!).existsSync()) {
        audioSources.add(
          AudioSource.file(track.localFilePath!, tag: mediaItem),
        );
      } else {
        final streamUrl = apiClient.resolveUrl(track.streamUrl);
        audioSources.add(AudioSource.uri(Uri.parse(streamUrl), tag: mediaItem));
      }
    }

    final playlist = ConcatenatingAudioSource(
      children: audioSources,
      useLazyPreparation: true,
    );

    try {
      await _player.setAudioSource(
        playlist,
        initialIndex: initialIndex.clamp(0, audioSources.length - 1),
        initialPosition: Duration.zero,
      );
      await _player.play();
    } catch (e) {
      debugPrint('Error playing album: $e');
    }
  }

  Future<void> playTrack({
    required Track track,
    required Album album,
    required ApiClient apiClient,
  }) async {
    final trackIndex = album.tracks.indexWhere((t) => t.id == track.id);
    await playAlbum(
      album: album,
      initialIndex: trackIndex >= 0 ? trackIndex : 0,
      apiClient: apiClient,
    );
  }

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> stop() => _player.stop();
  Future<void> seek(Duration position, {int? index}) =>
      _player.seek(position, index: index);
  Future<void> seekToNext() => _player.seekToNext();
  Future<void> seekToPrevious() => _player.seekToPrevious();
  Future<void> setLoopMode(LoopMode loopMode) => _player.setLoopMode(loopMode);
  Future<void> setShuffleModeEnabled(bool enabled) =>
      _player.setShuffleModeEnabled(enabled);

  void dispose() {
    _player.dispose();
  }
}
