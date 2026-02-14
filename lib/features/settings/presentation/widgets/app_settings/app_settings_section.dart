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
  String _themeMode = "Sistem";
  String _language = "Türkçe";

  String _mapType = "Normal";
  bool _trafficEnabled = false;

  // Ses Kalitesi Seçenekleri (Key -> Label)
  final Map<String, String> _qualityOptions = {
    'low': "Düşük (16 kbps) - Veri Tasarrufu",
    'medium': "Dengeli (32 kbps) - Varsayılan",
    'high': "Yüksek (48 kbps) - WiFi Önerilir",
    'ultra': "Ultra (64 kbps) - En Yüksek Kalite",
  };

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  // Kayıtlı ayarları yükle ve servise uygula
  Future<void> _loadSavedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Kayıtlı ayarları oku
      final savedTheme = prefs.getString('theme_mode');
      final savedLanguage = prefs.getString('language');
      final savedQualityKey = prefs.getString('audio_quality_key');

      if (mounted) {
        setState(() {
          if (savedTheme != null) _themeMode = savedTheme;
          if (savedLanguage != null) _language = savedLanguage;
          if (savedQualityKey != null) {
            _audioQuality = _qualityOptions[savedQualityKey] ?? _qualityOptions['medium']!;
          }
        });

        if (savedQualityKey != null) {
          _updateWebRTCServiceWithKey(savedQualityKey);
        }
      }
    } catch (e) {
      debugPrint("Ayarlar yüklenirken hata: $e");
    }
  }

  // WebRTC servisine yeni kaliteyi bildir
  void _updateWebRTCServiceWithKey(String qualityKey) {
    try {
      if (!GetIt.I.isRegistered<WebRTCService>()) return;
      
      final service = GetIt.I<WebRTCService>();
      CallAudioQuality qualityEnum = CallAudioQuality.medium;

      switch (qualityKey) {
        case 'low':
          qualityEnum = CallAudioQuality.low;
          break;
        case 'medium':
          qualityEnum = CallAudioQuality.medium;
          break;
        case 'high':
          qualityEnum = CallAudioQuality.high;
          break;
        case 'ultra':
          qualityEnum = CallAudioQuality.ultra;
          break;
      }

      service.setAudioQuality(qualityEnum);
    } catch (_) {}
  }

  String _getKeyFromLabel(String label) {
    return _qualityOptions.entries
        .firstWhere((e) => e.value == label, orElse: () => const MapEntry('medium', ''))
        .key;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: "Uygulama Ayarları"),

        // 2. GENEL AYARLAR (Tema & Dil)
        SettingsExpansionTile(
          icon: Icons.settings_rounded,
          title: "Genel Ayarlar",
          children: [
            SettingsActionTile(
              title: "Tema",
              value: _themeMode,
              icon: Icons.brightness_6_rounded,
              onTap: () => showSettingsBottomSheet(
                context,
                "Tema Seçimi",
                ["Sistem", "Aydınlık", "Karanlık"],
                (val) async {
                  setState(() => _themeMode = val);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('theme_mode', val);
                  // Not: Uygulamanın anlık tema değişimi için main.dart veya ThemeBloc'un bu değeri dinlemesi gerekir.
                },
              ),
            ),
            SettingsActionTile(
              title: "Dil",
              value: _language,
              icon: Icons.language_rounded,
              onTap: () => showSettingsBottomSheet(
                context,
                "Dil Seçimi",
                ["Türkçe", "English"],
                (val) async {
                  setState(() => _language = val);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('language', val);
                },
              ),
            ),
          ],
        ),

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
                _qualityOptions.values.toList(),
                (val) async {
                  setState(() => _audioQuality = val);
                  final qualityKey = _getKeyFromLabel(val);
                  // 1. Kalıcı olarak kaydet
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('audio_quality_key', qualityKey);
                  // 2. Servisi anlık güncelle
                  _updateWebRTCServiceWithKey(qualityKey);
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
