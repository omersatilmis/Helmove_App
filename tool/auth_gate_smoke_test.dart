import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_comm_app_1/core/network/auth_bootstrap_gate.dart';
import 'package:moto_comm_app_1/core/network/auth_interceptor.dart';
import 'package:moto_comm_app_1/features/auth/data/datasources/auth_local_data_source.dart';

class FakeAuthLocalDataSource implements AuthLocalDataSource {
  FakeAuthLocalDataSource({this.token, this.refreshToken});

  String? token;
  String? refreshToken;
  int tokenReadCount = 0;

  @override
  Future<void> clearAuthData() async {
    token = null;
    refreshToken = null;
  }

  @override
  Future<void> deleteRefreshToken() async {
    refreshToken = null;
  }

  @override
  Future<void> deleteToken() async {
    token = null;
  }

  @override
  Future<String?> getFirstName() async => null;

  @override
  Future<String?> getLastName() async => null;

  @override
  Future<String?> getEmail() async => null;

  @override
  Future<String?> getProfileImageUrl() async => null;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<String?> getToken() async {
    tokenReadCount++;
    return token;
  }

  @override
  Future<int?> getUserId() async => null;

  @override
  Future<String?> getUsername() async => null;

  @override
  Future<void> saveFirstName(String? firstName) async {}

  @override
  Future<void> saveEmail(String email) async {}

  @override
  Future<void> saveLastName(String? lastName) async {}

  @override
  Future<void> saveProfileImageUrl(String? profileImageUrl) async {}

  @override
  Future<void> saveRefreshToken(String refreshToken) async {
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> saveToken(String token) async {
    this.token = token;
  }

  @override
  Future<void> saveUserId(int userId) async {}

  @override
  Future<void> saveUsername(String username) async {}
}

void main() {
  test(
    'AuthInterceptor waits for bootstrap gate and attaches Authorization',
    () async {
      final gate = AuthBootstrapGate();
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
      final refreshDio = Dio(BaseOptions(baseUrl: 'https://example.com'));
      final localDataSource = FakeAuthLocalDataSource(token: 'jwt-smoke-token');
      final interceptor = AuthInterceptor(
        dio,
        refreshDio,
        localDataSource,
        gate,
        null,
        null,
      );

      final options = RequestOptions(
        path: '/api/content/posts/feed',
        method: 'GET',
      );
      final handler = RequestInterceptorHandler();
      final stopwatch = Stopwatch()..start();

      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 350), () {
          gate.complete();
        }),
      );

      interceptor.onRequest(options, handler);
      await handler.future;
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(300));
      expect(
        options.headers['Authorization'],
        equals('Bearer jwt-smoke-token'),
      );
      expect(localDataSource.tokenReadCount, equals(1));
    },
  );
}
