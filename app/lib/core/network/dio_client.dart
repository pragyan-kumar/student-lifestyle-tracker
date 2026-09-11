import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

/// Riverpod provider for configured Dio HTTP client.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
    receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.addAll([
    _AuthInterceptor(dio),
    _LoggingInterceptor(),
    _ErrorInterceptor(),
  ]);

  return dio;
});

/// Attaches JWT Bearer token to every request and auto-refreshes on 401.
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio);

  final Dio _dio;
  final _storage = const FlutterSecureStorage();
  bool _isRefreshing = false;

  static const _kAccessToken = 'auth_token';
  static const _kRefreshToken = 'refresh_token';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: _kAccessToken);
    print(
        '[AUTH] ${options.method} ${options.path} — token: ${token != null ? "present" : "MISSING"}');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      final path = err.requestOptions.path;
      // Don't refresh-loop on auth endpoints themselves
      final isAuthEndpoint = path.contains('/auth/login') ||
          path.contains('/auth/register') ||
          path.contains('/auth/refresh');

      if (!isAuthEndpoint) {
        // Try to refresh the token
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          // Retry the original request with the new token
          try {
            final token = await _storage.read(key: _kAccessToken);
            final opts = err.requestOptions;
            opts.headers['Authorization'] = 'Bearer $token';
            final response = await _dio.fetch(opts);
            handler.resolve(response);
            return;
          } catch (retryErr) {
            print('[AUTH] Retry after refresh failed: $retryErr');
          }
        } else {
          // Refresh failed — clear tokens so router redirects to login
          await _storage.delete(key: _kAccessToken);
          await _storage.delete(key: _kRefreshToken);
          print('[AUTH] Refresh failed — clearing tokens');
        }
      }
    }
    handler.next(err);
  }

  Future<bool> _tryRefreshToken() async {
    _isRefreshing = true;
    try {
      final refreshToken = await _storage.read(key: _kRefreshToken);
      if (refreshToken == null || refreshToken.isEmpty) return false;

      // Use a fresh Dio (not the main one) to avoid interceptor loops
      final refreshDio = Dio(BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout:
            const Duration(milliseconds: AppConstants.connectTimeout),
        receiveTimeout:
            const Duration(milliseconds: AppConstants.receiveTimeout),
        headers: {'Content-Type': 'application/json'},
      ));

      final res = await refreshDio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final newAccessToken = res.data['accessToken'] as String?;
      final newRefreshToken = res.data['refreshToken'] as String?;

      if (newAccessToken == null) return false;

      await _storage.write(key: _kAccessToken, value: newAccessToken);
      if (newRefreshToken != null) {
        await _storage.write(key: _kRefreshToken, value: newRefreshToken);
      }

      print('[AUTH] Token refreshed successfully');
      return true;
    } catch (e) {
      print('[AUTH] Token refresh error: $e');
      return false;
    } finally {
      _isRefreshing = false;
    }
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
    final message =
        err.response?.data?['message'] ?? err.message ?? 'Unknown error';
    print('[HTTP ERROR] ${err.response?.statusCode} $message');
    handler.next(err);
  }
}
