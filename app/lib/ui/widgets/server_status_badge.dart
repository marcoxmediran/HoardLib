import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoardlib/providers/settings_provider.dart';
import 'package:hoardlib/ui/screens/settings_dialog.dart';

class ServerStatusBadge extends ConsumerWidget {
  const ServerStatusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(serverStatusProvider);

    return statusAsync.when(
      data: (isOnline) {
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => SettingsDialog.show(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOnline ? Colors.greenAccent : Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isOnline
                        ? (Theme.of(context).brightness == Brightness.dark
                              ? Colors.greenAccent
                              : Colors.green.shade800)
                        : Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, _) => InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => SettingsDialog.show(context),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 14,
                color: Colors.orangeAccent,
              ),
              SizedBox(width: 4),
              Text(
                'Disconnected',
                style: TextStyle(fontSize: 12, color: Colors.orangeAccent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
