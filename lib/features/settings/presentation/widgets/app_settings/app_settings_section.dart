import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:helmove/core/config/app_feature_flags.dart';
import 'package:helmove/l10n/app_localizations.dart';
import 'package:helmove/core/services/audio_orchestrator_service.dart';
import 'package:helmove/features/settings/data/models/audio_settings_model.dart';
import 'package:helmove/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:helmove/features/settings/presentation/bloc/settings_event.dart';
import 'package:helmove/features/settings/presentation/bloc/settings_state.dart';
import 'package:helmove/features/settings/presentation/pages/bluetooth_devices_page.dart';
import 'package:helmove/features/settings/presentation/widgets/structure/settings_section_header.dart';
import 'package:helmove/features/settings/presentation/widgets/structure/helper_widgets.dart';


class AppSettingsSection extends StatefulWidget {
  const AppSettingsSection({super.key});

  @override
  State<AppSettingsSection> createState() => _AppSettingsSectionState();
}

class _AppSettingsSectionState extends State<AppSettingsSection> {
  bool _noiseCancellation = false;
  bool _voiceNavigation = true;

  String _distanceUnit = "";
  String _tempUnit = "";
  String _mapType = "";
  bool _trafficEnabled = false;

  AudioMixingMode _musicMode = AudioMixingMode.auto;
  // ignore: unused_field
  bool _preferWiredMic = false;

