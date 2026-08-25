import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoardlib/providers/library_provider.dart';
import 'package:hoardlib/ui/widgets/album_card.dart';
import 'package:hoardlib/ui/screens/artist_detail_screen.dart';

enum LibraryViewType { albums, artists }

enum AlbumFilterType { all, unlistened, listened }

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  LibraryViewType _viewType = LibraryViewType.albums;
  AlbumFilterType _albumFilter = AlbumFilterType.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isGridView = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allAlbumsAsync = ref.watch(allAlbumsProvider);
    final artistsAsync = ref.watch(artistsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allAlbumsProvider);
          ref.invalidate(artistsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Segmented Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<LibraryViewType>(
                        segments: const [
                          ButtonSegment(
                            value: LibraryViewType.albums,
                            icon: Icon(Icons.album_rounded),
                            label: Text('Albums'),
                          ),
                          ButtonSegment(
                            value: LibraryViewType.artists,
                            icon: Icon(Icons.person_rounded),
                            label: Text('Artists'),
                          ),
                        ],
                        selected: {_viewType},
                        onSelectionChanged: (set) {
                          setState(() => _viewType = set.first);
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(
                              () => _searchQuery = val.trim().toLowerCase(),
                            ),
                            decoration: InputDecoration(
                              hintText: _viewType == LibraryViewType.albums
                                  ? 'Search albums & artists...'
                                  : 'Search artists...',
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                size: 20,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear_rounded,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              filled: true,
                              fillColor: theme
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        if (_viewType == LibraryViewType.albums) ...[
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            icon: Icon(
                              _isGridView
                                  ? Icons.view_list_rounded
                                  : Icons.grid_view_rounded,
                            ),
                            tooltip: _isGridView
                                ? 'Switch to List'
                                : 'Switch to Grid',
                            onPressed: () =>
                                setState(() => _isGridView = !_isGridView),
                          ),
                        ],
                      ],
                    ),
                    if (_viewType == LibraryViewType.albums) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('All'),
                            selected: _albumFilter == AlbumFilterType.all,
                            onSelected: (_) => setState(
                              () => _albumFilter = AlbumFilterType.all,
                            ),
                          ),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            label: const Text('Unlistened'),
                            selected:
                                _albumFilter == AlbumFilterType.unlistened,
                            onSelected: (_) => setState(
                              () => _albumFilter = AlbumFilterType.unlistened,
                            ),
                          ),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            label: const Text('Listened'),
                            selected: _albumFilter == AlbumFilterType.listened,
                            onSelected: (_) => setState(
                              () => _albumFilter = AlbumFilterType.listened,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Content Sliver
            if (_viewType == LibraryViewType.albums)
              allAlbumsAsync.when(
                data: (albums) {
                  var filtered = albums.where((a) {
                    if (_searchQuery.isNotEmpty) {
                      if (!a.title.toLowerCase().contains(_searchQuery) &&
                          !a.artistName.toLowerCase().contains(_searchQuery)) {
                        return false;
                      }
                    }
                    if (_albumFilter == AlbumFilterType.unlistened) {
                      return !a.listened;
                    }
                    if (_albumFilter == AlbumFilterType.listened) {
                      return a.listened;
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('No albums found')),
                    );
                  }

                  if (_isGridView) {
                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.74,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => AlbumCard(album: filtered[index]),
                          childCount: filtered.length,
                        ),
                      ),
                    );
                  } else {
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            AlbumCard(album: filtered[index], compact: true),
                        childCount: filtered.length,
                      ),
                    );
                  }
                },
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 12),
                        Text('Error loading library: $err'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(allAlbumsProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              artistsAsync.when(
                data: (artists) {
                  final filtered = artists.where((a) {
                    if (_searchQuery.isEmpty) return true;
                    return a.name.toLowerCase().contains(_searchQuery);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('No artists found')),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final artist = filtered[index];
                      final albumsCount = artist.albums.length;
                      final listenedCount = artist.albums
                          .where((a) => a.listened)
                          .length;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          foregroundColor: theme.colorScheme.onPrimaryContainer,
                          child: const Icon(Icons.person_rounded),
                        ),
                        title: Text(
                          artist.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '$albumsCount ${albumsCount == 1 ? 'album' : 'albums'} • $listenedCount listened',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ArtistDetailScreen(
                                artistId: artist.id,
                                artistName: artist.name,
                              ),
                            ),
                          );
                        },
                      );
                    }, childCount: filtered.length),
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 12),
                        Text('Error loading artists: $err'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(artistsProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}
