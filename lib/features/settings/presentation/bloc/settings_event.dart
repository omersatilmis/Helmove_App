import 'package:equatable/equatable.dart';
import '../../domain/entities/privacy_settings_entity.dart';
import '../../data/models/audio_settings_model.dart';
import '../../data/models/network_settings_model.dart';

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

class LoadAudioSettingsEvent extends SettingsEvent {
  const LoadAudioSettingsEvent();
}

class UpdateAudioEvent extends SettingsEvent {
  final AudioSettingsModel settings;
  const UpdateAudioEvent(this.settings);

  @override
  List<Object?> get props => [settings];
}

class LoadNetworkSettingsEvent extends SettingsEvent {
  const LoadNetworkSettingsEvent();
}

class UpdateNetworkEvent extends SettingsEvent {
  final NetworkSettingsModel settings;
  const UpdateNetworkEvent(this.settings);

  @override
  List<Object?> get props => [settings];
}
