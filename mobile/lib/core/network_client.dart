import 'dart:convert';
import 'package:dio/dio.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'constants.dart';

class NetworkClient {
  static final NetworkClient _instance = NetworkClient._internal();
  factory NetworkClient() => _instance;
  NetworkClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: 30000),
      receiveTimeout: const Duration(milliseconds: 30000),
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final token = await ApiService.getValidToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (e) {
          // ignore
        }
        return handler.next(options);
      },
      onError: (err, handler) async {
        // If 401, try refresh once and retry
        if (err.response?.statusCode == 401) {
          try {
            final token = await ApiService.getValidToken();
            if (token != null) {
              final opts = err.requestOptions;
              opts.headers['Authorization'] = 'Bearer $token';
              final cloneReq = await _dio.fetch(opts);
              return handler.resolve(cloneReq);
            }
          } catch (e) {
            // fall through
          }
        }
        return handler.next(err);
      },
    ));
  }

  late final Dio _dio;

  Dio get client => _dio;
}
