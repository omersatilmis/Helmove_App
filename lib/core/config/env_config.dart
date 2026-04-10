/// Environment configuration for the application.
/// This centralizes all environment-specific settings.
class EnvConfig {
  // Prevent instantiation
  EnvConfig._();

  // --- Base URL Configuration ---
  // Change these values based on your environment.
  // For production, replace with your actual server URL (preferably HTTPS).

  /// Base URL for Android Emulator (localhost via 10.0.2.2)
  static const String emulatorBaseUrl = "http://10.0.2.2:5089/";

  /// Base URL for iOS Simulator (localhost)
  static const String iosSimulatorBaseUrl = "http://localhost:5089/";

  /// Base URL for physical devices on the local network
  /// Update this IP address to match your development machine's local IP.
  static const String localDeviceBaseUrl = "http://192.168.68.50:5089/";

  /// Base URL for Web
  static const String webBaseUrl = "http://localhost:5089/";

  // --- Production URL ---
  static const String productionBaseUrl = "https://api.helmove.com/";

  // --- Timeouts ---
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
