import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moto_comm_app_1/core/services/webrtc_service.dart';
import 'package:moto_comm_app_1/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:moto_comm_app_1/features/settings/presentation/bloc/settings_event.dart';
import 'package:moto_comm_app_1/features/settings/presentation/widgets/structure/settings_section_header.dart';

// 🔥 YENİ OLUŞTURDUĞUMUZ HELPER DOSYASINI IMPORT ET
import 'package:moto_comm_app_1/features/settings/presentation/widgets/structure/helper_widgets.dart';

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

  String _distanceUnit = "Kilometre (km)";
  String _tempUnit = "Celsius (°C)";
  String _audioQuality = "Dengeli (32 kbps)";

  String _mapType = "Normal";
  bool _trafficEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  // Kayıtlı ayarları yükle ve servise uygula
  Future<void> _loadSavedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedQuality = prefs.getString('audio_quality');
      if (savedQuality != null && mounted) {
        setState(() => _audioQuality = savedQuality);
        _updateWebRTCService(savedQuality);
      }
    } catch (e) {
      debugPrint("Ayarlar yüklenirken hata: $e");
    }
  }

  // WebRTC servisine yeni kaliteyi bildir
  void _updateWebRTCService(String qualityLabel) {
    try {
      if (!GetIt.I.isRegistered<WebRTCService>()) return;
      
      final service = GetIt.I<WebRTCService>();
      CallAudioQuality qualityEnum = CallAudioQuality.medium;

      if (qualityLabel.contains("Düşük")) {
        qualityEnum = CallAudioQuality.low;
      } else if (qualityLabel.contains("Yüksek")) qualityEnum = CallAudioQuality.high;
      else if (qualityLabel.contains("Ultra")) qualityEnum = CallAudioQuality.ultra;

      service.setAudioQuality(qualityEnum);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: "Uygulama Ayarları"),

        // 3. ÖLÇÜ BİRİMLERİ
        SettingsExpansionTile(
          icon: Icons.straighten_rounded,
          title: "Ölçü Birimleri",
          children: [
            SettingsActionTile(
              title: "Mesafe",
              value: _distanceUnit,
              icon: Icons.directions_car_rounded,
              onTap: () => showSettingsBottomSheet(
                context,
                "Mesafe Birimi",
                ["Kilometre (km)", "Mil (mi)"],
                (val) {
                  setState(() => _distanceUnit = val);
                  context.read<SettingsBloc>().add(const UpdateUnitsEvent());
                },
              ),
            ),
            SettingsActionTile(
              title: "Sıcaklık",
              value: _tempUnit,
              icon: Icons.thermostat_rounded,
              onTap: () => showSettingsBottomSheet(
                context,
                "Sıcaklık Birimi",
                ["Celsius (°C)", "Fahrenheit (°F)"],
                (val) {
                  setState(() => _tempUnit = val);
                  context.read<SettingsBloc>().add(const UpdateUnitsEvent());
                },
              ),
            ),
          ],
        ),

        // 4. HARİTA AYARLARI
        SettingsExpansionTile(
          icon: Icons.map_outlined,
          title: "Harita Ayarları",
          children: [
            SettingsActionTile(
              title: "Harita Tipi",
              value: _mapType,
              icon: Icons.layers_outlined,
              onTap: () => showSettingsBottomSheet(
                context,
                "Harita Tipi",
                ["Normal", "Uydu", "Arazi", "Hibrit"],
                (val) {
                  setState(() => _mapType = val);
                  context.read<SettingsBloc>().add(const UpdateMapEvent());
                },
              ),
            ),
            SettingsSwitchTile(
              title: "Trafik Bilgisi",
              subtitle: "Yoğunluk durumunu göster",
              value: _trafficEnabled,
              onChanged: (val) {
                setState(() => _trafficEnabled = val);
                context.read<SettingsBloc>().add(const UpdateMapEvent());
              },
            ),
          ],
        ),

        // 5. SES & MEDYA
        SettingsExpansionTile(
          icon: Icons.volume_up_rounded,
          title: "Ses & Medya",
          children: [
            SettingsActionTile(
              title: "Ses Kalitesi",
              value: _audioQuality,
              icon: Icons.equalizer_rounded,
              onTap: () => showSettingsBottomSheet(
                context,
                "Ses Kalitesi",
                [
                  "Düşük (16 kbps) - Veri Tasarrufu",
                  "Dengeli (32 kbps) - Varsayılan",
                  "Yüksek (48 kbps) - WiFi Önerilir",
                  "Ultra (64 kbps) - En Yüksek Kalite",
                ],
                (val) async {
                  setState(() => _audioQuality = val);
                  // 1. Kalıcı olarak kaydet
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('audio_quality', val);
                  // 2. Servisi anlık güncelle
                  _updateWebRTCService(val);
                  context.read<SettingsBloc>().add(const UpdateAudioEvent());
                },
              ),
            ),
            SettingsSwitchTile(
              title: "Gürültü Engelleme",
              subtitle: "Rüzgar sesini azaltır",
              value: _noiseCancellation,
              onChanged: (val) {
                setState(() => _noiseCancellation = val);
                context.read<SettingsBloc>().add(const UpdateAudioEvent());
              },
            ),
            SettingsSwitchTile(
              title: "Sesli Navigasyon",
              subtitle: "Rota talimatlarını sesli al",
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
          title: "Bağlantı",
          children: [
            SettingsSwitchTile(
              title: "Sadece Wi-Fi ile İndir",
              subtitle: "Harita güncellemeleri için",
              value: _wifiOnly,
              onChanged: (val) => setState(() => _wifiOnly = val),
            ),
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: Text(
                "Bluetooth Cihazları",
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
}
