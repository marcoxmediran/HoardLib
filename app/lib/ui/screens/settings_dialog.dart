import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoardlib/core/constants/app_constants.dart';
import 'package:hoardlib/core/utils/formatters.dart';
import 'package:hoardlib/providers/downloads_provider.dart';
import 'package:hoardlib/providers/library_provider.dart';
import 'package:hoardlib/providers/settings_provider.dart';

class SettingsDialog extends ConsumerStatefulWidget {
  const SettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const SettingsDialog(),
    );
  }

  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog> {
  late TextEditingController _urlController;
  bool _testingConnection = false;
  bool? _connectionSuccess;
  String? _testMessage;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ref.read(serverUrlProvider));
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _testingConnection = true;
      _connectionSuccess = null;
      _testMessage = null;
    });

    final currentUrl = _urlController.text.trim();
    await ref.read(serverUrlProvider.notifier).setUrl(currentUrl);

    final isOk = await ref.read(apiClientProvider).checkConnection();

    setState(() {
      _testingConnection = false;
      _connectionSuccess = isOk;
      _testMessage = isOk
          ? 'Connected successfully to HoardLib Server!'
          : 'Unable to reach server. Check URL and network.';
    });

    ref.read(libraryNotifierProvider.notifier).refreshLibrary();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final storageUsageAsync = ref.watch(storageUsageProvider);
    final libraryState = ref.watch(libraryNotifierProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings & Server'),
            centerTitle: true,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          body: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // Server URL Section
              Text(
                'SERVER CONFIGURATION',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: 'HoardLib Server Base URL',
                  hintText: 'http://192.168.1.100:8080',
                  prefixIcon: const Icon(Icons.dns_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check_rounded),
                    tooltip: 'Save URL',
                    onPressed: () async {
                      await ref
                          .read(serverUrlProvider.notifier)
                          .setUrl(_urlController.text);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Server URL updated')),
                        );
                      }
                      ref
                          .read(libraryNotifierProvider.notifier)
                          .refreshLibrary();
                    },
                  ),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 8),

              // Presets
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.phone_android_rounded, size: 16),
                    label: const Text('Android Emulator'),
                    onPressed: () {
                      _urlController.text =
                          AppConstants.defaultAndroidEmulatorUrl;
                      _testConnection();
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.laptop_rounded, size: 16),
                    label: const Text('Localhost'),
                    onPressed: () {
                      _urlController.text = AppConstants.defaultLocalhostUrl;
                      _testConnection();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Connection Test Button & Status
              OutlinedButton.icon(
                onPressed: _testingConnection ? null : _testConnection,
                icon: _testingConnection
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.network_check_rounded),
                label: Text(
                  _testingConnection ? 'Testing...' : 'Test Connection',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (_testMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (_connectionSuccess ?? false)
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (_connectionSuccess ?? false)
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        (_connectionSuccess ?? false)
                            ? Icons.check_circle_rounded
                            : Icons.error_outline_rounded,
                        color: (_connectionSuccess ?? false)
                            ? Colors.green
                            : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _testMessage!,
                          style: TextStyle(
                            fontSize: 13,
                            color: (_connectionSuccess ?? false)
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Divider(height: 36),

              // Library Scanner Section
              Text(
                'LIBRARY MANAGEMENT',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'On-Demand Library Scan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Scans your music directory, indexes new albums & tracks, and refreshes metadata.',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: libraryState.isLoading
                            ? null
                            : () async {
                                await ref
                                    .read(libraryNotifierProvider.notifier)
                                    .triggerRescan();
                                final result = ref.read(
                                  libraryNotifierProvider,
                                );
                                result.whenOrNull(
                                  data: (summary) {
                                    if (summary != null && context.mounted) {
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text('Scan Complete 🎉'),
                                          content: Text(
                                            'Scanned ${summary.artistsScanned} artists, '
                                            '${summary.albumsScanned} albums, and '
                                            '${summary.tracksScanned} tracks in '
                                            '${(summary.durationMs / 1000).toStringAsFixed(2)}s.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                  error: (err, _) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Scan failed: $err'),
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                        icon: libraryState.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.sync_rounded),
                        label: Text(
                          libraryState.isLoading
                              ? 'Scanning Library...'
                              : 'Trigger Full Scan',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 36),

              // Theme Selector Section
              Text(
                'APPEARANCE',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto_rounded),
                    label: Text('System'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_rounded),
                    label: Text('Light'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_rounded),
                    label: Text('Dark'),
                  ),
                ],
                selected: {themeMode},
                onSelectionChanged: (set) {
                  ref.read(themeModeProvider.notifier).setMode(set.first);
                },
              ),

              const Divider(height: 36),

              // Offline Storage Usage Section
              Text(
                'STORAGE & OFFLINE CACHE',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.folder_special_rounded),
                title: const Text('Offline Music Cache'),
                subtitle: storageUsageAsync.when(
                  data: (bytes) => Text(
                    '${Formatters.formatBytes(bytes)} used for offline albums',
                  ),
                  loading: () => const Text('Calculating storage...'),
                  error: (_, _) => const Text('Storage info unavailable'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
