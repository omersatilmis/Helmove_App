import 'package:flutter/foundation.dart';
import '../../domain/entities/auth_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/di/injection_container.dart' as di;

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthProvider(this._authRepository);

  bool _isLoading = false;
  String? _errorMessage;
  AuthEntity? _currentUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AuthEntity? get currentUser => _currentUser;

  // Login
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    clearError();

    try {
      final authEntity = await _authRepository.login(email, password);
      _currentUser = authEntity;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Register
  Future<bool> register({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    _setLoading(true);
    clearError();

    try {
      await _authRepository.register(
        username: username,
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Şifremi Unuttum
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    clearError();

    try {
      await _authRepository.forgotPassword(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Şifre Sıfırlama
  Future<bool> resetPassword({
    required String email,
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    _setLoading(true);
    clearError();

    try {
      await _authRepository.resetPassword(
        email: email,
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmNewPassword: confirmNewPassword,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authRepository.logout();
      _currentUser = null; // Kullanıcı bilgisini temizle
      // Singleton önbelleklerini temizle - yeni kullanıcı için taze veri
      await di.resetOnLogout();
    } catch (e) {
      // Logout hatası olsa bile token silineceği için kullanıcı çıkmış sayılır
      AppLogger.warning("Logout provider error: $e");
    } finally {
      _setLoading(false);
    }
  }

  // Auth check
  Future<bool> checkAuthStatus() async {
    return await _authRepository.isLoggedIn();
  }

  // Yardımcı Metodlar
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message.replaceAll("Exception: ", "");
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
