/// Auth API Endpoints
/// These are relative paths since Dio's baseUrl already includes the server address.
class AuthEndpoints {
  static const String login = 'api/auth/login';
  static const String register = 'api/auth/register';
  static const String logout = 'api/auth/logout';
  static const String forgotPassword = 'api/auth/forgot-password';
  static const String resetPassword = 'api/auth/reset-password';
}
