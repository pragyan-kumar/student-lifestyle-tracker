import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

/// Riverpod provider for configured Dio HTTP client.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl        : AppConstants.baseUrl,
    connectTimeout : const Duration(milliseconds: AppConstants.connectTimeout),
    receiveTimeout : const Duration(milliseconds: AppConstants.receiveTimeout),
    headers        : {'Content-Type': 'application/json'},
  ));

  dio.interceptors.addAll([
    _AuthInterceptor(),
    _LoggingInterceptor(),
    _ErrorInterceptor(),
  ]);

  return dio;
});

/// Attaches JWT Bearer token to every request.
class _AuthInterceptor extends Interceptor {
  final _storage = const FlutterSecureStorage();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: AppConstants.kAuthToken);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 401 → clear token → redirect to login (handled by router redirect)
    if (err.response?.statusCode == 401) {
      await _storage.delete(key: AppConstants.kAuthToken);
    }
    handler.next(err);
  }
}

/// Logs request/response in debug mode.
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('[HTTP] ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('[HTTP] ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }
}

/// Normalises DioExceptions into readable AppException messages.
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final message = err.response?.data?['message'] ?? err.message ?? 'Unknown error';
    print('[HTTP ERROR] $message');
    handler.next(err);
  }
}
