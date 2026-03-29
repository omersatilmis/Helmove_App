import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:helmove/core/config/app_feature_flags.dart';
import 'package:helmove/l10n/app_localizations.dart';
// WebRTC servisi artık doğrudan çağrılmıyor — bitrate yönetimi
// AdaptiveBitrateController üzerinden IntercomEngine tarafından yapılır.
import 'package:helmove/core/services/audio_orchestrator_service.dart';
import 'package:helmove/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:helmove/features/settings/presentation/bloc/settings_event.dart';
import 'package:helmove/features/settings/presentation/widgets/structure/settings_section_header.dart';

// 🔥 YENİ OLUŞTURDUĞUMUZ HELPER DOSYASINI IMPORT ET
import 'package:helmove/features/settings/presentation/widgets/structure/helper_widgets.dart';


class AppSettingsSection extends StatefulWidget {
  const AppSettingsSection({super.key});

  @override
  State<AppSettingsSection> createState() => _AppSettingsSectionState();
}

class _AppSettingsSectionState extends State<AppSettingsSection> {
  // State Değişkenleri
  bool _noiseCancellation = false;
  bool _voiceNavigation = true;
  bool _wifiOnly = true;

  String _distanceUnit = "";
  String _tempUnit = "";
  String _audioQuality = ""; // Will be initialized


  String _mapType = "";
  bool _trafficEnabled = false;

  // Yeni Ayarlar
  AudioMixingMode _musicMode = AudioMixingMode.auto;
  // ignore: unused_field
  bool _preferWiredMic = false; // UI'da gizli, ama logic hook var

  // Ses Kalitesi Seçenekleri (Key -> Label)
  Map<String, String> _getQualityOptions(AppLocalizations l10n) => {
    'low': l10n.lowQuality,
    'medium': l10n.mediumQuality,
    'high': l10n.highQuality,
    'ultra': l10n.ultraQuality,
  };

  @override
  void initState() {
    super.initState();
    // Delay loading until l10n is available or use a default
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context);
    if (l10n != null && mounted) {
      if (_distanceUnit.isEmpty) _distanceUnit = l10n.kilometer;
      if (_tempUnit.isEmpty) _tempUnit = l10n.celsius;
      if (_mapType.isEmpty) _mapType = l10n.normal;
      if (_audioQuality.isEmpty) {
        final qualityOptions = _getQualityOptions(l10n);
        _audioQuality = qualityOptions['medium'] ?? '';
      }
    }
    _loadSavedSettings();
  }

  // Kayıtlı ayarları yükle ve servise uygula
  Future<void> _loadSavedSettings() async {
    try {
      final l10n = AppLocalizations.of(context);
      if (l10n == null) return;
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final qualityOptions = _getQualityOptions(l10n);

      // Kayıtlı ayarları oku
      final savedQualityKey = prefs.getString('audio_quality_key');
      final savedMusicMode = prefs.getString('audio_mixing_mode');
      final savedWiredMic = prefs.getBool('prefer_wired_mic');

      if (mounted) {
        setState(() {

          if (savedQualityKey != null) {
            _audioQuality =
                qualityOptions[savedQualityKey] ?? qualityOptions['medium']!;
          } else if (_audioQuality.isEmpty) {
            _audioQuality = qualityOptions['medium']!;
          }
          if (savedMusicMode != null) {
            _musicMode = AudioMixingMode.values.firstWhere(
              (e) => e.name == savedMusicMode,
              orElse: () => AudioMixingMode.auto,
            );
          }
          if (savedWiredMic != null) _preferWiredMic = savedWiredMic;
        });

        // Bitrate artık IntercomEngine.onAudioSettingsChanged() üzerinden
        // AdaptiveBitrateController'a iletiliyor — doğrudan WebRTC çağrısı yok.
      }
    } catch (e) {
      // Logic for error logging could go here
    }
  }

  // ─── KALDIRILDI ───────────────────────────────────────────────────
  // _updateWebRTCServiceWithKey kaldırıldı.
  // Bitrate yönetimi artık tek noktadan (AdaptiveBitrateController)
  // IntercomEngine.onAudioSettingsChanged() üzerinden yapılıyor.
  // Bu sayede P2P ve SFU aynı pipeline'ı kullanıyor.
  // ──────────────────────────────────────────────────────────────────

  String _getKeyFromLabel(String label, AppLocalizations l10n) {
    final qualityOptions = _getQualityOptions(l10n);
    return qualityOptions.entries
        .firstWhere(
          (e) => e.value == label,
          orElse: () => const MapEntry('medium', ''),
        )
        .key;
  }

  Future<void> _updateMusicMode(AudioMixingMode mode) async {
    setState(() => _musicMode = mode);
    if (GetIt.I.isRegistered<AudioOrchestratorService>()) {
      await GetIt.I<AudioOrchestratorService>().setAudioMixingMode(mode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
    final qualityOptions = _getQualityOptions(l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: l10n.appSettings),


        // 3. ÖLÇÜ BİRİMLERİ
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

        // 4. HARİTA AYARLARI
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

        // 5. SES & MEDYA (YENİLENEN KISIM)
        SettingsExpansionTile(
          icon: Icons.volume_up_rounded,
          title: l10n.audioMedia,
          children: [
            // SES KALİTESİ KISMI
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.audioQuality,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () => showSettingsBottomSheet(
                      context,
                      l10n.audioQuality,
                      qualityOptions.values.toList(),
                      (val) async {
                        setState(() => _audioQuality = val);
                        final qualityKey = _getKeyFromLabel(val, l10n);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('audio_quality_key', qualityKey);
                        // Bitrate güncellemesi artık UpdateAudioEvent →
                        // SettingsRepo → IntercomEngine.onAudioSettingsChanged()
                        // → AdaptiveBitrateController üzerinden yapılıyor.
                        if (!context.mounted) return;
                        context.read<SettingsBloc>().add(
                          const UpdateAudioEvent(),
                        );
                      },
                    ),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _audioQuality,
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 24, indent: 16, endIndent: 16),

            // ARKA PLANDA MÜZİK KISMI
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
              onChanged: (val) {
                setState(() => _noiseCancellation = val);
                context.read<SettingsBloc>().add(const UpdateAudioEvent());
              },
            ),
            SettingsSwitchTile(
              title: l10n.voiceNavigation,
              subtitle: l10n.voiceRouteInstructions,
              value: _voiceNavigation,
              onChanged: (val) {
                setState(() => _voiceNavigation = val);
                context.read<SettingsBloc>().add(const UpdateAudioEvent());
              },
            ),
          ],
        ),

        // 6. BAĞLANTI
        SettingsExpansionTile(
          icon: Icons.sensors_rounded,
          title: l10n.connectionSettings,
          children: [
            SettingsSwitchTile(
              title: l10n.wifiOnlyDownloads,
              subtitle: l10n.mapUpdatesFor,
              value: _wifiOnly,
              onChanged: (val) => setState(() => _wifiOnly = val),
            ),
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
              onTap: () {},
            ),
          ],
        ),
      ],
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
                    style: TextStyle(fontSize: 12, color: Colors.grey),
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
