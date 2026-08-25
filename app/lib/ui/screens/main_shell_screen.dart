import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoardlib/providers/library_provider.dart';
import 'package:hoardlib/ui/widgets/mini_player_dock.dart';
import 'package:hoardlib/ui/widgets/server_status_badge.dart';
import 'package:hoardlib/ui/screens/backlog_screen.dart';
import 'package:hoardlib/ui/screens/downloads_screen.dart';
import 'package:hoardlib/ui/screens/library_screen.dart';
import 'package:hoardlib/ui/screens/settings_dialog.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    BacklogScreen(),
    LibraryScreen(),
    DownloadsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final backlogAsync = ref.watch(backlogAlbumsProvider);
    final backlogCount = backlogAsync.valueOrNull?.length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.music_note_rounded, color: Colors.greenAccent),
            const SizedBox(width: 8),
            const Text(
              'HoardLib',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ],
        ),
        actions: [
          const ServerStatusBadge(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Library',
            onPressed: () {
              ref.read(libraryNotifierProvider.notifier).refreshLibrary();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings',
            onPressed: () => SettingsDialog.show(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiniPlayerDock(),
            NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() => _currentIndex = index);
              },
              destinations: [
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: backlogCount != null && backlogCount > 0,
                    label: Text(
                      backlogCount != null && backlogCount > 99
                          ? '99+'
                          : '${backlogCount ?? 0}',
                    ),
                    child: const Icon(Icons.playlist_play_rounded),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: backlogCount != null && backlogCount > 0,
                    label: Text(
                      backlogCount != null && backlogCount > 99
                          ? '99+'
                          : '${backlogCount ?? 0}',
                    ),
                    child: const Icon(Icons.playlist_play_rounded),
                  ),
                  label: 'Backlog',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.library_music_outlined),
                  selectedIcon: Icon(Icons.library_music_rounded),
                  label: 'Library',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.cloud_download_outlined),
                  selectedIcon: Icon(Icons.cloud_download_rounded),
                  label: 'Downloads',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
