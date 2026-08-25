import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoardlib/models/album.dart';
import 'package:hoardlib/models/artist.dart';
import 'package:hoardlib/models/scan_summary.dart';
import 'package:hoardlib/providers/settings_provider.dart';

// Unlistened Backlog Albums Provider
final backlogAlbumsProvider = FutureProvider.autoDispose<List<Album>>((
  ref,
) async {
  final apiClient = ref.watch(apiClientProvider);
  return await apiClient.getAlbums(listened: false);
});

// All Albums Provider
final allAlbumsProvider = FutureProvider.autoDispose<List<Album>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  return await apiClient.getAlbums();
});

// All Artists Provider
final artistsProvider = FutureProvider.autoDispose<List<Artist>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  return await apiClient.getArtists();
});

// Single Album Provider
final albumDetailProvider = FutureProvider.autoDispose.family<Album, int>((
  ref,
  albumId,
) async {
  final apiClient = ref.watch(apiClientProvider);
  return await apiClient.getAlbum(albumId);
});

// Single Artist Provider
final artistDetailProvider = FutureProvider.autoDispose.family<Artist, int>((
  ref,
  artistId,
) async {
  final apiClient = ref.watch(apiClientProvider);
  return await apiClient.getArtist(artistId);
});

// Library Action State (Scanning / Updating)
class LibraryNotifier extends StateNotifier<AsyncValue<ScanSummary?>> {
  final Ref _ref;

  LibraryNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> triggerRescan() async {
    state = const AsyncValue.loading();
    try {
      final apiClient = _ref.read(apiClientProvider);
      final summary = await apiClient.triggerScan();
      state = AsyncValue.data(summary);
      refreshLibrary();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<Album?> toggleListened(int albumId, {bool? explicitStatus}) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final updated = await apiClient.toggleAlbumListened(
        albumId,
        listened: explicitStatus,
      );
      // Invalidate relevant providers to reflect latest state
      _ref.invalidate(backlogAlbumsProvider);
      _ref.invalidate(allAlbumsProvider);
      _ref.invalidate(artistsProvider);
      _ref.invalidate(albumDetailProvider(albumId));
      return updated;
    } catch (e) {
      return null;
    }
  }

  void refreshLibrary() {
    _ref.invalidate(backlogAlbumsProvider);
    _ref.invalidate(allAlbumsProvider);
    _ref.invalidate(artistsProvider);
    _ref.invalidate(serverStatusProvider);
  }
}

final libraryNotifierProvider =
    StateNotifierProvider<LibraryNotifier, AsyncValue<ScanSummary?>>((ref) {
      return LibraryNotifier(ref);
    });
