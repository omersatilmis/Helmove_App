import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthInterceptor extends Interceptor {
  final SharedPreferences _sharedPreferences;

  AuthInterceptor(this._sharedPreferences);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // SharedPreferences verisini taze diskten okumayı zorla
    await _sharedPreferences.reload();

    // Token'ı SharedPrefs'ten al
    final token = _sharedPreferences.getString('AUTH_TOKEN');

    if (token != null && token.isNotEmpty) {
      // DEBUG LOG
      print(
        '🔐 AuthInterceptor: Using token starting with ${token.substring(0, token.length > 5 ? 5 : token.length)}...',
      );
      options.headers['Authorization'] = 'Bearer $token';
    } else {
      print('⚠️ AuthInterceptor: No token found in SharedPreferences!');
    }

    super.onRequest(options, handler);
  }
}
