import '../../domain/entities/privacy_settings_entity.dart';

class PrivacySettingsModel extends PrivacySettingsEntity {
  const PrivacySettingsModel({
    super.ghostMode,
    super.locationPrivacy,
    super.showProfileToOthers,
  });

  Map<String, dynamic> toJson() {
    return {
      'ghostMode': ghostMode,
      'locationPrivacy': locationPrivacy,
      'showProfileToOthers': showProfileToOthers,
    };
  }
}
