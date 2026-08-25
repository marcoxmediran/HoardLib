import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:hoardlib/core/theme/app_theme.dart';
import 'package:hoardlib/providers/settings_provider.dart';
import 'package:hoardlib/services/storage_service.dart';
import 'package:hoardlib/ui/screens/main_shell_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.mmediran.hoardlib.channel.audio',
    androidNotificationChannelName: 'HoardLib Audio Playback',
    androidNotificationOngoing: true,
    androidNotificationIcon: 'mipmap/ic_launcher',
  );

  final storageService = await StorageService.init();

  runApp(
    ProviderScope(
      overrides: [storageServiceProvider.overrideWithValue(storageService)],
      child: const HoardLibApp(),
    ),
  );
}

class HoardLibApp extends ConsumerWidget {
  const HoardLibApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'HoardLib',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeMode,
      home: const MainShellScreen(),
    );
  }
}
