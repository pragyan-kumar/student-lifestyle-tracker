import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/dio_client.dart';

/// Model returned from login / register endpoints.
class AuthUser {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final int points;
  final int streakDays;
  final int badgesCount;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.points = 0,
    this.streakDays = 0,
    this.badgesCount = 0,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['_id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        avatar: json['avatar'] as String?,
        points: (json['points'] as num?)?.toInt() ?? 0,
        streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
        badgesCount: (json['badges'] as List?)?.length ?? 0,
      );
}

/// Handles all auth API calls and token persistence.
class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final FlutterSecureStorage _storage;

  static const _kAccessToken  = 'auth_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kUserName     = 'user_name';
  static const _kUserEmail    = 'user_email';
  static const _kUserId       = 'user_id';

  // ── Register ──────────────────────────────────────────────────────────────
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await _dio.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'role': 'student',
    });
    final data = res.data as Map<String, dynamic>;
    await _persistTokens(data);
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final data = res.data as Map<String, dynamic>;
    await _persistTokens(data);
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {
      // Best-effort; clear local tokens regardless.
    }
    await _storage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_onboarded');
  }

  // ── Check persisted session ───────────────────────────────────────────────
  Future<AuthUser?> getStoredUser() async {
    final token = await _storage.read(key: _kAccessToken);
    final id    = await _storage.read(key: _kUserId);
    final name  = await _storage.read(key: _kUserName);
    final email = await _storage.read(key: _kUserEmail);
    if (token == null || id == null || name == null || email == null) return null;
    return AuthUser(id: id, name: name, email: email);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Future<void> _persistTokens(Map<String, dynamic> data) async {
    await _storage.write(key: _kAccessToken,  value: data['accessToken']  as String);
    await _storage.write(key: _kRefreshToken, value: data['refreshToken'] as String);
    final user = data['user'] as Map<String, dynamic>;
    await _storage.write(key: _kUserId,    value: user['_id']   as String);
    await _storage.write(key: _kUserName,  value: user['name']  as String);
    await _storage.write(key: _kUserEmail, value: user['email'] as String);
  }
}

// ── Riverpod Providers ────────────────────────────────────────────────────────

final _secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.read(dioProvider),
    ref.read(_secureStorageProvider),
  );
});
