import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoardlib/models/album.dart';
import 'package:hoardlib/models/download_item.dart';
import 'package:hoardlib/services/download_service.dart';
import 'package:hoardlib/services/storage_service.dart';
import 'package:hoardlib/providers/settings_provider.dart';

final downloadServiceProvider = Provider<DownloadService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return DownloadService(storage);
});

// Active downloads map: albumId -> DownloadItem
class ActiveDownloadsNotifier extends StateNotifier<Map<int, DownloadItem>> {
  ActiveDownloadsNotifier() : super({});

  void updateProgress(DownloadItem item) {
    state = {...state, item.album.id: item};
  }

  void removeDownload(int albumId) {
    final updated = Map<int, DownloadItem>.from(state)..remove(albumId);
    state = updated;
  }
}

final activeDownloadsProvider =
    StateNotifierProvider<ActiveDownloadsNotifier, Map<int, DownloadItem>>((
      ref,
    ) {
      return ActiveDownloadsNotifier();
    });

// Downloaded Albums State Notifier
class DownloadedAlbumsNotifier extends StateNotifier<List<Album>> {
  final DownloadService _downloadService;
  final StorageService _storageService;
  final Ref _ref;

  DownloadedAlbumsNotifier(
    this._downloadService,
    this._storageService,
    this._ref,
  ) : super([]) {
    loadDownloadedAlbums();
  }

  void loadDownloadedAlbums() {
    state = _storageService.getDownloadedAlbums();
  }

  Future<void> startDownload(Album album) async {
    final apiClient = _ref.read(apiClientProvider);
    final activeNotifier = _ref.read(activeDownloadsProvider.notifier);

    await _downloadService.downloadAndExtractAlbum(
      album: album,
      apiClient: apiClient,
      onProgress: (item) {
        activeNotifier.updateProgress(item);
        if (item.status == DownloadStatus.completed) {
          loadDownloadedAlbums();
          _ref.invalidate(storageUsageProvider);
        }
      },
    );
  }

  Future<void> deleteDownload(int albumId) async {
    await _downloadService.deleteDownloadedAlbum(albumId);
    _ref.read(activeDownloadsProvider.notifier).removeDownload(albumId);
    loadDownloadedAlbums();
    _ref.invalidate(storageUsageProvider);
  }

  bool isAlbumDownloaded(int albumId) {
    return state.any((a) => a.id == albumId);
  }
}

final downloadedAlbumsProvider =
    StateNotifierProvider<DownloadedAlbumsNotifier, List<Album>>((ref) {
      final downloadService = ref.watch(downloadServiceProvider);
      final storageService = ref.watch(storageServiceProvider);
      return DownloadedAlbumsNotifier(downloadService, storageService, ref);
    });

final storageUsageProvider = FutureProvider.autoDispose<int>((ref) async {
  final downloadService = ref.watch(downloadServiceProvider);
  return await downloadService.getTotalStorageUsageBytes();
});
