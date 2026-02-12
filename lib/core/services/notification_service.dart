import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class NotificationService {
  static const String _appId =
      "826a8fdc-3290-4a00-a14b-74a4c6e8ac20"; // Backend appsettings.json'dan aldım

  /// OneSignal'i başlatır
  Future<void> initialize() async {
    try {
      // 1. OneSignal Debugging (Geliştirme aşamasında açık kalsın)
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

      // 2. Initialize
      OneSignal.initialize(_appId);

      // 3. İzin İste
      final permission = await OneSignal.Notifications.requestPermission(true);
      debugPrint("🔔 [NotificationService] Permission: $permission");

      // 4. Global Event Handlers
      // Bildirime tıklandığında ne olacak?
      OneSignal.Notifications.addClickListener((event) {
        debugPrint(
          "🔔 [NotificationService] Notification Clicked: ${event.notification.additionalData}",
        );
        // Burada navigation logic eklenebilir (örn. go_router ile odaya git)
      });

      // Bildirim ön planda geldiğinde ne olacak?
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        debugPrint(
          "🔔 [NotificationService] Notification Received in Foreground: ${event.notification.title}",
        );
        // event.preventDefault(); // Eğer sistem bildirimini göstermek istemiyorsak
        // event.notification.display(); // Manuel göstermek için
      });
    } catch (e) {
      debugPrint("❌ [NotificationService] Init Error: $e");
    }
  }

  /// Kullanıcı giriş yaptığında OneSignal ile eşleştirip External ID atar
  Future<void> login(String userId) async {
    try {
      debugPrint("🔔 [NotificationService] Logging in user: $userId");
      await OneSignal.login(userId);
    } catch (e) {
      debugPrint("❌ [NotificationService] Login Error: $e");
    }
  }

  /// Çıkış yapıldığında
  Future<void> logout() async {
    try {
      debugPrint("🔔 [NotificationService] Logging out");
      await OneSignal.logout();
    } catch (e) {
      debugPrint("❌ [NotificationService] Logout Error: $e");
    }
  }
}
