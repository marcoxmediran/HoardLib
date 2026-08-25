import 'package:dio/dio.dart';
import 'package:hoardlib/models/artist.dart';
import 'package:hoardlib/models/album.dart';
import 'package:hoardlib/models/scan_summary.dart';

class ApiClient {
  late final Dio _dio;
  String baseUrl;

  ApiClient({required this.baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Accept': 'application/json'},
      ),
    );
  }

  void updateBaseUrl(String newBaseUrl) {
    var sanitized = newBaseUrl.trim();
    if (sanitized.endsWith('/')) {
      sanitized = sanitized.substring(0, sanitized.length - 1);
    }
    baseUrl = sanitized;
    _dio.options.baseUrl = sanitized;
  }

  String resolveUrl(String relativeOrAbsoluteUrl) {
    if (relativeOrAbsoluteUrl.startsWith('http://') ||
        relativeOrAbsoluteUrl.startsWith('https://')) {
      return relativeOrAbsoluteUrl;
    }
    final path = relativeOrAbsoluteUrl.startsWith('/')
        ? relativeOrAbsoluteUrl
        : '/$relativeOrAbsoluteUrl';
    return '$baseUrl$path';
  }

  Future<bool> checkConnection() async {
    try {
      final response = await _dio.get(
        '/api/albums',
        queryParameters: {'listened': false},
        options: Options(
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<Artist>> getArtists() async {
    final response = await _dio.get('/api/artists');
    if (response.statusCode == 200 && response.data is List) {
      return (response.data as List)
          .map((item) => Artist.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<Artist> getArtist(int id) async {
    final response = await _dio.get('/api/artists/$id');
    return Artist.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Album>> getAlbums({bool? listened}) async {
    final queryParams = <String, dynamic>{};
    if (listened != null) {
      queryParams['listened'] = listened;
    }

    final response = await _dio.get(
      '/api/albums',
      queryParameters: queryParams,
    );

    if (response.statusCode == 200 && response.data is List) {
      return (response.data as List)
          .map((item) => Album.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<Album> getAlbum(int id) async {
    final response = await _dio.get('/api/albums/$id');
    return Album.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Album> toggleAlbumListened(int id, {bool? listened}) async {
    Map<String, dynamic>? data;
    if (listened != null) {
      data = {'listened': listened};
    }
    final response = await _dio.patch('/api/albums/$id/listened', data: data);
    return Album.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ScanSummary> triggerScan() async {
    final response = await _dio.post('/api/library/scan');
    return ScanSummary.fromJson(response.data as Map<String, dynamic>);
  }
}
