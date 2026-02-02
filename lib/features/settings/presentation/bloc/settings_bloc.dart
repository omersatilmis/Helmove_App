import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/update_audio_usecase.dart';
import '../../domain/usecases/update_map_usecase.dart';
import '../../domain/usecases/update_privacy_usecase.dart';
import '../../domain/usecases/update_units_usecase.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final UpdatePrivacyUseCase updatePrivacy;
  final UpdateUnitsUseCase updateUnits;
  final UpdateMapUseCase updateMap;
  final UpdateAudioUseCase updateAudio;

  SettingsBloc({
    required this.updatePrivacy,
    required this.updateUnits,
    required this.updateMap,
    required this.updateAudio,
  }) : super(const SettingsState()) {
    on<UpdatePrivacyEvent>(_onUpdatePrivacy);
    on<UpdateUnitsEvent>(_onUpdateUnits);
    on<UpdateMapEvent>(_onUpdateMap);
    on<UpdateAudioEvent>(_onUpdateAudio);
  }

  Future<void> _onUpdatePrivacy(
    UpdatePrivacyEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(status: SettingsStatus.loading));
    final result = await updatePrivacy(event.settings);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: SettingsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          status: SettingsStatus.success,
          successMessage: 'Gizlilik ayarları güncellendi',
        ),
      ),
    );
  }

  Future<void> _onUpdateUnits(
    UpdateUnitsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(status: SettingsStatus.loading));
    final result = await updateUnits(NoParams());
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: SettingsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          status: SettingsStatus.success,
          successMessage: 'Birim ayarları güncellendi',
        ),
      ),
    );
  }

  Future<void> _onUpdateMap(
    UpdateMapEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(status: SettingsStatus.loading));
    final result = await updateMap(NoParams());
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: SettingsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          status: SettingsStatus.success,
          successMessage: 'Harita ayarları güncellendi',
        ),
      ),
    );
  }

  Future<void> _onUpdateAudio(
    UpdateAudioEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(status: SettingsStatus.loading));
    final result = await updateAudio(NoParams());
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: SettingsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          status: SettingsStatus.success,
          successMessage: 'Ses ayarları güncellendi',
        ),
      ),
    );
  }
}
