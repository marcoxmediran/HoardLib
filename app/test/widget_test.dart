import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoardlib/core/theme/app_theme.dart';
import 'package:hoardlib/providers/library_provider.dart';
import 'package:hoardlib/providers/settings_provider.dart';
import 'package:hoardlib/services/storage_service.dart';
import 'package:hoardlib/ui/screens/main_shell_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('HoardLib MainShell navigation and tabs smoke test', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
          backlogAlbumsProvider.overrideWith((ref) => Future.value([])),
          allAlbumsProvider.overrideWith((ref) => Future.value([])),
          artistsProvider.overrideWith((ref) => Future.value([])),
          serverStatusProvider.overrideWith((ref) => Future.value(true)),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          home: const MainShellScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify AppBar brand title
    expect(find.text('HoardLib'), findsOneWidget);

    // Verify NavigationBar destinations
    expect(find.text('Backlog'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Downloads'), findsOneWidget);

    // Tap on Library tab
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();

    // Verify Library segments
    expect(find.text('Albums'), findsOneWidget);
    expect(find.text('Artists'), findsOneWidget);

    // Tap on Downloads tab
    await tester.tap(find.text('Downloads'));
    await tester.pumpAndSettle();

    // Verify Downloads empty state text
    expect(find.text('Offline Music Collection'), findsOneWidget);
  });
}
