import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CachedHttpClient {
  static final CachedHttpClient _instance = CachedHttpClient._internal();

  factory CachedHttpClient() {
    return _instance;
  }

  CachedHttpClient._internal();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept-Encoding': 'gzip, deflate',
      },
    ),
  );

  late final CacheManager _cacheManager = DefaultCacheManager();

  // GET with caching
  Future<Response> getWithCache(
    String url, {
    Duration cacheDuration = const Duration(hours: 1),
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        final cachedFile = await _cacheManager.getFileFromCache(url);
        if (cachedFile != null && !cachedFile.isExpired()) {
          return Response(
            requestOptions: RequestOptions(path: url),
            data: cachedFile.file.readAsStringSync(),
            statusCode: 200,
          );
        }
      }

      final response = await _dio.get(url);
      
      // Cache the response
      if (response.statusCode == 200) {
        late List<int> data;
        if (response.data is String) {
          data = utf8.encode(response.data as String);
        } else {
          data = utf8.encode(jsonEncode(response.data));
        }
        await _cacheManager.putFile(
          url,
          Uint8List.fromList(data),
          fileExtension: 'json',
          maxAge: cacheDuration,
        );
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // POST without caching
  Future<Response> post(
    String url, {
    required Map<String, dynamic> data,
  }) async {
    try {
      return await _dio.post(url, data: data);
    } catch (e) {
      rethrow;
    }
  }

  // PUT without caching
  Future<Response> put(
    String url, {
    required Map<String, dynamic> data,
  }) async {
    try {
      return await _dio.put(url, data: data);
    } catch (e) {
      rethrow;
    }
  }

  // DELETE without caching
  Future<Response> delete(String url) async {
    try {
      return await _dio.delete(url);
    } catch (e) {
      rethrow;
    }
  }

  void clearCache() {
    _cacheManager.emptyCache();
  }
}

extension FileInfoExtension on FileInfo {
  bool isExpired() {
    return DateTime.now().isAfter(validTill);
  }
}