  bool _settingsLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context);
    if (l10n != null && mounted) {
      if (_distanceUnit.isEmpty) _distanceUnit = l10n.kilometer;
      if (_tempUnit.isEmpty) _tempUnit = l10n.celsius;
      if (_mapType.isEmpty) _mapType = l10n.normal;
    }
    if (!_settingsLoaded) {
      _settingsLoaded = true;
      _loadSavedSettings();
      context.read<SettingsBloc>().add(const LoadAudioSettingsEvent());
    }
  }

  Future<void> _loadSavedSettings() async {
    try {
      final l10n = AppLocalizations.of(context);
      if (l10n == null) return;
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;

      final savedMusicMode = prefs.getString('audio_mixing_mode');
      final savedWiredMic = prefs.getBool('prefer_wired_mic');
      final savedNoise = prefs.getBool('audio_noise_suppression');
      final savedVoiceNav = prefs.getBool('voice_navigation_enabled');

      if (mounted) {
        setState(() {
          if (savedMusicMode != null) {
            _musicMode = AudioMixingMode.values.firstWhere(
              (e) => e.name == savedMusicMode,
              orElse: () => AudioMixingMode.auto,
            );
          }
          if (savedWiredMic != null) _preferWiredMic = savedWiredMic;
          if (savedNoise != null) _noiseCancellation = savedNoise;
          if (savedVoiceNav != null) _voiceNavigation = savedVoiceNav;
        });
      }
    } catch (_) {}
  }

  void _applyAudioSettingsFromBloc(AudioSettingsModel settings) {
    if (!mounted) return;
    setState(() {
      if (settings.noiseCancellationEnabled != null) {
        _noiseCancellation = settings.noiseCancellationEnabled!;
      }
      if (settings.voiceNavigationEnabled != null) {
        _voiceNavigation = settings.voiceNavigationEnabled!;
      }
    });
  }

  Future<void> _updateMusicMode(AudioMixingMode mode) async {
    setState(() => _musicMode = mode);
    if (GetIt.I.isRegistered<AudioOrchestratorService>()) {
      await GetIt.I<AudioOrchestratorService>().setAudioMixingMode(mode);
    }
  }

  void _onNoiseChanged(bool val) {
    setState(() => _noiseCancellation = val);
    context.read<SettingsBloc>().add(
      UpdateAudioEvent(
        AudioSettingsModel(noiseCancellationEnabled: val),
      ),
    );
  }

  void _onVoiceNavChanged(bool val) {
    setState(() => _voiceNavigation = val);
    context.read<SettingsBloc>().add(
      UpdateAudioEvent(
        AudioSettingsModel(voiceNavigationEnabled: val),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    return BlocListener<SettingsBloc, SettingsState>(
      listenWhen: (prev, curr) => curr.audioSettings != prev.audioSettings,
      listener: (context, state) {
        if (state.audioSettings != null) {
          _applyAudioSettingsFromBloc(state.audioSettings!);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsSectionHeader(title: l10n.appSettings),

          if (AppFeatureFlags.showMeasurementUnits)
            SettingsExpansionTile(
              icon: Icons.straighten_rounded,
              title: l10n.measurementUnits,
              children: [
                SettingsActionTile(
                  title: l10n.distance,
                  value: _distanceUnit,
                  icon: Icons.directions_car_rounded,
                  onTap: () => showSettingsBottomSheet(
                    context,
                    l10n.distanceUnit,
                    [l10n.kilometer, l10n.mile],
                    (val) {
                      setState(() => _distanceUnit = val);
                      context.read<SettingsBloc>().add(const UpdateUnitsEvent());
                    },
                  ),
                ),
                SettingsActionTile(
                  title: l10n.temperature,
                  value: _tempUnit,
                  icon: Icons.thermostat_rounded,
                  onTap: () => showSettingsBottomSheet(
                    context,
                    l10n.tempUnit,
                    [l10n.celsius, l10n.fahrenheit],
                    (val) {
                      setState(() => _tempUnit = val);
                      context.read<SettingsBloc>().add(const UpdateUnitsEvent());
                    },
                  ),
                ),
              ],
            ),

          if (AppFeatureFlags.showMapSettings)
            SettingsExpansionTile(
              icon: Icons.map_outlined,
              title: l10n.mapSettings,
              children: [
                SettingsActionTile(
                  title: l10n.mapType,
                  value: _mapType,
                  icon: Icons.layers_outlined,
                  onTap: () => showSettingsBottomSheet(
                    context,
                    l10n.mapType,
                    [l10n.normal, l10n.satellite, l10n.terrain, l10n.hybrid],
                    (val) {
                      setState(() => _mapType = val);
                      context.read<SettingsBloc>().add(const UpdateMapEvent());
                    },
                  ),
                ),
                SettingsSwitchTile(
                  title: l10n.trafficInfo,
                  subtitle: l10n.showTrafficDensity,
                  value: _trafficEnabled,
                  onChanged: (val) {
                    setState(() => _trafficEnabled = val);
                    context.read<SettingsBloc>().add(const UpdateMapEvent());
                  },
                ),
              ],
            ),

          SettingsExpansionTile(
            icon: Icons.volume_up_rounded,
            title: l10n.audioMedia,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.backgroundMusic,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RadioGroup<AudioMixingMode>(
                      groupValue: _musicMode,
                      onChanged: (val) {
                        if (val != null) _updateMusicMode(val);
                      },
                      child: Column(
                        children: [
                          _buildMusicOption(
                            title: l10n.automatic,
                            subtitle: l10n.dimWhileTalking,
                            value: AudioMixingMode.auto,
                            groupValue: _musicMode,
                            onChanged: _updateMusicMode,
                          ),
                          _buildMusicOption(
                            title: l10n.on,
                            subtitle: l10n.musicAlwaysDimmed,
                            value: AudioMixingMode.always,
                            groupValue: _musicMode,
                            onChanged: _updateMusicMode,
                          ),
                          _buildMusicOption(
                            title: l10n.off,
                            subtitle: l10n.noChangeInMusic,
                            value: AudioMixingMode.off,
                            groupValue: _musicMode,
                            onChanged: _updateMusicMode,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 16, indent: 16, endIndent: 16),

              SettingsSwitchTile(
                title: l10n.noiseCancellation,
                subtitle: l10n.reduceWindNoise,
                value: _noiseCancellation,
                onChanged: _onNoiseChanged,
              ),
              SettingsSwitchTile(
                title: l10n.voiceNavigation,
                subtitle: l10n.voiceRouteInstructions,
                value: _voiceNavigation,
                onChanged: _onVoiceNavChanged,
              ),
            ],
          ),

          SettingsExpansionTile(
            icon: Icons.sensors_rounded,
            title: l10n.connectionSettings,
            children: [
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text(
                  l10n.bluetoothDevices,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Colors.grey,
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const BluetoothDevicesPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMusicOption({
    required String title,
    required String subtitle,
    required AudioMixingMode value,
    required AudioMixingMode groupValue,
    required Function(AudioMixingMode) onChanged,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            Radio<AudioMixingMode>(
              value: value,
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
