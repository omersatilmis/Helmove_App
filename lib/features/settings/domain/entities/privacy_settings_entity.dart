import 'package:equatable/equatable.dart';

class PrivacySettingsEntity extends Equatable {
  final bool? ghostMode;
  final int? locationPrivacy;
  final bool? showProfileToOthers;

  const PrivacySettingsEntity({
    this.ghostMode,
    this.locationPrivacy,
    this.showProfileToOthers,
  });

  @override
  List<Object?> get props => [ghostMode, locationPrivacy, showProfileToOthers];
}
