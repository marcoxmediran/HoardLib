import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hoardlib/core/constants/app_constants.dart';
import 'package:hoardlib/models/album.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // Server URL
  String getServerUrl() {
    return _prefs.getString(AppConstants.keyServerUrl) ??
        AppConstants.defaultAndroidEmulatorUrl;
  }

  Future<void> setServerUrl(String url) async {
    await _prefs.setString(AppConstants.keyServerUrl, url.trim());
  }

  // Theme Mode
  ThemeMode getThemeMode() {
    final mode = _prefs.getString(AppConstants.keyThemeMode);
    if (mode == 'light') return ThemeMode.light;
    if (mode == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    switch (mode) {
      case ThemeMode.light:
        await _prefs.setString(AppConstants.keyThemeMode, 'light');
        break;
      case ThemeMode.dark:
        await _prefs.setString(AppConstants.keyThemeMode, 'dark');
        break;
      case ThemeMode.system:
        await _prefs.setString(AppConstants.keyThemeMode, 'system');
        break;
    }
  }

  // Downloaded Albums Index
  List<Album> getDownloadedAlbums() {
    final raw = _prefs.getString(AppConstants.keyDownloadedAlbums);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List decoded = jsonDecode(raw) as List;
      return decoded
          .map((item) => Album.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveDownloadedAlbums(List<Album> albums) async {
    final raw = jsonEncode(albums.map((a) => a.toJson()).toList());
    await _prefs.setString(AppConstants.keyDownloadedAlbums, raw);
  }

  Future<void> addDownloadedAlbum(Album album) async {
    final current = getDownloadedAlbums();
    final index = current.indexWhere((a) => a.id == album.id);
    if (index >= 0) {
      current[index] = album;
    } else {
      current.add(album);
    }
    await saveDownloadedAlbums(current);
  }

  Future<void> removeDownloadedAlbum(int albumId) async {
    final current = getDownloadedAlbums();
    current.removeWhere((a) => a.id == albumId);
    await saveDownloadedAlbums(current);
  }
}
