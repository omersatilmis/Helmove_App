import 'package:equatable/equatable.dart';
import '../../domain/entities/privacy_settings_entity.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class UpdatePrivacyEvent extends SettingsEvent {
  final PrivacySettingsEntity settings;
  const UpdatePrivacyEvent(this.settings);

  @override
  List<Object?> get props => [settings];
}

class UpdateUnitsEvent extends SettingsEvent {
  const UpdateUnitsEvent();
}

class UpdateMapEvent extends SettingsEvent {
  const UpdateMapEvent();
}

class UpdateAudioEvent extends SettingsEvent {
  const UpdateAudioEvent();
}
