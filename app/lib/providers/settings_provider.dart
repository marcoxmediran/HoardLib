import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoardlib/core/network/api_client.dart';
import 'package:hoardlib/services/storage_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('storageServiceProvider must be initialized');
});

// Server URL State
class ServerUrlNotifier extends StateNotifier<String> {
  final StorageService _storageService;

  ServerUrlNotifier(this._storageService)
    : super(_storageService.getServerUrl());

  Future<void> setUrl(String newUrl) async {
    final cleanUrl = newUrl.trim();
    await _storageService.setServerUrl(cleanUrl);
    state = cleanUrl;
  }
}

final serverUrlProvider = StateNotifierProvider<ServerUrlNotifier, String>((
  ref,
) {
  final storage = ref.watch(storageServiceProvider);
  return ServerUrlNotifier(storage);
});

// API Client Provider (rebuilds if server URL changes)
final apiClientProvider = Provider<ApiClient>((ref) {
  final url = ref.watch(serverUrlProvider);
  return ApiClient(baseUrl: url);
});

// Server Connection Status
final serverStatusProvider = FutureProvider.autoDispose<bool>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  return await apiClient.checkConnection();
});

// Theme Mode Provider
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final StorageService _storageService;

  ThemeModeNotifier(this._storageService)
    : super(_storageService.getThemeMode());

  Future<void> setMode(ThemeMode mode) async {
    await _storageService.setThemeMode(mode);
    state = mode;
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  final storage = ref.watch(storageServiceProvider);
  return ThemeModeNotifier(storage);
});
