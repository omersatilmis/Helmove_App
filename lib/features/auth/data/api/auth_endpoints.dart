/// Auth API Endpoints
/// These are relative paths since Dio's baseUrl already includes the server address.
class AuthEndpoints {
  static const String login = 'api/auth/login';
  static const String register = 'api/auth/register';
  static const String logout = 'api/auth/logout';
  static const String forgotPassword = 'api/auth/forgot-password';
  static const String confirmForgotPassword =
      'api/auth/confirm-forgot-password';
  static const String resetPassword = 'api/auth/reset-password';
  static const String refreshToken = 'api/auth/refresh-token';
  static const String revokeToken = 'api/auth/revoke-token';
  static const String sessions = 'api/auth/sessions';
  static const String refreshCurrentUser = 'api/auth/refresh-current-user';
  static const String googleLogin = 'api/auth/google';
  static const String socialLogin = 'api/auth/social-login';
  static const String sendRegisterOtp = 'api/auth/send-register-otp';
  static const String confirmRegister = 'api/auth/confirm-register';

  // Some backend branches use alternative naming for social auth.
  // We try these as fallback when the primary path returns 404.
  static const List<String> socialLoginFallbacks = [
    'api/auth/social-signin',
    'api/auth/social-sign-in',
    'api/auth/external-login',
  ];
}
