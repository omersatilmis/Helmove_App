import 'package:equatable/equatable.dart';
import '../../data/models/audio_settings_model.dart';
import '../../data/models/network_settings_model.dart';

enum SettingsStatus { initial, loading, success, failure }

class SettingsState extends Equatable {
  final SettingsStatus status;
  final String? errorMessage;
  final String? successMessage;
  final AudioSettingsModel? audioSettings;
  final NetworkSettingsModel? networkSettings;

  const SettingsState({
    this.status = SettingsStatus.initial,
    this.errorMessage,
    this.successMessage,
    this.audioSettings,
    this.networkSettings,
  });

  SettingsState copyWith({
    SettingsStatus? status,
    String? errorMessage,
    String? successMessage,
    AudioSettingsModel? audioSettings,
    NetworkSettingsModel? networkSettings,
  }) {
    return SettingsState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
      audioSettings: audioSettings ?? this.audioSettings,
      networkSettings: networkSettings ?? this.networkSettings,
    );
  }

  @override
  List<Object?> get props => [
    status,
    errorMessage,
    successMessage,
    audioSettings,
    networkSettings,
  ];
}
