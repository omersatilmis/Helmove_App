import 'package:flutter/foundation.dart';
import '../../domain/entities/auth_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../profile/domain/repositories/profile_repository.dart'; // Import added
import '../../../../core/utils/app_logger.dart';
import '../../../../core/di/injection_container.dart' as di;

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository; // Dependency added

  AuthProvider(
    this._authRepository,
    this._profileRepository,
  ); // Constructor updated

  bool _isLoading = false;
  String? _errorMessage;
  AuthEntity? _currentUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AuthEntity? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

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
    final isLoggedIn = await _authRepository.isLoggedIn();

    if (isLoggedIn) {
      if (_currentUser == null) {
        // 1. Try to get from local storage
        final persistedUser = await _authRepository.getPersistedUser();

        if (persistedUser != null && persistedUser.id != 0) {
          _currentUser = persistedUser;
          // IMPORTANT: notifyListeners() skipped here because this is often called during build or navigation
        } else {
          // 2. If local storage is empty or invalid, fetch from API
          try {
            AppLogger.info(
              "Persisted user invalid or empty, fetching profile...",
            );
            final profile = await _profileRepository.getMyProfile();

            _currentUser = AuthEntity(
              id: profile.id,
              username: profile.username,
              email: profile.email,
              token: await _authRepository.getAuthToken() ?? '',
              firstName: profile.firstName,
              lastName: profile.lastName,
              profileImageUrl: profile.profileImageUrl,
            );

            // 3. Save to local storage for next time if ID is valid
            if (_currentUser!.id != 0) {
              await _authRepository.savePersistedUser(
                _currentUser!.id,
                _currentUser!.username,
              );
            }
          } catch (e) {
            AppLogger.error("Failed to fetch profile on auth check: $e");
            // If API call fails, we might still be logged in (token exists),
            // but we don't have user details.
          }
        }
        if (_currentUser != null) {
          notifyListeners();
        }
      }
    } else {
      if (_currentUser != null) {
        _currentUser = null;
        notifyListeners();
      }
    }
    return isLoggedIn;
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
